import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/subject_prediction.dart';
import '../services/predictor_service.dart';

/// What-If simulator bottom sheet — premium redesign.
class WhatIfSimulator extends ConsumerStatefulWidget {
  final SubjectPrediction prediction;
  const WhatIfSimulator({super.key, required this.prediction});

  static void show(BuildContext context, SubjectPrediction prediction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => WhatIfSimulator(prediction: prediction),
    );
  }

  @override
  ConsumerState<WhatIfSimulator> createState() => _WhatIfSimulatorState();
}

class _WhatIfSimulatorState extends ConsumerState<WhatIfSimulator> {
  int _missed = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF13161F) : Colors.white;
    final surface = isDark ? const Color(0xFF1E2130) : const Color(0xFFF5F5FA);
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final maxSlider =
        widget.prediction.remainingClasses.clamp(1, 20).toDouble();
    final bd = PredictorService.whatIfBreakdown(
      prediction: widget.prediction,
      missedClasses: _missed,
    );

    final isBelow = bd.predictedPct < bd.goal;
    final accentColor = isBelow ? AppColors.error : AppColors.success;

    // Delta vs current
    final delta = bd.predictedPct - widget.prediction.currentPct;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              primary,
                              primary.withValues(alpha: 0.7)
                            ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.science_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('What If?',
                                  style: AppTextStyles.headlineMd.copyWith(
                                      color: onSurface, fontSize: 18)),
                              Text(
                                widget.prediction.name,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: onSurfaceVariant,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Hero number ────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              fontSize: _missed == 0 ? 52 : 64,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              height: 1,
                            ),
                            child: Text('$_missed'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'class${_missed == 1 ? '' : 'es'} to bunk',
                            style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Slider ─────────────────────────────────────────────
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentColor,
                        inactiveTrackColor:
                            accentColor.withValues(alpha: 0.15),
                        thumbColor: accentColor,
                        overlayColor: accentColor.withValues(alpha: 0.12),
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _missed.toDouble(),
                        min: 0,
                        max: maxSlider,
                        divisions: maxSlider.toInt(),
                        onChanged: (v) =>
                            setState(() => _missed = v.round()),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0',
                            style: TextStyle(
                                fontSize: 11, color: onSurfaceVariant)),
                        Text('Max ${maxSlider.toInt()}',
                            style: TextStyle(
                                fontSize: 11, color: onSurfaceVariant)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Before → After ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _PctTile(
                            title: 'Now',
                            pct: widget.prediction.currentPct,
                            sub:
                                '${widget.prediction.attended}/${widget.prediction.total} lecs',
                            color: onSurface,
                            surface: surface,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Icon(Icons.arrow_forward_rounded,
                                  color: onSurfaceVariant, size: 18),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: delta < 0
                                      ? AppColors.error.withValues(alpha: 0.1)
                                      : AppColors.success
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: delta < 0
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _PctTile(
                            title: 'After Bunk',
                            pct: bd.predictedPct,
                            sub:
                                '${bd.attendedSoFar}/${bd.totalLectures} lecs',
                            color: accentColor,
                            surface: surface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Breakdown card ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LECTURE BREAKDOWN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _BdRow(
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.success,
                            label: 'Attended so far',
                            value: '${bd.attendedSoFar} lecs',
                            onSurface: onSurface,
                            onSurfaceVariant: onSurfaceVariant,
                          ),
                          _BdRow(
                            icon: Icons.do_not_disturb_on_outlined,
                            iconColor: AppColors.error,
                            label: 'Planning to bunk',
                            value: '${bd.missedClasses} lecs',
                            onSurface: onSurface,
                            onSurfaceVariant: onSurfaceVariant,
                          ),
                          _BdRow(
                            icon: Icons.upcoming_outlined,
                            iconColor: primary,
                            label: 'Remaining after bunk',
                            value: '${bd.remainingAfterBunk} lecs',
                            onSurface: onSurface,
                            onSurfaceVariant: onSurfaceVariant,
                          ),

                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  bd.minPresentNeeded == 0
                                      ? Icons.check_circle_rounded
                                      : bd.isAchievable
                                          ? Icons.info_outline_rounded
                                          : Icons.dangerous_outlined,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bd.minPresentNeeded == 0
                                        ? "You're safe! Well above ${bd.goal.toStringAsFixed(0)}%."
                                        : bd.isAchievable
                                            ? "Attend at least ${bd.minPresentNeeded} of the "
                                              "${bd.remainingAfterBunk} remaining lectures "
                                              "to stay above ${bd.goal.toStringAsFixed(0)}%."
                                            : "Even attending all ${bd.remainingAfterBunk} "
                                              "remaining lectures, you cannot reach "
                                              "${bd.goal.toStringAsFixed(0)}% by semester end.",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: accentColor,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PctTile extends StatelessWidget {
  final String title;
  final double pct;
  final String sub;
  final Color color;
  final Color surface;

  const _PctTile({
    required this.title,
    required this.pct,
    required this.sub,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.6),
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1),
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BdRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _BdRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant))),
          Text(
            value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: onSurface),
          ),
        ],
      ),
    );
  }
}
