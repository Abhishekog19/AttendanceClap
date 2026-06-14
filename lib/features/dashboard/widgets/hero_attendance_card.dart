import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../shared/widgets/attendance_progress_ring.dart';
import '../../../shared/widgets/subject_progress_bar.dart';

class HeroAttendanceCard extends StatelessWidget {
  final double overallPercentage;
  final int safeBunks;
  final int classesNeeded;
  final double targetPercent;

  const HeroAttendanceCard({
    super.key,
    required this.overallPercentage,
    required this.safeBunks,
    required this.classesNeeded,
    required this.targetPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = AttendanceCalculator.getStatus(overallPercentage, target: targetPercent);
    final cardBg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL STATUS',
                      style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _AnimatedPercentageText(percentage: overallPercentage, isDark: isDark),
                    const SizedBox(height: AppSpacing.sm),
                    StatusChip(status: status),
                  ],
                ),
              ),
              // Right: animated ring
              AttendanceProgressRing(
                percentage: overallPercentage,
                size: 96,
                strokeWidth: 9,
                centerChild: Icon(
                  Icons.verified_rounded,
                  color: _ringColor(status, isDark),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Buffer',
                  value: '$safeBunks Bunks Left',
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: borderColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: _StatItem(
                    label: 'Target (${targetPercent.toStringAsFixed(0)}%)',
                    value: classesNeeded > 0
                        ? '$classesNeeded Classes To Go'
                        : 'Target Met ✓',
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _ringColor(AttendanceStatus status, bool isDark) {
    switch (status) {
      case AttendanceStatus.excellent:
      case AttendanceStatus.good:
      case AttendanceStatus.safe:
        return isDark ? AppColors.darkPrimary : AppColors.primary;
      case AttendanceStatus.risky:
        return AppColors.warning;
      case AttendanceStatus.critical:
        return AppColors.error;
    }
  }
}

class _AnimatedPercentageText extends StatefulWidget {
  final double percentage;
  final bool isDark;

  const _AnimatedPercentageText({required this.percentage, required this.isDark});

  @override
  State<_AnimatedPercentageText> createState() => _AnimatedPercentageTextState();
}

class _AnimatedPercentageTextState extends State<_AnimatedPercentageText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = Tween<double>(begin: 0, end: widget.percentage).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedPercentageText old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _anim = Tween<double>(begin: old.percentage, end: widget.percentage).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        '${_anim.value.toStringAsFixed(1)}%',
        style: AppTextStyles.displayLg.copyWith(
          color: widget.isDark ? AppColors.darkOnSurface : AppColors.onSurface,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _StatItem({
    required this.label,
    required this.value,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd.copyWith(color: onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
      ],
    );
  }
}
