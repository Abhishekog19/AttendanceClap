import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final logsAsync = ref.watch(analyticsLogsStreamProvider);
    final summary = ref.watch(analyticsSummaryProvider);
    final insights = ref.watch(analyticsInsightsProvider);
    final period = ref.watch(analyticsPeriodNotifierProvider);
    final spots = ref.watch(trendDataProvider);
    final heatmap = ref.watch(heatmapDataProvider);
    final dashboardAsync = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg.withAlpha(230),
        title: Text('AttendanceAI',
            style: AppTextStyles.headlineMd.copyWith(color: primary)),
        actions: [
          IconButton(
            icon: Icon(Icons.history_outlined, color: onSurfaceVariant),
            tooltip: 'Attendance History',
            onPressed: () => context.push('/attendance/history'),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load analytics',
                  style: AppTextStyles.headlineMd
                      .copyWith(color: AppColors.error)),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(analyticsLogsStreamProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analytics Dashboard',
                          style: AppTextStyles.headlineLg
                              .copyWith(color: onSurface)),
                      Text('Real-time attendance insights.',
                          style: AppTextStyles.bodyLg
                              .copyWith(color: onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Summary Cards Row ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _GlassCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OVERALL ATTENDANCE',
                              style: AppTextStyles.labelCaps
                                  .copyWith(color: onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${summary.overallPercentage.toStringAsFixed(1)}%',
                            style: AppTextStyles.displayLg.copyWith(
                                fontSize: 36, color: primary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: summary.overallPercentage / 100,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceContainerHigh
                                  : AppColors.surfaceContainer,
                              color: primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _GlassCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SUBJECTS',
                              style: AppTextStyles.labelCaps
                                  .copyWith(color: onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${summary.totalSubjects}',
                            style: AppTextStyles.displayLg.copyWith(
                                fontSize: 36, color: onSurface),
                          ),
                          Text(
                            'tracked this semester',
                            style: AppTextStyles.labelMd
                                .copyWith(color: onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Classes Stats Row ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatMiniCard(
                      label: 'Attended',
                      value: '${summary.totalAttended}',
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatMiniCard(
                      label: 'Missed',
                      value: '${summary.totalMissed}',
                      color: AppColors.error,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatMiniCard(
                      label: 'Total',
                      value: '${summary.totalClasses}',
                      color: primary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Attendance Trends ─────────────────────────────────────────
              _GlassCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Attendance Trends',
                            style: AppTextStyles.headlineMd
                                .copyWith(color: onSurface)),
                        // Period selector
                        ToggleButtons(
                          isSelected: [
                            period == AnalyticsPeriod.week,
                            period == AnalyticsPeriod.month,
                            period == AnalyticsPeriod.semester,
                          ],
                          onPressed: (i) {
                            ref
                                .read(analyticsPeriodNotifierProvider.notifier)
                                .set(AnalyticsPeriod.values[i]);
                          },
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                          constraints: const BoxConstraints(
                              minWidth: 48, minHeight: 28),
                          selectedColor: Colors.white,
                          fillColor: primary,
                          color: AppColors.outline,
                          textStyle:
                              AppTextStyles.labelMd.copyWith(fontSize: 10),
                          children: const [
                            Text('Week'),
                            Text('Month'),
                            Text('Semester'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 200,
                      child: _RealTrendChart(
                          isDark: isDark, primary: primary, spots: spots, period: period),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Subject Comparison ────────────────────────────────────────
              _GlassCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subject Comparison',
                        style: AppTextStyles.headlineMd
                            .copyWith(color: onSurface)),
                    const SizedBox(height: AppSpacing.md),
                    dashboardAsync.when(
                      loading: () =>
                          const LinearProgressIndicator(),
                      error: (e, _) => const SizedBox(),
                      data: (data) => data.subjects.isEmpty
                          ? Text('No subjects yet',
                              style: AppTextStyles.bodyLg.copyWith(
                                  color: onSurfaceVariant))
                          : Column(
                              children: data.subjects.map((s) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(s.name,
                                                style: AppTextStyles.labelMd
                                                    .copyWith(
                                                        color: onSurface),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          Text(
                                            '${s.attendancePercentage.toStringAsFixed(0)}%',
                                            style: AppTextStyles.labelMd
                                                .copyWith(color: onSurface),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value:
                                              s.attendancePercentage / 100,
                                          backgroundColor: isDark
                                              ? AppColors
                                                  .darkSurfaceContainerHigh
                                              : AppColors.surfaceContainer,
                                          color: primary.withAlpha((200 *
                                                  (s.attendancePercentage /
                                                      100))
                                              .round()),
                                          minHeight: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Activity Heatmap ──────────────────────────────────────────
              _GlassCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Activity Heatmap',
                            style: AppTextStyles.headlineMd
                                .copyWith(color: onSurface)),
                        Row(
                          children: [
                            Text('Less',
                                style: AppTextStyles.labelCaps
                                    .copyWith(color: onSurfaceVariant)),
                            const SizedBox(width: 4),
                            ...List.generate(
                                4,
                                (i) => Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: primary.withAlpha(
                                            (50 + i * 60).clamp(0, 255)),
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    )),
                            const SizedBox(width: 4),
                            Text('More',
                                style: AppTextStyles.labelCaps
                                    .copyWith(color: onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RealHeatmap(
                        isDark: isDark,
                        primary: primary,
                        heatmap: heatmap),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── AI Insights ───────────────────────────────────────────────
              if (insights.isNotEmpty) ...[
                _GlassCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: primary, size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Attendance Insights',
                              style: AppTextStyles.headlineMd
                                  .copyWith(color: onSurface)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...insights.map((insight) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.md),
                            child: _InsightTile(
                                insight: insight, isDark: isDark),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── History CTA ───────────────────────────────────────────────
              GestureDetector(
                onTap: () => context.push('/attendance/history'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer.withAlpha(60)
                        : AppColors.primaryFixed.withAlpha(100),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.primaryFixed,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: primary, shape: BoxShape.circle),
                        child: const Icon(Icons.history,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('View Full History',
                                style: AppTextStyles.headlineMd
                                    .copyWith(color: primary)),
                            Text(
                              'Browse, filter, and edit all your attendance records.',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: primary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Real Trend Chart ──────────────────────────────────────────────────────────

class _RealTrendChart extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final List<FlSpot> spots;
  final AnalyticsPeriod period;

  const _RealTrendChart({
    required this.isDark,
    required this.primary,
    required this.spots,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final gridColor =
        (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant)
            .withAlpha(100);

    final hasData = spots.any((s) => s.y > 0);

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 48,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text('No data for this period',
                style: AppTextStyles.bodyLg.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    final weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthLabels = ['W1', 'W2', 'W3', 'W4'];
    final now = DateTime.now();
    final semLabels = List.generate(
        6, (i) => DateFormat('MMM').format(DateTime(now.year, now.month - (5 - i))));

    List<String> labels;
    switch (period) {
      case AnalyticsPeriod.week:
        labels = weekLabels;
      case AnalyticsPeriod.month:
        labels = monthLabels;
      case AnalyticsPeriod.semester:
        labels = semLabels;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
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
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Text(labels[i],
                    style: AppTextStyles.labelCaps.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.outline,
                      fontSize: 9,
                    ));
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
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: primary,
                strokeWidth: 2,
                strokeColor:
                    isDark ? AppColors.darkSurface : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primary.withAlpha(26),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }
}

// ── Real Heatmap ──────────────────────────────────────────────────────────────

class _RealHeatmap extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final Map<String, int> heatmap;

  const _RealHeatmap({
    required this.isDark,
    required this.primary,
    required this.heatmap,
  });

  @override
  Widget build(BuildContext context) {
    // Show last 15 weeks = 105 days
    final now = DateTime.now();
    final cells = List.generate(105, (i) {
      final day = now.subtract(Duration(days: 104 - i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return heatmap[key] ?? 0;
    });

    final maxCount = cells.isEmpty
        ? 1
        : cells.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 15,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 1,
      ),
      itemCount: cells.length,
      itemBuilder: (_, i) {
        final count = cells[i];
        final intensity = count == 0 ? 0.08 : (count / maxCount).clamp(0.2, 1.0);
        return Tooltip(
          message: count == 0 ? 'No classes' : '$count class${count > 1 ? 'es' : ''}',
          child: Container(
            decoration: BoxDecoration(
              color: primary.withAlpha((intensity * 255).round()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}

// ── Insight Tile ──────────────────────────────────────────────────────────────

class _InsightTile extends StatelessWidget {
  final AnalyticsInsight insight;
  final bool isDark;

  const _InsightTile({required this.insight, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final (bg, iconColor) = switch (insight.type) {
      InsightType.positive => (AppColors.successContainer, AppColors.success),
      InsightType.warning => (AppColors.warningContainer, AppColors.warning),
      InsightType.critical => (AppColors.errorContainer, AppColors.error),
      InsightType.neutral => (
          isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow,
          AppColors.outline
        ),
    };

    final icon = switch (insight.type) {
      InsightType.positive => Icons.trending_up,
      InsightType.warning => Icons.warning_outlined,
      InsightType.critical => Icons.report_outlined,
      InsightType.neutral => Icons.info_outlined,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.title,
                  style: AppTextStyles.labelMd.copyWith(
                      color: onSurface, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(insight.subtitle,
                  style:
                      AppTextStyles.bodySm.copyWith(color: onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Glass Card ────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(13)
            : Colors.white.withAlpha(178),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Stat Mini Card ────────────────────────────────────────────────────────────

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatMiniCard({
    required this.label,
    required this.value,
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

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headlineMd
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
          Text(label,
              style: AppTextStyles.labelCaps
                  .copyWith(color: color.withAlpha(180), fontSize: 9)),
        ],
      ),
    );
  }
}
