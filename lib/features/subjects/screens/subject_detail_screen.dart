import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
// calc prefix so its AttendanceStatus (excellent/good/safe/risky/critical) doesn't clash
import '../../../core/utils/attendance_calculator.dart' as calc;
// Log model's AttendanceStatus (present/absent/late/cancelled) is default bare name
import '../../../data/models/attendance_log_model.dart';
// Hide class_session_model's conflicting AttendanceStatus
import '../../../data/models/class_session_model.dart' hide AttendanceStatus;
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../shared/widgets/attendance_progress_ring.dart';
import '../providers/subject_detail_provider.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final SubjectModel subject;
  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final detailAsync = ref.watch(subjectDetailProvider(subject.id));

    return Scaffold(
      backgroundColor: bg,
      body: detailAsync.when(
        loading: () => _buildSkeleton(context, bg, isDark),
        error: (e, _) => _buildError(context, e.toString(), bg, primary),
        data: (data) => _buildContent(
          context,
          ref,
          data,
          isDark: isDark,
          primary: primary,
          bg: bg,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SubjectDetailData data, {
    required bool isDark,
    required Color primary,
    required Color bg,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    final isWeekly = ref.watch(subjectDetailPeriodNotifierProvider);

    return CustomScrollView(
      slivers: [
        // ── Hero SliverAppBar ──────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) async {
                if (v == 'edit') {
                  context.push('/subjects/edit', extra: data.subject);
                } else if (v == 'delete') {
                  final ok = await _confirmDelete(context, ref, data.subject);
                  if (ok && context.mounted) context.pop();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Subject')),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Subject',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primary.withAlpha(180)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 56, AppSpacing.lg, AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data.subject.name,
                              style: AppTextStyles.headlineLg.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (data.subject.faculty != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                data.subject.faculty!,
                                style: AppTextStyles.bodyLg.copyWith(
                                    color: Colors.white.withAlpha(200)),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            _RiskBadge(status: data.riskLevel),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AttendanceProgressRing(
                        percentage: data.percentage,
                        size: 90,
                        strokeWidth: 8,
                        color: Colors.white,
                        showPercentage: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Metric Grid ───────────────────────────────────────────────
              _SectionTitle(title: 'Overview', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    label: 'Attended',
                    value: '${data.subject.attendedClasses}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                  _MetricCard(
                    label: 'Total Classes',
                    value: '${data.subject.totalClasses}',
                    icon: Icons.class_outlined,
                    color: primary,
                    isDark: isDark,
                  ),
                  _MetricCard(
                    label: 'Safe Bunks',
                    value: '${data.safeBunks}',
                    icon: Icons.event_busy_outlined,
                    color: data.safeBunks > 0
                        ? AppColors.success
                        : AppColors.error,
                    isDark: isDark,
                  ),
                  _MetricCard(
                    label: 'Classes Needed',
                    value: data.classesNeeded > 0
                        ? '+${data.classesNeeded}'
                        : 'On Track',
                    icon: Icons.trending_up,
                    color: data.classesNeeded > 0
                        ? AppColors.warning
                        : AppColors.success,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Trend Chart ───────────────────────────────────────────────
              _SectionTitle(title: 'Attendance Trend', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              _TrendCard(
                isDark: isDark,
                primary: primary,
                isWeekly: isWeekly,
                spots:
                    isWeekly ? data.weeklyTrend : data.monthlyTrend,
                onToggle: (v) {
                  if (v) {
                    ref
                        .read(subjectDetailPeriodNotifierProvider.notifier)
                        .setWeekly();
                  } else {
                    ref
                        .read(subjectDetailPeriodNotifierProvider.notifier)
                        .setMonthly();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Recent Attendance ─────────────────────────────────────────
              _SectionTitle(
                  title: 'Recent Attendance',
                  isDark: isDark,
                  action: data.logs.length > 5
                      ? TextButton(
                          onPressed: () =>
                              context.push('/attendance/history'),
                          child: Text('View All',
                              style: AppTextStyles.labelMd
                                  .copyWith(color: primary)),
                        )
                      : null),
              const SizedBox(height: AppSpacing.sm),
              if (data.logs.isEmpty)
                _EmptyCard(
                  icon: Icons.history_outlined,
                  message: 'No attendance records yet',
                  isDark: isDark,
                )
              else
                ...data.logs.take(5).map((log) => _SubjectLogTile(
                      log: log,
                      isDark: isDark,
                    )),
              const SizedBox(height: AppSpacing.lg),

              // ── Upcoming Classes ──────────────────────────────────────────
              _SectionTitle(title: 'Upcoming Classes', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              if (data.upcomingSessions.isEmpty)
                _EmptyCard(
                  icon: Icons.event_outlined,
                  message: 'No upcoming sessions scheduled',
                  isDark: isDark,
                )
              else
                ...data.upcomingSessions
                    .take(5)
                    .map((s) => _SessionTile(session: s, isDark: isDark)),
            ]),
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(
      BuildContext context, WidgetRef ref, SubjectModel s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
            'Delete "${s.name}"? All attendance logs for this subject will remain but the subject tracker will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(subjectRepositoryProvider).deleteSubject(s.id);
      return true;
    }
    return false;
  }

  Widget _buildSkeleton(BuildContext context, Color bg, bool isDark) {
    final shimmer =
        isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow;
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(height: 240, color: shimmer),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(children: [
              for (int i = 0; i < 4; i++) ...[
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
      BuildContext context, String error, Color bg, Color primary) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Failed to load subject', style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.sm),
            Text(error,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── Risk Badge ────────────────────────────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  final calc.AttendanceStatus status;
  const _RiskBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      calc.AttendanceStatus.excellent => (
          AppColors.success.withAlpha(40),
          Colors.white,
          '✅ Excellent',
        ),
      calc.AttendanceStatus.good => (
          AppColors.success.withAlpha(30),
          Colors.white,
          '👍 Good',
        ),
      calc.AttendanceStatus.safe => (
          Colors.white.withAlpha(30),
          Colors.white,
          '✓ Safe',
        ),
      calc.AttendanceStatus.risky => (
          AppColors.warning.withAlpha(50),
          Colors.white,
          '⚠️ Watch',
        ),
      calc.AttendanceStatus.critical => (
          AppColors.error.withAlpha(60),
          Colors.white,
          '🚨 Critical',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Text(label,
          style:
              AppTextStyles.labelMd.copyWith(color: fg, fontSize: 12)),
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: AppTextStyles.headlineMd
                        .copyWith(color: onSurface, fontSize: 18)),
                Text(label,
                    style: AppTextStyles.labelMd.copyWith(
                        color: onSurfaceVariant, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trend Card ────────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool isWeekly;
  final List<FlSpot> spots;
  final void Function(bool) onToggle;

  const _TrendCard({
    required this.isDark,
    required this.primary,
    required this.isWeekly,
    required this.spots,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final gridColor =
        (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant)
            .withAlpha(80);
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final hasData = spots.any((s) => s.y > 0);
    final weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthLabels = ['W1', 'W2', 'W3', 'W4'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trend',
                  style:
                      AppTextStyles.labelMd.copyWith(color: onSurface)),
              ToggleButtons(
                isSelected: [isWeekly, !isWeekly],
                onPressed: (i) => onToggle(i == 0),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
                constraints:
                    const BoxConstraints(minWidth: 56, minHeight: 28),
                selectedColor: Colors.white,
                fillColor: primary,
                color: AppColors.outline,
                textStyle: AppTextStyles.labelMd.copyWith(fontSize: 11),
                children: const [Text('Week'), Text('Month')],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: hasData
                ? LineChart(LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: gridColor, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final labels =
                                isWeekly ? weekLabels : monthLabels;
                            final i = v.round();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox();
                            }
                            return Text(labels[i],
                                style: AppTextStyles.labelCaps.copyWith(
                                    color: AppColors.outline,
                                    fontSize: 9));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: primary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                            radius: 3,
                            color: primary,
                            strokeWidth: 2,
                            strokeColor: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: primary.withAlpha(25),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                  ))
                : Center(
                    child: Text('No data yet',
                        style: AppTextStyles.bodyLg.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant))),
          ),
        ],
      ),
    );
  }
}

// ── Subject Log Tile ──────────────────────────────────────────────────────────

class _SubjectLogTile extends StatelessWidget {
  final AttendanceLogModel log;
  final bool isDark;

  const _SubjectLogTile({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final color = _statusColor(log.status);
    final icon = _statusIcon(log.status);
    final label = _statusLabel(log.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              DateFormat('EEE, d MMM y').format(log.date),
              style: AppTextStyles.bodyLg.copyWith(color: onSurface),
            ),
          ),
          if (log.startTime != null)
            Text(log.startTime!,
                style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(label,
                style: AppTextStyles.labelMd
                    .copyWith(color: color, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => AppColors.success,
        AttendanceStatus.absent => AppColors.error,
        AttendanceStatus.late => AppColors.warning,
        AttendanceStatus.cancelled => AppColors.outline,
      };

  IconData _statusIcon(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => Icons.check_circle_rounded,
        AttendanceStatus.absent => Icons.cancel_rounded,
        AttendanceStatus.late => Icons.access_time_filled,
        AttendanceStatus.cancelled => Icons.event_busy_rounded,
      };

  String _statusLabel(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.cancelled => 'Cancelled',
      };
}

// ── Session Tile ──────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final ClassSession session;
  final bool isDark;

  const _SessionTile({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final now = DateTime.now();
    final isToday = session.date.year == now.year &&
        session.date.month == now.month &&
        session.date.day == now.day;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isToday ? primary.withAlpha(80) : border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withAlpha(isToday ? 30 : 15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_outlined, color: primary, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('EEE, d MMM').format(session.date),
                  style: AppTextStyles.bodyLg.copyWith(
                      color: onSurface, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${session.startTime} – ${session.endTime}${session.room != null ? ' • ${session.room}' : ''}',
                  style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text('Today',
                  style: AppTextStyles.labelMd
                      .copyWith(color: primary, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? action;

  const _SectionTitle({required this.title, required this.isDark, this.action});

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                AppTextStyles.headlineMd.copyWith(color: onSurface)),
        if (action != null) action!,
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _EmptyCard(
      {required this.icon, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(message,
              style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
