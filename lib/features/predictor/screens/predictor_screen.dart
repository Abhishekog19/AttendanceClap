import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/predictor_provider.dart';
import '../services/predictor_service.dart';
import '../widgets/bunk_bank_card.dart';
import '../widgets/leave_planner_card.dart';
import '../widgets/subjects_requiring_attention_card.dart';
import '../widgets/tomorrow_opportunities_card.dart';

// =============================================================================
// Predictor V1 - Deprecated
// Retained for future reference
// =============================================================================
// import '../models/subject_prediction.dart';
// import '../widgets/leave_planner_card.dart';
// import '../widgets/overall_summary_card.dart';
// import '../widgets/risk_radar_section.dart';
// import '../widgets/semester_forecast_card.dart';
// import '../widgets/subject_prediction_card.dart';
// import '../widgets/what_if_simulator.dart';
// =============================================================================
// End Predictor V1 - Deprecated
// =============================================================================

class PredictorScreen extends ConsumerWidget {
  const PredictorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final dataAsync = ref.watch(predictorDataProvider);

    return Scaffold(
      backgroundColor: bg,
      body: dataAsync.when(
        loading: () => _LoadingBody(isDark: isDark, primary: primary),
        error: (e, _) => _ErrorBody(error: e.toString(), isDark: isDark),
        data: (data) {
          if (data == null) {
            return _EmptyBody(
              isDark: isDark,
              primary: primary,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            );
          }
          return _PredictorContent(data: data, isDark: isDark);
        },
      ),
    );
  }
}

// ─── Main content — V2 ────────────────────────────────────────────────────────

