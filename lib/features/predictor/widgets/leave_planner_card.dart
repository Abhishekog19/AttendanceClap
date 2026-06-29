import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/leave_plan_result.dart';
import '../models/subject_prediction.dart';
import '../providers/predictor_provider.dart';
import '../services/predictor_service.dart';

// =============================================================================
// Predictor V2 — Leave Planner Card
// =============================================================================
//
// Interactive card for Section 3: Leave Planner.
//
// V2 Layout:
//   1. Date range picker trigger
//   2. Total classes missed (big number)
//   3. Overall attendance impact (before → after)
//   4. Leave verdict badge: SAFE LEAVE / RISKY LEAVE / NOT RECOMMENDED
//
// The [SubjectsRequiringAttentionCard] (Section 4) is rendered separately
// in the screen and shows the per-subject recovery detail.

/// Verdict classification for the leave planner.
enum LeaveVerdict {
  /// All subjects remain above target.
  safe,

  /// Overall attendance is safe but ≥ 1 subject drops below target.
  risky,

  /// Overall attendance itself drops below target.
  notRecommended;

  String get label => switch (this) {
        LeaveVerdict.safe => 'SAFE LEAVE',
        LeaveVerdict.risky => 'RISKY LEAVE',
        LeaveVerdict.notRecommended => 'NOT RECOMMENDED',
      };

  String get description => switch (this) {
        LeaveVerdict.safe =>
          'All subjects remain above your attendance target.',
        LeaveVerdict.risky =>
          'Your overall attendance stays safe, but some subjects will drop below target.',
        LeaveVerdict.notRecommended =>
          'Your overall attendance will fall below your target.',
      };

  Color get color => switch (this) {
        LeaveVerdict.safe => AppColors.success,
        LeaveVerdict.risky => AppColors.warning,
        LeaveVerdict.notRecommended => AppColors.error,
      };

  IconData get icon => switch (this) {
        LeaveVerdict.safe => Icons.check_circle_outline_rounded,
        LeaveVerdict.risky => Icons.warning_amber_rounded,
        LeaveVerdict.notRecommended => Icons.cancel_outlined,
      };
}

LeaveVerdict _computeVerdict(
    LeavePlanResult result, double goal, List<SubjectPrediction> predictions) {
  if (result.overallAfter < goal) return LeaveVerdict.notRecommended;

  // Check subjects directly impacted by the leave
  if (result.subjectImpacts.any((i) => i.isBelow(goal))) {
    return LeaveVerdict.risky;
  }

  // Also check subjects NOT in the date range — they are excluded from
  // subjectImpacts but may already be below goal. The leave is only truly
  // SAFE when every subject (unchanged or not) remains at or above goal.
  final impactedIds =
      result.subjectImpacts.map((i) => i.subjectId).toSet();
  final anyUnaffectedBelowGoal = predictions.any((p) =>
      !impactedIds.contains(p.subject.id) &&
      p.currentPct < goal);
  if (anyUnaffectedBelowGoal) return LeaveVerdict.risky;

  return LeaveVerdict.safe;
}

// ─── Main card ────────────────────────────────────────────────────────────────

