import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/attendance_calculator.dart';

/// Animated horizontal progress bar with color-coded status
class SubjectProgressBar extends StatefulWidget {
  final double percentage;
  final double targetPercent;
  final double height;

  const SubjectProgressBar({
    super.key,
    required this.percentage,
    this.targetPercent = 75.0,
    this.height = 8,
  });

  @override
  State<SubjectProgressBar> createState() => _SubjectProgressBarState();
}

class _SubjectProgressBarState extends State<SubjectProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _widthAnim = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(SubjectProgressBar old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _widthAnim = Tween<double>(
        begin: _widthAnim.value, // animate from current position, not 0
        end: widget.percentage / 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    final status = AttendanceCalculator.getStatus(
      widget.percentage,
      target: widget.targetPercent,
    );
    switch (status) {
      case AttendanceStatus.excellent:
      case AttendanceStatus.good:
      case AttendanceStatus.safe:
        return AppColors.primary;
      case AttendanceStatus.risky:
        return AppColors.warning;
      case AttendanceStatus.critical:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = _getColor();

    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerHigh
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(widget.height),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * _widthAnim.value,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(widget.height),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Status chip (Safe / Watch / Critical)
class StatusChip extends StatelessWidget {
  final AttendanceStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTextStyles.labelMd.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _colors(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.excellent:
      case AttendanceStatus.good:
      case AttendanceStatus.safe:
        return (
          AppColors.successContainer,
          AppColors.onSuccessContainer,
          AppColors.success,
        );
      case AttendanceStatus.risky:
        return (
          AppColors.warningContainer,
          AppColors.onWarningContainer,
          AppColors.warning,
        );
      case AttendanceStatus.critical:
        return (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          AppColors.error,
        );
    }
  }
}
