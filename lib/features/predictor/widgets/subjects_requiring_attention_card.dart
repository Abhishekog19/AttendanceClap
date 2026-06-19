import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/leave_plan_result.dart';
import '../providers/predictor_provider.dart';
import '../services/predictor_service.dart';

/// Predictor V2 — Section 4: Subjects Requiring Attention.
///
/// Only displayed after a leave range is selected AND at least one subject
/// drops below the attendance goal. Shows each affected subject with its
/// current → after-leave attendance and the computed recovery date.
///
/// Uses [leavePlanResultProvider] + [predictorDataProvider] — zero new
/// Firebase reads.
class SubjectsRequiringAttentionCard extends ConsumerWidget {
  const SubjectsRequiringAttentionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(leavePlanResultProvider);
    final dataAsync = ref.watch(predictorDataProvider);
    final range = ref.watch(leavePlannerNotifierProvider);

    final data = dataAsync.valueOrNull;
    if (result == null || data == null || range == null) {
      return const SizedBox.shrink();
    }

    // Only subjects that drop below goal
    final affected =
        result.subjectImpacts.where((i) => i.isBelow(data.goal)).toList();
    if (affected.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

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
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.healing_outlined,
                      size: 18, color: AppColors.error),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subjects Requiring Attention',
                        style: AppTextStyles.headlineMd.copyWith(
                            color: onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${affected.length} subject${affected.length == 1 ? '' : 's'} below goal after leave',
                        style:
                            TextStyle(fontSize: 11, color: onSurfaceVariant),
                      ),
                    ],
                  ),
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

          // ── Subject cards ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Column(
              children: affected
                  .map((impact) => _AttentionSubjectCard(
                        impact: impact,
                        data: data,
                        leaveEnd: range.end,
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
}

// ─── Single affected subject card ─────────────────────────────────────────────

class _AttentionSubjectCard extends StatelessWidget {
  final SubjectLeaveImpact impact;
  final PredictorData data;
  final DateTime leaveEnd;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _AttentionSubjectCard({
    required this.impact,
    required this.data,
    required this.leaveEnd,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerLow;

    // Find matching prediction for recovery date calculation
    final pred = data.predictions
        .where((p) => p.subject.id == impact.subjectId)
        .firstOrNull;

    DateTime? recovery;
    if (pred != null) {
      recovery = PredictorService.recoveryDate(
        impact: impact,
        prediction: pred,
        entries: data.entries,
        semester: data.semester,
        leaveEnd: leaveEnd,
        goal: data.goal,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Subject name + warning icon ─────────────────────────────
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  impact.subjectName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Attendance impact row ────────────────────────────────────
          Row(
            children: [
              // Current
              _StatBox(
                label: 'Current',
                value: '${impact.pctBefore.toStringAsFixed(1)}%',
                color: impact.pctBefore >= data.goal
                    ? AppColors.success
                    : AppColors.error,
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Icons.arrow_downward_rounded,
                    size: 14, color: AppColors.error.withValues(alpha: 0.7)),
              ),

              // After leave
              _StatBox(
                label: 'After Leave',
                value: '${impact.pctAfter.toStringAsFixed(1)}%',
                color: AppColors.error,
              ),

              const Spacer(),

              // Target
              _StatBox(
                label: 'Target',
                value: '${data.goal.toStringAsFixed(0)}%',
                color: onSurfaceVariant,
                small: true,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Recovery guidance ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.error),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    recovery != null
                        ? 'Attend every ${impact.subjectName} lecture until: ${_fmtDate(recovery)}'
                        : 'Not recoverable within this semester',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ─── Stat box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool small;
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: small ? 14 : 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
