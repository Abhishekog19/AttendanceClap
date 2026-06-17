import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/risk_level.dart';
import '../models/subject_prediction.dart';

/// Per-subject prediction card — premium redesign.
/// Shows circular arc, risk badge, safe bunks, and projected %.
/// Tap opens the What-If simulator.
class SubjectPredictionCard extends StatefulWidget {
  final SubjectPrediction prediction;
  final VoidCallback onTap;

  const SubjectPredictionCard(
      {super.key, required this.prediction, required this.onTap});

  @override
  State<SubjectPredictionCard> createState() =>
      _SubjectPredictionCardState();
}

class _SubjectPredictionCardState extends State<SubjectPredictionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));
    _progress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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

    final risk = widget.prediction.riskLevel;
    final pct = widget.prediction.currentPct;
    final proj = widget.prediction.projectedPct;
    final isBelow = risk == RiskLevel.critical;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBelow
                ? risk.color.withValues(alpha: 0.35)
                : border.withValues(alpha: 0.5),
            width: isBelow ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top section ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arc dial
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => _MiniArcDial(
                      percentage: pct,
                      animProgress: _progress.value,
                      risk: risk,
                      size: 64,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Subject info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.prediction.name,
                                style: AppTextStyles.bodyLg.copyWith(
                                    color: onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Risk chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: risk.containerColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                        color: risk.color,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    risk.label,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: risk.onContainerColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (widget.prediction.faculty != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 11,
                                  color:
                                      onSurfaceVariant.withValues(alpha: 0.7)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  widget.prediction.faculty!,
                                  style: AppTextStyles.labelMd.copyWith(
                                      color: onSurfaceVariant.withValues(
                                          alpha: 0.7),
                                      fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: AppSpacing.sm),

                        // Stats — Wrap prevents overflow
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _InlineStatPill(
                              label: 'Bunks',
                              value: '${widget.prediction.safeBunks}',
                              isDark: isDark,
                              color: widget.prediction.safeBunks > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            _InlineStatPill(
                              label: 'Proj.',
                              value:
                                  '${proj.toStringAsFixed(1)}%',
                              isDark: isDark,
                              color: proj >= widget.prediction.goal
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            _InlineStatPill(
                              label: 'Left',
                              value:
                                  '${widget.prediction.remainingClasses}',
                              isDark: isDark,
                              color: onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Recovery banner (only when below goal) ───────────────────
            if (widget.prediction.classesNeeded > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.healing_outlined,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Need ${widget.prediction.classesNeeded} more consecutive classes to reach '
                        '${widget.prediction.goal.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Bottom tap hint ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.025),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined,
                      size: 12,
                      color: onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(width: 5),
                  Text(
                    'Tap to simulate bunks',
                    style: TextStyle(
                        fontSize: 11,
                        color: onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500),
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

// ─── Mini arc dial ────────────────────────────────────────────────────────────

class _MiniArcDial extends StatelessWidget {
  final double percentage;
  final double animProgress;
  final RiskLevel risk;
  final double size;

  const _MiniArcDial({
    required this.percentage,
    required this.animProgress,
    required this.risk,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (animProgress * percentage / 100).clamp(0.0, 1.0),
            strokeWidth: 6,
            backgroundColor: risk.color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(risk.color),
            strokeCap: StrokeCap.round,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(animProgress * percentage).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: risk.color,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Inline stat pill ─────────────────────────────────────────────────────────

class _InlineStatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color color;

  const _InlineStatPill({
    required this.label,
    required this.value,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}