class LeavePlannerCard extends ConsumerWidget {
  final PredictorData data;
  const LeavePlannerCard({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final surface = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerLow;

    final selectedRange = ref.watch(leavePlannerNotifierProvider);
    final result = selectedRange == null
        ? null
        : PredictorService.simulateLeave(
            predictions: data.predictions,
            entries: data.entries,
            semester: data.semester,
            range: selectedRange,
          );

    // Total classes missed across all subjects in the range
    final totalMissed = result?.subjectImpacts
            .fold(0, (sum, i) => sum + i.missedCount) ??
        0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.beach_access_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Leave Planner',
                          style: AppTextStyles.headlineMd
                              .copyWith(color: onSurface, fontSize: 17)),
                      Text(
                        'Simulate a leave period',
                        style:
                            TextStyle(fontSize: 11, color: onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (selectedRange != null)
                  GestureDetector(
                    onTap: () =>
                        ref.read(leavePlannerNotifierProvider.notifier).clear(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: onSurfaceVariant.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),

          // ── Date picker trigger ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: GestureDetector(
              onTap: () => _pickDateRange(context, ref, selectedRange),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_outlined,
                        size: 18, color: Color(0xFF0D9488)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        selectedRange == null
                            ? 'Select your leave dates'
                            : '${_fmtDate(selectedRange.start)}  →  ${_fmtDate(selectedRange.end)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedRange == null
                              ? onSurfaceVariant
                              : onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),

          // ── No range selected: hint ───────────────────────────────────
          if (result == null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              child: Text(
                'Pick a date range to see how many classes you\'d miss and whether your leave is safe.',
                style: TextStyle(
                    fontSize: 13, color: onSurfaceVariant, height: 1.5),
              ),
            ),
          ] else ...[

            // ── Total classes missed ──────────────────────────────────
            if (totalMissed > 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md, horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$totalMissed',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: onSurface,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class${totalMissed == 1 ? '' : 'es'} Missed',
                        style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: Text(
                  'No scheduled classes in this period.',
                  style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                ),
              ),
            ],

            // ── Attendance impact (before → after) ─────────────────────
            if (totalMissed > 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _OverallStat(
                          label: 'Before',
                          value:
                              '${result.overallBefore.toStringAsFixed(1)}%',
                          color: onSurface),
                      Column(
                        children: [
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: onSurfaceVariant),
                          const SizedBox(height: 2),
                          Text(
                            '${result.overallDelta >= 0 ? '+' : ''}${result.overallDelta.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: result.overallDelta < 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      _OverallStat(
                          label: 'After',
                          value:
                              '${result.overallAfter.toStringAsFixed(1)}%',
                          color: result.overallAfter < data.goal
                              ? AppColors.error
                              : AppColors.success),
                    ],
                  ),
                ),
              ),

              // ── Leave Verdict ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: _VerdictBadge(
                  verdict: _computeVerdict(result, data.goal, data.predictions),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
            ],
          ],

          // =================================================================
          // Predictor V1 - Deprecated
          // Retained for future reference
          // =================================================================
          //
          // // ── Subject impact rows (V1) ───────────────────────────────
          // if (result != null && result.hasImpact) ...[
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(
          //         AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
          //     child: Text(
          //       'SUBJECT IMPACT',
          //       style: TextStyle(
          //           fontSize: 10,
          //           fontWeight: FontWeight.w700,
          //           letterSpacing: 1,
          //           color: onSurfaceVariant),
          //     ),
          //   ),
          //   ...result.subjectImpacts.map((impact) => _ImpactRow(
          //         impact: impact,
          //         goal: data.goal,
          //         isDark: isDark,
          //         onSurface: onSurface,
          //         onSurfaceVariant: onSurfaceVariant,
          //       )),
          //
          //   // ── Recovery section (V1) ─────────────────────────────────
          //   if (result.subjectImpacts.any((i) => i.recoveryNeeded > 0)) ...[
          //     const SizedBox(height: AppSpacing.sm),
          //     Padding(
          //       padding: const EdgeInsets.fromLTRB(
          //           AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
          //       child: Text(
          //         'RECOVERY PLAN',
          //         style: TextStyle(
          //             fontSize: 10,
          //             fontWeight: FontWeight.w700,
          //             letterSpacing: 1,
          //             color: onSurfaceVariant),
          //       ),
          //     ),
          //     Padding(
          //       padding: const EdgeInsets.fromLTRB(
          //           AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          //       child: Container(
          //         width: double.infinity,
          //         padding: const EdgeInsets.all(AppSpacing.md),
          //         decoration: BoxDecoration(
          //           color: AppColors.error.withValues(alpha: 0.06),
          //           borderRadius:
          //               BorderRadius.circular(AppSpacing.radiusMd),
          //           border: Border.all(
          //               color: AppColors.error.withValues(alpha: 0.2)),
          //         ),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             ...result.subjectImpacts
          //                 .where((i) => i.recoveryNeeded > 0)
          //                 .map((i) => _RecoveryRow(
          //                       impact: i,
          //                       goal: data.goal,
          //                       onSurface: onSurface,
          //                       onSurfaceVariant: onSurfaceVariant,
          //                     )),
          //             if (result.totalRecoveryNeeded > 0) ...[
          //               const SizedBox(height: AppSpacing.sm),
          //               Text(
          //                 'Total: attend ${result.totalRecoveryNeeded} more '
          //                 'class${result.totalRecoveryNeeded == 1 ? '' : 'es'} across all affected subjects',
          //                 style: const TextStyle(
          //                     fontSize: 12,
          //                     fontWeight: FontWeight.w700,
          //                     color: AppColors.error),
          //               ),
          //             ],
          //           ],
          //         ),
          //       ),
          //     ),
          //   ],
          //   const SizedBox(height: AppSpacing.sm),
          // ],
          // =================================================================
          // End Predictor V1 - Deprecated
          // =================================================================
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
      BuildContext context, WidgetRef ref, DateTimeRange? current) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final lastDate = DateTime(
      data.semester.endDate.year,
      data.semester.endDate.month,
      data.semester.endDate.day,
    );
    if (today.isAfter(lastDate)) return;

    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: lastDate,
      initialDateRange: current,
      helpText: 'SELECT LEAVE PERIOD',
      saveText: 'SIMULATE',
    );
    if (range != null) {
      ref.read(leavePlannerNotifierProvider.notifier).setRange(range);
    }
  }

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ─── Verdict badge ────────────────────────────────────────────────────────────

