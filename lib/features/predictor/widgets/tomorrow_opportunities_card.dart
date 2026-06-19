import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/predictor_provider.dart';
import '../services/predictor_service.dart';

/// Predictor V2 — Section 2: Tomorrow's Bunk Opportunities.
///
/// Shows a compact ✓/⚠ list of tomorrow's scheduled lectures, helping the
/// student decide which classes can safely be skipped.
///
/// Hidden entirely when no classes are scheduled tomorrow or when data
/// is not yet available.
class TomorrowOpportunitiesCard extends ConsumerWidget {
  const TomorrowOpportunitiesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(tomorrowOpportunitiesProvider);

    // Hide card when nothing is scheduled tomorrow
    if (opportunities.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final safeCount =
        opportunities.where((o) => o.isSafe).length;
    final riskyCount = opportunities.length - safeCount;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(Icons.wb_twilight_rounded,
                      size: 18, color: primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tomorrow',
                        style: AppTextStyles.headlineMd.copyWith(
                            color: onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _tomorrowLabel(),
                        style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // Summary badge row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (safeCount > 0)
                      _SummaryBadge(
                        count: safeCount,
                        label: 'Skip',
                        color: AppColors.success,
                      ),
                    if (safeCount > 0 && riskyCount > 0)
                      const SizedBox(width: AppSpacing.xs),
                    if (riskyCount > 0)
                      _SummaryBadge(
                        count: riskyCount,
                        label: 'Attend',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: border.withValues(alpha: 0.4),
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),

          // ── Lecture rows ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Column(
              children: opportunities
                  .map((o) => _OpportunityRow(
                        opportunity: o,
                        onSurface: onSurface,
                        onSurfaceVariant: onSurfaceVariant,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _tomorrowLabel() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[tomorrow.weekday - 1]}, ${tomorrow.day} ${months[tomorrow.month - 1]}';
  }
}

// ─── Summary badge ────────────────────────────────────────────────────────────

class _SummaryBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _SummaryBadge(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Single lecture row ───────────────────────────────────────────────────────

class _OpportunityRow extends StatelessWidget {
  final TomorrowOpportunity opportunity;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _OpportunityRow({
    required this.opportunity,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final isSafe = opportunity.isSafe;
    final accentColor =
        isSafe ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSafe
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              size: 14,
              color: accentColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Subject name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity.subjectName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isSafe ? 'Can be skipped' : 'Should be attended',
                  style: TextStyle(
                      fontSize: 11, color: accentColor.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),

          // Time range
          Text(
            '${opportunity.startTime}–${opportunity.endTime}',
            style: TextStyle(fontSize: 11, color: onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
