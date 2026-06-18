import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/class_session_model.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/timetable_provider.dart';
import 'edit_today_schedule_sheet.dart';

// ── Lightweight one-shot providers (no codegen needed) ────────────────────────

/// True if the user has ANY rows in timetable_entries.
final _hasTimetableEntriesProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(timetableRepositoryProvider).hasActiveTimetable(),
);

/// True if the user has ever saved a semester (generated a schedule at least once).
final _hasActiveSemesterProvider = FutureProvider.autoDispose<bool>((ref) async {
  final semester =
      await ref.read(timetableRepositoryProvider).getActiveSemester();
  return semester != null;
});

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // S2 FIX: Invalidate schedulePageDataProvider every minute so time-based
    // bucket transitions (upcoming → action required → completed) happen
    // on the clock tick. A plain setState() only rebuilds the widget tree but
    // schedulePageDataProvider is a Riverpod provider that caches its value
    // until one of its watched inputs changes — so setState alone was not
    // enough to move classes between sections.
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) ref.invalidate(schedulePageDataProvider);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleData = ref.watch(schedulePageDataProvider);
    final todayAsync = ref.watch(todaySessionsStreamProvider);
    final notifier = ref.read(scheduleNotifierProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final now = DateTime.now();
    final dayName = DateFormat('EEEE, MMM d').format(now);

    final allSessions = todayAsync.valueOrNull ?? [];
    final hasAnyClasses = scheduleData.totalTodayCount > 0 || allSessions.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg.withAlpha(230),
        title: Text(
          'Schedule',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.grid_view_rounded, color: onSurfaceVariant),
            tooltip: 'Manage Timetable',
            onPressed: () => context.push('/timetable/manage'),
          ),
          // OCR import button — disabled until OCR feature is ready
          // IconButton(
          //   icon: Icon(Icons.document_scanner_outlined, color: onSurfaceVariant),
          //   tooltip: 'Import Timetable',
          //   onPressed: () => context.push('/timetable/upload'),
          // ),
        ],
      ),
      body: todayAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.error)),
        ),
        data: (_) {
          if (!hasAnyClasses) {
            return _EmptySchedule(
              isDark: isDark,
              primary: primary,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
            children: [
              // ─── TODAY HEADER ───────────────────────────────────────────────
              _TodayHeader(
                dayName: dayName,
                totalClasses: scheduleData.totalTodayCount,
                upcomingCount: scheduleData.upcoming.length,
                isDark: isDark,
                primary: primary,
                onSurface: onSurface,
                onSurfaceVariant: onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── ACTION BUTTONS ROW ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit_calendar_outlined,
                      label: 'Edit Today',
                      isDark: isDark,
                      // S3 FIX: Pass override-aware sessions (from schedulePageData)
                      // instead of raw todayAsync. The raw stream has no overrides
                      // applied, so the edit sheet could create duplicate overrides
                      // on top of already-overridden sessions.
                      onTap: () => _showEditSheet(context, [
                        if (scheduleData.currentClass != null)
                          scheduleData.currentClass!,
                        ...scheduleData.upcoming,
                        ...scheduleData.actionRequired,
                        ...scheduleData.completedToday,
                      ]),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.event_busy_outlined,
                      label: 'Mark Absent',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () => _showMarkRemainingDialog(
                          context, scheduleData, notifier, allSessions),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── CURRENT CLASS ─────────────────────────────────────────────
              if (scheduleData.currentClass != null) ...[
                _SectionHeader(
                  dotColor: primary,
                  label: 'CURRENT CLASS',
                  animated: true,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
                _CurrentClassCard(
                  session: scheduleData.currentClass!,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ─── ACTION REQUIRED ───────────────────────────────────────────
              if (scheduleData.actionRequired.isNotEmpty) ...[
                _SectionHeader(
                  dotColor: AppColors.warning,
                  label: 'ACTION REQUIRED',
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'These classes have ended. Please mark your attendance.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                ...scheduleData.actionRequired.map(
                  (session) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ActionRequiredCard(
                      session: session,
                      isDark: isDark,
                      onMark: (status) async {
                        await notifier.markAttendance(
                            session: session, status: status);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ─── UPCOMING CLASSES ──────────────────────────────────────────
              if (scheduleData.upcoming.isNotEmpty) ...[
                _SectionHeader(label: 'UPCOMING CLASSES', isDark: isDark),
                const SizedBox(height: AppSpacing.md),
                ...scheduleData.upcoming.map(
                  (session) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _UpcomingClassCard(
                        session: session, isDark: isDark),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ─── COMPLETED TODAY ───────────────────────────────────────────
              // S1 FIX: Completed classes are now ALWAYS visible in compact
              // inline rows. Previously hidden behind a GestureDetector +
              // AnimatedCrossFade collapse toggle (_completedExpanded = false).
              // Users need to see marked classes immediately without extra taps.
              if (scheduleData.completedToday.isNotEmpty) ...[
                _SectionHeader(label: 'COMPLETED TODAY', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                ...scheduleData.completedToday.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _CompletedClassTile(
                        session: session, isDark: isDark),
                  ),
                ),
              ],

            ],
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, List<ClassSession> sessions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTodayScheduleSheet(sessions: sessions),
    );
  }

  Future<void> _showMarkRemainingDialog(
    BuildContext context,
    SchedulePageData data,
    ScheduleNotifier notifier,
    List<ClassSession> allSessions,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;

    final remaining = [
      ...data.upcoming,
      ...data.actionRequired,
    ].where((s) =>
        s.status == AttendanceStatus.notMarked && !s.isCancelled).toList();

    final allCount = allSessions
        .where((s) =>
            s.status == AttendanceStatus.notMarked && !s.isCancelled)
        .length;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mark Classes Absent',
              style: AppTextStyles.headlineMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (remaining.isNotEmpty)
              _AbsentChoiceCard(
                icon: Icons.arrow_forward_rounded,
                title: 'Mark Remaining Absent',
                subtitle:
                    '${remaining.length} upcoming & unmarked class${remaining.length == 1 ? '' : 'es'}',
                color: AppColors.warning,
                value: 'remaining',
              ),
            if (remaining.isNotEmpty) const SizedBox(height: AppSpacing.md),
            if (allCount > 0)
              _AbsentChoiceCard(
                icon: Icons.calendar_today_rounded,
                title: 'Mark Full Day Absent',
                subtitle:
                    '$allCount total unmarked class${allCount == 1 ? '' : 'es'} today',
                color: AppColors.error,
                value: 'fullday',
              ),
            if (remaining.isEmpty && allCount == 0)
              Text(
                'No unmarked classes remaining today.',
                style: AppTextStyles.bodyLg,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    if (choice == 'remaining') {
      await notifier.markRemainingAbsent(remaining);
    } else if (choice == 'fullday') {
      await notifier.markFullDayAbsent(allSessions);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Absent Choice Card
// ─────────────────────────────────────────────────────────────────────────────

class _AbsentChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String value;

  const _AbsentChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLowest;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: AppTextStyles.bodySm.copyWith(
                            color: color)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool animated;
  final bool isDark;

  const _SectionHeader({
    required this.label,
    this.dotColor,
    this.animated = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final variant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Row(
      children: [
        if (dotColor != null) ...[
          if (animated)
            _PulsingDot(color: dotColor!)
          else
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            color: dotColor != null ? primary : variant,
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Today Header
// ─────────────────────────────────────────────────────────────────────────────

class _TodayHeader extends StatelessWidget {
  final String dayName;
  final int totalClasses;
  final int upcomingCount;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _TodayHeader({
    required this.dayName,
    required this.totalClasses,
    required this.upcomingCount,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today',
          style: AppTextStyles.headlineLg.copyWith(color: onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$dayName  ·  $upcomingCount class${upcomingCount == 1 ? '' : 'es'} remaining',
          style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action Button (Edit / Mark Absent)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final color = isDestructive ? AppColors.warning : primary;
    final surface =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
                color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                    color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Current Class Card
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentClassCard extends StatelessWidget {
  final ClassSession session;
  final bool isDark;

  const _CurrentClassCard({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final cardBg =
        isDark ? AppColors.darkSurfaceContainer : Colors.white;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primaryFixed =
        isDark ? AppColors.darkPrimaryContainer.withAlpha(80) : AppColors.primaryFixed;

    // Calculate progress
    final now = DateTime.now();
    final startMin = _parseTimeMin(session.displayStartTime);
    final endMin = _parseTimeMin(session.displayEndTime);
    final nowMin = now.hour * 60 + now.minute;
    final duration = endMin - startMin;
    final elapsed = nowMin - startMin;
    final progress = duration > 0 ? (elapsed / duration).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(38),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.displaySubjectName,
                        style: AppTextStyles.headlineMd
                            .copyWith(color: primary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_outlined,
                            size: 14, color: onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${session.displayStartTime} – ${session.displayEndTime}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: onSurfaceVariant),
                        ),
                        if (session.room != null) ...[
                          Text(' · ',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: onSurfaceVariant)),
                          Icon(Icons.location_on_outlined,
                              size: 14, color: onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            session.room!,
                            style: AppTextStyles.bodySm
                                .copyWith(color: onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryFixed,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingDot(color: primary),
                    const SizedBox(width: 4),
                    Text(
                      'In Progress',
                      style: AppTextStyles.labelMd.copyWith(color: primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerHigh
                  : AppColors.surfaceContainerHigh,
              color: primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.displayStartTime,
                style: AppTextStyles.bodySm
                    .copyWith(color: onSurfaceVariant, fontSize: 10),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% through',
                style: AppTextStyles.bodySm
                    .copyWith(color: onSurfaceVariant, fontSize: 10),
              ),
              Text(
                session.displayEndTime,
                style: AppTextStyles.bodySm
                    .copyWith(color: onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Info note
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: primaryFixed.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Attendance can be marked after class ends',
                    style: AppTextStyles.bodySm.copyWith(color: primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _parseTimeMin(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action Required Card (ended, unmarked → show Present/Absent buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRequiredCard extends StatefulWidget {
  final ClassSession session;
  final bool isDark;
  final Future<void> Function(AttendanceStatus status) onMark;

  const _ActionRequiredCard({
    required this.session,
    required this.isDark,
    required this.onMark,
  });

  @override
  State<_ActionRequiredCard> createState() => _ActionRequiredCardState();
}

class _ActionRequiredCardState extends State<_ActionRequiredCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final onSurface =
        widget.isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = widget.isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.displaySubjectName,
                      style: AppTextStyles.bodyLg.copyWith(
                          color: onSurface, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.session.displayStartTime} – ${widget.session.displayEndTime}',
                      style: AppTextStyles.bodySm
                          .copyWith(color: onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'Ended',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isLoading)
            const Center(
                child: SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(strokeWidth: 2.5)))
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _mark(AttendanceStatus.present),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Present'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mark(AttendanceStatus.absent),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Absent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _mark(AttendanceStatus status) async {
    setState(() => _isLoading = true);
    await widget.onMark(status);
    if (mounted) setState(() => _isLoading = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Upcoming Class Card
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingClassCard extends StatelessWidget {
  final ClassSession session;
  final bool isDark;

  const _UpcomingClassCard({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = _parseTimeMin(session.displayStartTime);
    final diffMin = startMin - nowMin;
    final timeLabel = _formatTimeUntil(diffMin);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayStartTime,
                  style: AppTextStyles.labelMd.copyWith(
                      color: onSurface, fontWeight: FontWeight.bold),
                ),
                Text(
                  session.displayEndTime,
                  style: AppTextStyles.bodySm
                      .copyWith(color: onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: borderColor,
            margin:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displaySubjectName,
                  style: AppTextStyles.bodyLg.copyWith(
                      color: onSurface, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (session.room != null)
                  Text(
                    session.room!,
                    style: AppTextStyles.bodySm
                        .copyWith(color: onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              timeLabel,
              style: AppTextStyles.bodySm
                  .copyWith(color: primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  int _parseTimeMin(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTimeUntil(int minutes) {
    if (minutes <= 0) return 'Starting';
    if (minutes < 60) return 'In ${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return 'In ${h}h';
    return 'In ${h}h ${m}m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Completed Class Tile
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedClassTile extends StatelessWidget {
  final ClassSession session;
  final bool isDark;

  const _CompletedClassTile({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final (icon, color, statusLabel) = switch (session.status) {
      AttendanceStatus.present => (
          Icons.check_circle_rounded,
          AppColors.success,
          'Present'
        ),
      AttendanceStatus.late => (
          Icons.timelapse_rounded,
          AppColors.warning,
          'Late'
        ),
      AttendanceStatus.absent => (
          Icons.cancel_rounded,
          AppColors.error,
          'Absent'
        ),
      AttendanceStatus.cancelled || _ => (
          Icons.block_rounded,
          onSurfaceVariant,
          session.isCancelled ? 'Cancelled' : 'Cancelled'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              session.displaySubjectName,
              style: AppTextStyles.bodyLg.copyWith(
                  color: onSurface, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${session.displayStartTime} – ${session.displayEndTime}',
            style:
                AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            statusLabel,
            style: AppTextStyles.labelMd.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty Schedule State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySchedule extends ConsumerWidget {
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _EmptySchedule({
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEntries =
        ref.watch(_hasTimetableEntriesProvider).valueOrNull ?? false;
    final hasSemester =
        ref.watch(_hasActiveSemesterProvider).valueOrNull ?? false;

    // ── State 1: No timetable at all ─────────────────────────────────────
    if (!hasEntries) {
      return EmptyStateWidget(
        icon: Icons.table_chart_outlined,
        title: 'No timetable yet',
        subtitle: 'Add your classes manually to get started.',
        actionLabel: 'Add Classes',
        onAction: () => context.push('/timetable/manage'),
      );
    }

    // ── State 2: Entries exist but semester was never generated ──────────
    if (!hasSemester) {
      return _SetupSemesterPrompt(
        primary: primary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        isDark: isDark,
      );
    }

    // ── State 3: Semester exists but today is a rest day ─────────────────
    return EmptyStateWidget(
      icon: Icons.weekend_outlined,
      title: 'No classes today 🎉',
      subtitle: 'Enjoy your free day! Your next class is on a weekday.',
      actionLabel: 'View Full Timetable',
      onAction: () => context.push('/timetable/manage'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Semester setup prompt (timetable saved, semester missing)
// ─────────────────────────────────────────────────────────────────────────────

class _SetupSemesterPrompt extends StatelessWidget {
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final bool isDark;

  const _SetupSemesterPrompt({
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green, size: 44),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Timetable Saved!',
              style: AppTextStyles.headlineMd.copyWith(
                  color: onSurface, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your classes are saved. Now set your semester dates so we can '  
              'generate daily sessions and show your schedule here.',
              style:
                  AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Step indicator
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  _Step(
                      number: 1,
                      label: 'Build timetable',
                      done: true,
                      primary: Colors.green),
                  const SizedBox(height: AppSpacing.sm),
                  _Step(
                      number: 2,
                      label: 'Set semester dates & generate schedule',
                      done: false,
                      primary: primary),
                  const SizedBox(height: AppSpacing.sm),
                  _Step(
                      number: 3,
                      label: 'Track attendance daily',
                      done: false,
                      primary: onSurfaceVariant),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/timetable/semester-setup'),
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Set Up Semester Now'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool done;
  final Color primary;

  const _Step({
    required this.number,
    required this.label,
    required this.done,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: done ? 1.0 : 0.12),
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }
}
