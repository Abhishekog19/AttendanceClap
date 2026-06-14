import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/timetable_provider.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayClasses = ref.watch(todayClassesProvider);
    final currentClass = ref.watch(currentClassProvider);
    final nextClass = ref.watch(nextClassProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final now = DateTime.now();
    final dayName = DateFormat('EEEE, MMM d').format(now);
    final remaining = todayClasses.where((c) {
      final start = _parseTime(c.startTime);
      final nowTod = TimeOfDay.now();
      return start.hour > nowTod.hour ||
          (start.hour == nowTod.hour && start.minute > nowTod.minute);
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg.withAlpha(230),
        title: Text(
          'AttendanceAI',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.document_scanner_outlined, color: onSurfaceVariant),
            tooltip: 'Import Timetable',
            onPressed: () => context.push('/timetable/upload'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
        children: [
          Text(
            "Today's Schedule",
            style: AppTextStyles.headlineLg.copyWith(color: onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$dayName • ${remaining.length} Classes remaining',
            style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── Currently In ──────────────────────────────────────────────────
          if (currentClass != null) ...[
            _SectionHeader(
              dotColor: primary,
              label: 'CURRENTLY IN',
              animated: true,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.md),
            _CurrentClassCard(entry: currentClass, ref: ref, isDark: isDark),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ─── Next Up ───────────────────────────────────────────────────────
          if (nextClass != null) ...[
            _SectionHeader(label: 'NEXT UP', isDark: isDark),
            const SizedBox(height: AppSpacing.md),
            _NextClassCard(entry: nextClass, ref: ref, isDark: isDark),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ─── Remaining Today ───────────────────────────────────────────────
          if (remaining.isNotEmpty) ...[
            _SectionHeader(label: 'REMAINING TODAY', isDark: isDark),
            const SizedBox(height: AppSpacing.md),
            ...remaining.skip(nextClass != null ? 1 : 0).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _RemainingClassCard(entry: entry, ref: ref, isDark: isDark),
                  ),
                ),
          ],

          if (todayClasses.isEmpty)
            EmptyStateWidget(
              icon: Icons.free_breakfast_outlined,
              title: 'No classes today',
              subtitle: 'Import your timetable to get started!',
              actionLabel: 'Import Timetable',
              onAction: () => context.push('/timetable/upload'),
            ),

          // ─── AI Prediction Bento ───────────────────────────────────────────
          const SizedBox(height: AppSpacing.md),
          _AIPredictionBento(isDark: isDark),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

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
    final variant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Row(
      children: [
        if (dotColor != null) ...[
          if (animated)
            _PulsingDot(color: dotColor!)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
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

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      );
}

class _CurrentClassCard extends StatelessWidget {
  final TimetableModel entry;
  final WidgetRef ref;
  final bool isDark;

  const _CurrentClassCard({required this.entry, required this.ref, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final cardBg = isDark ? AppColors.darkSurfaceContainer : Colors.white;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primaryFixed = isDark ? AppColors.darkPrimaryContainer.withAlpha(80) : AppColors.primaryFixed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(38),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.subjectName,
                        style: AppTextStyles.headlineMd.copyWith(color: primary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.room ?? 'Room TBD'} • ${entry.startTime} - ${entry.endTime}',
                          style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                        ),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'In Progress',
                  style: AppTextStyles.labelMd.copyWith(color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
              color: primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ref.read(timetableNotifierProvider.notifier).markAttendance(
                    subjectId: entry.subjectId,
                    status: AttendanceStatus.present,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark Present'),
                  style: FilledButton.styleFrom(backgroundColor: primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(timetableNotifierProvider.notifier).markAttendance(
                    subjectId: entry.subjectId,
                    status: AttendanceStatus.absent,
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Mark Absent'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  final TimetableModel entry;
  final WidgetRef ref;
  final bool isDark;

  const _NextClassCard({required this.entry, required this.ref, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final secondaryContainer = isDark ? AppColors.onSecondaryFixedVariant : AppColors.secondaryContainer;
    final onSecondary = isDark ? AppColors.secondaryFixed : AppColors.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.subjectName,
                        style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_outlined, size: 16, color: onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.startTime} - ${entry.endTime} • ${entry.room ?? 'Room TBD'}',
                          style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text('Up Next', style: AppTextStyles.labelMd.copyWith(color: onSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(timetableNotifierProvider.notifier).markAttendance(
                    subjectId: entry.subjectId,
                    status: AttendanceStatus.present,
                  ),
                  child: const Text('Mark Present'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(timetableNotifierProvider.notifier).markAttendance(
                    subjectId: entry.subjectId,
                    status: AttendanceStatus.absent,
                  ),
                  child: const Text('Mark Absent'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemainingClassCard extends StatelessWidget {
  final TimetableModel entry;
  final WidgetRef ref;
  final bool isDark;

  const _RemainingClassCard({required this.entry, required this.ref, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subjectName,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: onSurface, fontWeight: FontWeight.w600)),
                Text(
                  '${entry.startTime} - ${entry.endTime} • ${entry.room ?? 'TBD'}',
                  style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _CircleIconBtn(
                icon: Icons.check,
                color: primary,
                bg: isDark ? AppColors.darkPrimaryContainer.withAlpha(80) : AppColors.primaryFixed,
                onTap: () => ref.read(timetableNotifierProvider.notifier).markAttendance(
                  subjectId: entry.subjectId, status: AttendanceStatus.present,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CircleIconBtn(
                icon: Icons.close,
                color: AppColors.error,
                bg: AppColors.errorContainer,
                onTap: () => ref.read(timetableNotifierProvider.notifier).markAttendance(
                  subjectId: entry.subjectId, status: AttendanceStatus.absent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _CircleIconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}

class _AIPredictionBento extends StatelessWidget {
  final bool isDark;
  const _AIPredictionBento({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg * 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI PREDICTION',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onTertiaryFixed.withAlpha(180),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'High Attendance Likelihood',
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.onTertiaryFixed,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Based on your past weeks, you are 92% likely to attend all sessions today.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onTertiaryFixed.withAlpha(220),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('View Analytics'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onTertiaryFixed,
              side: BorderSide(color: AppColors.onTertiaryFixed.withAlpha(100)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
