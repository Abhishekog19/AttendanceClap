import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/subject_prediction.dart';
import '../services/predictor_service.dart';

/// Semester forecast card — premium redesign.
/// Shows a stacked dual-bar for current vs projected per subject.
class SemesterForecastCard extends StatelessWidget {
  final PredictorData data;
  /// Filtered subject list (respects user's subject filter).
  final List<SubjectPrediction> filtered;
  const SemesterForecastCard({
    super.key,
    required this.data,
    required this.filtered,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final daysLeft =
        data.semester.endDate.difference(DateTime.now()).inDays.clamp(0, 999);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Semester Forecast',
                          style: AppTextStyles.headlineMd.copyWith(
                              color: onSurface, fontSize: 17)),
                      Text(
                        'If you attend all remaining classes',
                        style: TextStyle(
                            fontSize: 11, color: onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Days left badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_bottom_rounded,
                          size: 10, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        '$daysLeft days',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Overall projection highlight ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.08),
                    AppColors.success.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Overall',
                            style: TextStyle(
                                fontSize: 11,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w500)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${data.overallCurrentPct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                                height: 1.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            color: primary, size: 20),
                        Text(
                          '+${(data.overallProjectedPct - data.overallCurrentPct).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Projected',
                            style: TextStyle(
                                fontSize: 11,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.right),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${data.overallProjectedPct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                                height: 1.1),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                _LegendDot(color: primary, label: 'Current'),
                const SizedBox(width: 16),
                _LegendDot(
                    color: AppColors.success.withValues(alpha: 0.4),
                    label: 'Projected'),
              ],
            ),
          ),

          // ── Per-subject forecast bars ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
            child: Column(
              children: filtered.map((p) => _ForecastRow(
                    prediction: p,
                    isDark: isDark,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final SubjectPrediction prediction;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _ForecastRow({
    required this.prediction,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerHigh;

    final current = (prediction.currentPct / 100).clamp(0.0, 1.0);
    final projected = (prediction.projectedPct / 100).clamp(0.0, 1.0);
    final delta = prediction.projectedPct - prediction.currentPct;
    final isBelowGoal = prediction.currentPct < prediction.goal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prediction.name,
                  style: TextStyle(
                      fontSize: 13,
                      color: onSurface,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isBelowGoal)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${prediction.currentPct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error),
                  ),
                ),
              Icon(Icons.arrow_forward_rounded,
                  size: 12, color: onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${prediction.projectedPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              if (delta > 0.1) ...[
                const SizedBox(width: 4),
                Text(
                  '+${delta.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Dual bar: projected (lighter) behind, current on top
          Stack(
            children: [
              // Projected bar (background)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: projected,
                  minHeight: 8,
                  backgroundColor: trackColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.success.withValues(alpha: 0.35)),
                ),
              ),
              // Current bar (foreground)
              FractionallySizedBox(
                widthFactor: current,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isBelowGoal ? AppColors.error : primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