class _PredictorContent extends ConsumerWidget {
  final PredictorData data;
  final bool isDark;
  const _PredictorContent({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── App bar ──────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: AppSpacing.md,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Predictor',
                      style: AppTextStyles.headlineMd.copyWith(
                          color: onSurface, fontWeight: FontWeight.w800)),
                  Text(
                    '${data.predictions.length} subjects · Plan your attendance',
                    style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Section 1: Bunk Bank (hero card) ─────────────────────
              BunkBankCard(data: data),
              const SizedBox(height: AppSpacing.md),

              // ── Section 2: Tomorrow's Opportunities ──────────────────
              const TomorrowOpportunitiesCard(),
              // Hidden automatically when no classes tomorrow

              const SizedBox(height: AppSpacing.md),

              // ── Section 3: Leave Planner ──────────────────────────────
              LeavePlannerCard(data: data),
              const SizedBox(height: AppSpacing.md),

              // ── Section 4: Subjects Requiring Attention ───────────────
              // Only shown when a leave range is selected and subjects drop
              // below target — hidden otherwise.
              const SubjectsRequiringAttentionCard(),

              // ==========================================================
              // Predictor V1 - Deprecated
              // Retained for future reference
              // ==========================================================
              //
              // // ── Global subject filter ─────────────────────────────
              // _SubjectFilterBar(predictions: data.predictions, isDark: isDark),
              // const SizedBox(height: AppSpacing.md),
              //
              // // ── Hero card (always all subjects) ───────────────────
              // OverallSummaryCard(data: data),
              // const SizedBox(height: AppSpacing.md),
              //
              // // ── Risk radar ────────────────────────────────────────
              // _CollapsibleSection(
              //   title: 'Danger Radar',
              //   subtitle: 'Risk levels at a glance',
              //   icon: Icons.radar_outlined,
              //   isDark: isDark,
              //   child: RiskRadarSection(predictions: filtered),
              // ),
              // const SizedBox(height: AppSpacing.md),
              //
              // // ── Subject cards ─────────────────────────────────────
              // _CollapsibleSection(
              //   title: 'Subject Predictions',
              //   subtitle: 'Tap a card to simulate bunks',
              //   icon: Icons.auto_graph_rounded,
              //   isDark: isDark,
              //   child: Column(
              //     children: filtered.map((p) => Padding(
              //           padding:
              //               const EdgeInsets.only(bottom: AppSpacing.sm),
              //           child: SubjectPredictionCard(
              //             prediction: p,
              //             onTap: () =>
              //                 WhatIfSimulator.show(context, p),
              //           ),
              //         )).toList(),
              //   ),
              // ),
              // const SizedBox(height: AppSpacing.md),
              //
              // // ── Leave planner (V1) ───────────────────────────────
              // _CollapsibleSection(
              //   title: 'Leave Planner',
              //   subtitle: 'Simulate a leave period',
              //   icon: Icons.beach_access_rounded,
              //   isDark: isDark,
              //   child: LeavePlannerCard(data: data),
              // ),
              // const SizedBox(height: AppSpacing.md),
              //
              // // ── Semester forecast ─────────────────────────────────
              // _CollapsibleSection(
              //   title: 'Semester Forecast',
              //   subtitle: 'End-of-semester projection',
              //   icon: Icons.flag_rounded,
              //   isDark: isDark,
              //   child: SemesterForecastCard(data: data, filtered: filtered),
              // ),
              // ==========================================================
              // End Predictor V1 - Deprecated
              // ==========================================================
            ]),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Predictor V1 - Deprecated
// Retained for future reference
// =============================================================================

// ─── Global subject filter bar ────────────────────────────────────────────────

// class _SubjectFilterBar extends ConsumerWidget {
//   final List<SubjectPrediction> predictions;
//   final bool isDark;
//   const _SubjectFilterBar(
//       {required this.predictions, required this.isDark});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final filter = ref.watch(subjectFilterProvider);
//     final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
//     final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
//     final onSurfaceVariant =
//         isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
//     final surface = isDark
//         ? AppColors.darkSurfaceContainer
//         : AppColors.surfaceContainerLowest;
//     final border =
//         isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
//
//     return Container(
//       padding: const EdgeInsets.fromLTRB(
//           AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
//       decoration: BoxDecoration(
//         color: surface,
//         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
//         border: Border.all(color: border.withValues(alpha: 0.5)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.filter_list_rounded,
//                   size: 14, color: onSurfaceVariant),
//               const SizedBox(width: AppSpacing.xs),
//               Text(
//                 'Filter subjects',
//                 style: AppTextStyles.labelCaps.copyWith(
//                     color: onSurfaceVariant, fontSize: 11),
//               ),
//               const Spacer(),
//               if (filter.isNotEmpty)
//                 GestureDetector(
//                   onTap: () => ref.read(subjectFilterProvider.notifier).state =
//                       const {},
//                   child: Text(
//                     'Clear',
//                     style: AppTextStyles.labelMd
//                         .copyWith(color: primary, fontSize: 11),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           Wrap(
//             spacing: AppSpacing.xs,
//             runSpacing: AppSpacing.xs,
//             children: [
//               _FilterChipWidget(
//                 label: 'All',
//                 selected: filter.isEmpty,
//                 primary: primary,
//                 onSurface: onSurface,
//                 isDark: isDark,
//                 onTap: () => ref.read(subjectFilterProvider.notifier).state =
//                     const {},
//               ),
//               ...predictions.map((p) => _FilterChipWidget(
//                     label: _shortName(p.name),
//                     selected: filter.contains(p.subject.id),
//                     primary: primary,
//                     onSurface: onSurface,
//                     isDark: isDark,
//                     onTap: () {
//                       final current =
//                           ref.read(subjectFilterProvider.notifier).state;
//                       final updated = Set<String>.from(current);
//                       if (updated.contains(p.subject.id)) {
//                         updated.remove(p.subject.id);
//                       } else {
//                         updated.add(p.subject.id);
//                       }
//                       ref.read(subjectFilterProvider.notifier).state =
//                           updated;
//                     },
//                   )),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _shortName(String name) {
//     if (name.length <= 14) return name;
//     return '${name.substring(0, 13)}…';
//   }
// }
//
// class _FilterChipWidget extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final Color primary;
//   final Color onSurface;
//   final bool isDark;
//   final VoidCallback onTap;
//
//   const _FilterChipWidget({
//     required this.label,
//     required this.selected,
//     required this.primary,
//     required this.onSurface,
//     required this.isDark,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: selected
//               ? primary.withValues(alpha: 0.15)
//               : (isDark
//                   ? AppColors.darkSurfaceContainerHigh
//                   : AppColors.surfaceContainerLow),
//           borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
//           border: Border.all(
//             color: selected
//                 ? primary.withValues(alpha: 0.5)
//                 : Colors.transparent,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
//             color: selected ? primary : onSurface.withValues(alpha: 0.7),
//           ),
//         ),
//       ),
//     );
//   }
// }

// ─── Collapsible section wrapper ──────────────────────────────────────────────

// class _CollapsibleSection extends StatefulWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final bool isDark;
//   final Widget child;
//
//   const _CollapsibleSection({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.isDark,
//     required this.child,
//   });
//
//   @override
//   State<_CollapsibleSection> createState() => _CollapsibleSectionState();
// }
//
// class _CollapsibleSectionState extends State<_CollapsibleSection>
//     with SingleTickerProviderStateMixin {
//   bool _expanded = true;
//   late final AnimationController _ctrl;
//   late final Animation<double> _anim;
//
//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 200),
//         value: 1.0);
//     _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
//   }
//
//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }
//
//   void _toggle() {
//     setState(() => _expanded = !_expanded);
//     if (_expanded) {
//       _ctrl.forward();
//     } else {
//       _ctrl.reverse();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final primary = widget.isDark ? AppColors.darkPrimary : AppColors.primary;
//     final onSurface =
//         widget.isDark ? AppColors.darkOnSurface : AppColors.onSurface;
//     final onSurfaceVariant = widget.isDark
//         ? AppColors.darkOnSurfaceVariant
//         : AppColors.onSurfaceVariant;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         InkWell(
//           onTap: _toggle,
//           borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
//             child: Row(
//               children: [
//                 Container(
//                   width: 30,
//                   height: 30,
//                   decoration: BoxDecoration(
//                     color: primary.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
//                   ),
//                   child: Icon(widget.icon, size: 15, color: primary),
//                 ),
//                 const SizedBox(width: AppSpacing.sm),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(widget.title,
//                           style: AppTextStyles.bodyLg.copyWith(
//                               color: onSurface,
//                               fontWeight: FontWeight.w700,
//                               fontSize: 15)),
//                       Text(widget.subtitle,
//                           style: TextStyle(
//                               fontSize: 11, color: onSurfaceVariant)),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   _expanded ? Icons.expand_less : Icons.expand_more,
//                   color: onSurfaceVariant,
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: AppSpacing.sm),
//         SizeTransition(
//           sizeFactor: _anim,
//           child: widget.child,
//         ),
//       ],
//     );
//   }
// }

// =============================================================================
// End Predictor V1 - Deprecated
// =============================================================================

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingBody extends StatefulWidget {
  final bool isDark;
  final Color primary;
  const _LoadingBody({required this.isDark, required this.primary});

  @override
  State<_LoadingBody> createState() => _LoadingBodyState();
}

class _LoadingBodyState extends State<_LoadingBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface =
        widget.isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = widget.isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) =>
                Opacity(opacity: _pulse.value, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.insights_rounded,
                  color: widget.primary, size: 36),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Crunching your data…',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: onSurface)),
          const SizedBox(height: AppSpacing.xs),
          Text('Building predictions from your timetable',
              style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _EmptyBody({
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.insights_rounded, color: primary, size: 44),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No data yet',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: onSurface)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Set up your timetable and semester\ndates to unlock predictions.',
              style: TextStyle(
                  fontSize: 14, color: onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final bool isDark;
  const _ErrorBody({required this.error, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Something went wrong',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface)),
            const SizedBox(height: AppSpacing.sm),
            Text(error,
                style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
