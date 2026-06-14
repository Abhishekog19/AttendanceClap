import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Animated circular progress ring matching the Stitch Dashboard hero card
class AttendanceProgressRing extends StatefulWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool showPercentage;
  final Widget? centerChild;

  const AttendanceProgressRing({
    super.key,
    required this.percentage,
    this.size = 96,
    this.strokeWidth = 8,
    this.color,
    this.showPercentage = false,
    this.centerChild,
  });

  @override
  State<AttendanceProgressRing> createState() => _AttendanceProgressRingState();
}

class _AttendanceProgressRingState extends State<AttendanceProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldPercentage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AttendanceProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _oldPercentage = oldWidget.percentage / 100;
      _animation = Tween<double>(
        begin: _oldPercentage,
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

  Color _colorForPercentage(double pct) {
    if (pct >= 85) return AppColors.success;
    if (pct >= 75) return AppColors.primary;
    if (pct >= 65) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.color ?? _colorForPercentage(widget.percentage);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              color: ringColor,
              strokeWidth: widget.strokeWidth,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            child: Center(
              child: widget.centerChild ??
                  (widget.showPercentage
                      ? Text(
                          '${(_animation.value * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.headlineMd.copyWith(
                            color: ringColor,
                          ),
                        )
                      : null),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool isDark;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = isDark
          ? AppColors.darkOutlineVariant
          : AppColors.surfaceContainerHigh
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isDark != isDark;
}
