import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg.withAlpha(230),
        title: Text('AttendanceAI',
            style: AppTextStyles.headlineMd.copyWith(color: primary)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analytics Dashboard',
                        style: AppTextStyles.headlineLg.copyWith(color: onSurface)),
                    Text('Real-time attendance insights.',
                        style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Attendance Trends ──────────────────────────────────────────
            _GlassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Attendance Trends',
                          style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
                      Row(
                        children: [
                          _Legend(color: primary, label: 'Present', isDark: isDark),
                          const SizedBox(width: AppSpacing.md),
                          _Legend(color: AppColors.tertiary, label: 'Late', isDark: isDark),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 200,
                    child: _TrendLineChart(isDark: isDark, primary: primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Stats Row ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _GlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVERAGE ATTENDANCE',
                          style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(dashboardAsync.valueOrNull?.overallPercentage ?? 0).toStringAsFixed(1)}%',
                              style: AppTextStyles.displayLg.copyWith(
                                fontSize: 36, color: primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (dashboardAsync.valueOrNull?.overallPercentage ?? 0) / 100,
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
                        Text(
                          'SUBJECTS',
                          style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${dashboardAsync.valueOrNull?.subjects.length ?? 0}',
                          style: AppTextStyles.displayLg.copyWith(
                            fontSize: 36, color: onSurface),
                        ),
                        Text(
                          'tracked this semester',
                          style: AppTextStyles.labelMd.copyWith(color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Subject Comparison ─────────────────────────────────────────
            _GlassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject Comparison',
                      style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
                  const SizedBox(height: AppSpacing.md),
                  dashboardAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const SizedBox(),
                    data: (data) => Column(
                      children: data.subjects.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(s.name,
                                        style: AppTextStyles.labelMd.copyWith(color: onSurface),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text(
                                    '${s.attendancePercentage.toStringAsFixed(0)}%',
                                    style: AppTextStyles.labelMd.copyWith(color: onSurface),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: s.attendancePercentage / 100,
                                  backgroundColor: isDark
                                      ? AppColors.darkSurfaceContainerHigh
                                      : AppColors.surfaceContainer,
                                  color: primary.withAlpha(
                                      (200 * (s.attendancePercentage / 100)).round()),
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

            // ─── Activity Heatmap ───────────────────────────────────────────
            _GlassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Activity Heatmap',
                          style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
                      Row(
                        children: [
                          Text('Less', style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant)),
                          const SizedBox(width: 4),
                          ...List.generate(4, (i) => Container(
                            width: 10, height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: primary.withAlpha((50 + i * 60).clamp(0, 255)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )),
                          const SizedBox(width: 4),
                          Text('More', style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActivityHeatmap(isDark: isDark, primary: primary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Predictor Insight CTA ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimaryContainer.withAlpha(60)
                    : AppColors.primaryFixed.withAlpha(100),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isDark ? AppColors.darkPrimaryContainer : AppColors.primaryFixed,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                    child: const Icon(Icons.query_stats, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance Predictor',
                            style: AppTextStyles.headlineMd.copyWith(color: primary)),
                        Text(
                          'Based on current trends, simulate your future attendance.',
                          style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          color: isDark ? AppColors.darkOutlineVariant : const Color(0xFFE2E8F0),
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

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _Legend({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelMd.copyWith(
          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
        )),
      ],
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const _TrendLineChart({required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final gridColor = (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant)
        .withAlpha(100);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final i = v.round();
                if (i < 0 || i >= days.length) return const SizedBox();
                return Text(days[i],
                    style: AppTextStyles.labelCaps.copyWith(
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                    ));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 80), FlSpot(1, 70), FlSpot(2, 75),
              FlSpot(3, 40), FlSpot(4, 50), FlSpot(5, 80), FlSpot(6, 70),
            ],
            isCurved: true,
            color: primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: primary,
                strokeWidth: 2,
                strokeColor: isDark ? AppColors.darkSurface : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primary.withAlpha(26),
            ),
          ),
          LineChartBarData(
            spots: const [
              FlSpot(0, 90), FlSpot(1, 85), FlSpot(2, 88),
              FlSpot(3, 70), FlSpot(4, 75), FlSpot(5, 60), FlSpot(6, 65),
            ],
            isCurved: true,
            color: AppColors.tertiary,
            barWidth: 2,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const _ActivityHeatmap({required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final rand = Random(42);
    final cells = List.generate(105, (_) => rand.nextDouble());

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
        final opacity = (cells[i] * 0.9 + 0.1);
        return Container(
          decoration: BoxDecoration(
            color: primary.withAlpha((opacity * 255).round()),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
