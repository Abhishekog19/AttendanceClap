import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/risk_level.dart';
import '../models/subject_prediction.dart';

/// Compact horizontal risk list — sorted Critical → Warning → Safe.
class RiskRadarSection extends StatelessWidget {
  final List<SubjectPrediction> predictions;
  const RiskRadarSection({super.key, required this.predictions});

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

    final groups = <RiskLevel, List<SubjectPrediction>>{};
    for (final p in predictions) {
      groups.putIfAbsent(p.riskLevel, () => []).add(p);
    }

    final critical = groups[RiskLevel.critical] ?? [];
    final warning = groups[RiskLevel.warning] ?? [];
    final safe = groups[RiskLevel.safe] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text('Danger Radar',
                    style: AppTextStyles.headlineMd
                        .copyWith(color: onSurface, fontSize: 17)),
                const Spacer(),
                _CountPill(RiskLevel.critical, critical.length),
                const SizedBox(width: 6),
                _CountPill(RiskLevel.warning, warning.length),
                const SizedBox(width: 6),
                _CountPill(RiskLevel.safe, safe.length),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Rows ─────────────────────────────────────────────────────────
          if (critical.isNotEmpty)
            _GroupSection(
              risk: RiskLevel.critical,
              items: critical,
              isDark: isDark,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            ),
          if (warning.isNotEmpty)
            _GroupSection(
              risk: RiskLevel.warning,
              items: warning,
              isDark: isDark,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            ),
          if (safe.isNotEmpty)
            _GroupSection(
              risk: RiskLevel.safe,
              items: safe,
              isDark: isDark,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final RiskLevel risk;
  final int count;
  const _CountPill(this.risk, this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: risk.containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: risk.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: risk.onContainerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final RiskLevel risk;
  final List<SubjectPrediction> items;
  final bool isDark;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _GroupSection({
    required this.risk,
    required this.items,
    required this.isDark,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
          child: Text(
            '${risk.emoji} ${risk.label.toUpperCase()}',
            style: AppTextStyles.labelCaps
                .copyWith(color: risk.color, fontSize: 10),
          ),
        ),
        ...items.map((p) => _RadarTile(
              prediction: p,
              isDark: isDark,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            )),
      ],
    );
  }
}

class _RadarTile extends StatelessWidget {
  final SubjectPrediction prediction;
  final bool isDark;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _RadarTile({
    required this.prediction,
    required this.isDark,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final risk = prediction.riskLevel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          // Dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: risk.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Subject name
          Expanded(
            flex: 3,
            child: Text(
              prediction.name,
              style: AppTextStyles.bodySm
                  .copyWith(color: onSurface, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Mini progress bar
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (prediction.currentPct / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: risk.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(risk.color),
                ),
              ),
            ),
          ),

          // Percentage
          Text(
            '${prediction.currentPct.toStringAsFixed(1)}%',
            style: AppTextStyles.labelMd.copyWith(
                color: risk.color, fontWeight: FontWeight.w700, fontSize: 11),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Safe bunks
          Text(
            prediction.safeBunks == 0
                ? '0 bunk'
                : '${prediction.safeBunks} bunk${prediction.safeBunks == 1 ? '' : 's'}',
            style: AppTextStyles.labelMd.copyWith(
                color: onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
