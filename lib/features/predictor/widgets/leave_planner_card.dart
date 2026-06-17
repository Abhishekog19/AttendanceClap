import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/leave_plan_result.dart';
import '../providers/predictor_provider.dart';
import '../services/predictor_service.dart';

/// Leave planner card — with recovery guidance.
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
                        'See impact + recovery plan',
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
                      color:
                          const Color(0xFF0D9488).withValues(alpha: 0.25)),
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

          if (result == null) ...[
            // Placeholder hint
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              child: Text(
                'Pick a date range to see how a leave affects each subject — and exactly how many classes to attend afterwards to recover.',
                style: TextStyle(
                    fontSize: 13, color: onSurfaceVariant, height: 1.5),
              ),
            ),
          ] else ...[
            // ── Overall impact card ─────────────────────────────────────
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
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: onSurfaceVariant),
                    _OverallStat(
                        label: 'After',
                        value:
                            '${result.overallAfter.toStringAsFixed(1)}%',
                        color: result.overallAfter < data.goal
                            ? AppColors.error
                            : AppColors.success),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: (result.overallDelta < 0
                                ? AppColors.error
                                : AppColors.success)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${result.overallDelta >= 0 ? '+' : ''}${result.overallDelta.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: result.overallDelta < 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!result.hasImpact) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                child: Text(
                  'No scheduled classes in this period.',
                  style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                ),
              ),
            ] else ...[
              // ── Subject impact rows ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                child: Text(
                  'SUBJECT IMPACT',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: onSurfaceVariant),
                ),
              ),
              ...result.subjectImpacts.map((impact) => _ImpactRow(
                    impact: impact,
                    goal: data.goal,
                    isDark: isDark,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  )),

              // ── Recovery section ────────────────────────────────────
              if (result.subjectImpacts.any((i) => i.recoveryNeeded > 0)) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                  child: Text(
                    'RECOVERY PLAN',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: onSurfaceVariant),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.healing_outlined,
                                size: 15, color: AppColors.error),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'After your leave, attend these extra classes to recover:',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...result.subjectImpacts
                            .where((i) => i.recoveryNeeded > 0)
                            .map((i) => _RecoveryRow(
                                  impact: i,
                                  goal: data.goal,
                                  onSurface: onSurface,
                                  onSurfaceVariant: onSurfaceVariant,
                                )),
                        if (result.totalRecoveryNeeded > 0) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(Icons.summarize_outlined,
                                  size: 13, color: AppColors.error),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Total: attend ${result.totalRecoveryNeeded} more '
                                  'class${result.totalRecoveryNeeded == 1 ? '' : 'es'} across all affected subjects',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
      BuildContext context, WidgetRef ref, DateTimeRange? current) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: data.semester.endDate,
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

// ─── Widgets ──────────────────────────────────────────────────────────────────

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

class _ImpactRow extends StatelessWidget {
  final SubjectLeaveImpact impact;
  final double goal;
  final bool isDark;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _ImpactRow({
    required this.impact,
    required this.goal,
    required this.isDark,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = impact.isBelow(goal);
    final alertColor = isAlert ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: alertColor, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(impact.subjectName,
                style: TextStyle(
                    fontSize: 13,
                    color: onSurface,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text('${impact.pctBefore.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.arrow_forward_rounded,
                size: 11, color: onSurfaceVariant),
          ),
          Text('${impact.pctAfter.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: alertColor)),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text('-${impact.missedCount}',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: alertColor)),
          ),
        ],
      ),
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  final SubjectLeaveImpact impact;
  final double goal;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _RecoveryRow({
    required this.impact,
    required this.goal,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              impact.subjectName,
              style: TextStyle(fontSize: 12, color: onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '+${impact.recoveryNeeded} class${impact.recoveryNeeded == 1 ? '' : 'es'}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