class _VerdictBadge extends StatelessWidget {
  final LeaveVerdict verdict;
  const _VerdictBadge({required this.verdict});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: verdict.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: verdict.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: verdict.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(verdict.icon, size: 18, color: verdict.color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: verdict.color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  verdict.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: verdict.color.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overall stat ─────────────────────────────────────────────────────────────

class _OverallStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _OverallStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// =============================================================================
// Predictor V1 - Deprecated
// Retained for future reference
// =============================================================================
//
// class _ImpactRow extends StatelessWidget {
//   final SubjectLeaveImpact impact;
//   final double goal;
//   final bool isDark;
//   final Color onSurface;
//   final Color onSurfaceVariant;
//
//   const _ImpactRow({
//     required this.impact,
//     required this.goal,
//     required this.isDark,
//     required this.onSurface,
//     required this.onSurfaceVariant,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final isAlert = impact.isBelow(goal);
//     final alertColor = isAlert ? AppColors.error : AppColors.success;
//
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//           AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
//       child: Row(
//         children: [
//           Container(
//               width: 6,
//               height: 6,
//               decoration:
//                   BoxDecoration(color: alertColor, shape: BoxShape.circle)),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Text(impact.subjectName,
//                 style: TextStyle(
//                     fontSize: 13,
//                     color: onSurface,
//                     fontWeight: FontWeight.w500),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis),
//           ),
//           Text('${impact.pctBefore.toStringAsFixed(1)}%',
//               style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
//             child: Icon(Icons.arrow_forward_rounded,
//                 size: 11, color: onSurfaceVariant),
//           ),
//           Text('${impact.pctAfter.toStringAsFixed(1)}%',
//               style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   color: alertColor)),
//           const SizedBox(width: AppSpacing.xs),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//             decoration: BoxDecoration(
//               color: alertColor.withValues(alpha: 0.08),
//               borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
//             ),
//             child: Text('-${impact.missedCount}',
//                 style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                     color: alertColor)),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _RecoveryRow extends StatelessWidget {
//   final SubjectLeaveImpact impact;
//   final double goal;
//   final Color onSurface;
//   final Color onSurfaceVariant;
//
//   const _RecoveryRow({
//     required this.impact,
//     required this.goal,
//     required this.onSurface,
//     required this.onSurfaceVariant,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: AppSpacing.xs),
//       child: Row(
//         children: [
//           const SizedBox(width: 2),
//           Expanded(
//             child: Text(
//               impact.subjectName,
//               style: TextStyle(fontSize: 12, color: onSurface),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//             decoration: BoxDecoration(
//               color: AppColors.error.withValues(alpha: 0.12),
//               borderRadius:
//                   BorderRadius.circular(AppSpacing.radiusFull),
//             ),
//             child: Text(
//               '+${impact.recoveryNeeded} class${impact.recoveryNeeded == 1 ? '' : 'es'}',
//               style: const TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.error),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// =============================================================================
// End Predictor V1 - Deprecated
// =============================================================================
