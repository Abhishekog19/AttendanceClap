import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../services/predictor_service.dart';

/// Hero card — animated arc gauge + 4 stat tiles.
class OverallSummaryCard extends StatefulWidget {
  final PredictorData data;
  const OverallSummaryCard({super.key, required this.data});

  @override
  State<OverallSummaryCard> createState() => _OverallSummaryCardState();
}

class _OverallSummaryCardState extends State<OverallSummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progress = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = widget.data.overallCurrentPct;
    final proj = widget.data.overallProjectedPct;
    final isHealthy = pct >= widget.data.goal;

    final List<Color> gradColors = isDark
        ? [const Color(0xFF1A1F35), const Color(0xFF0D1220)]
        : isHealthy
            ? [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)]
            : [const Color(0xFF991B1B), const Color(0xFFDC2626)];

    final accentColor = isHealthy ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: (isHealthy ? AppColors.primary : AppColors.error)
                .withValues(alpha: isDark ? 0.2 : 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top badge row ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Text(
                              'SEMESTER OVERVIEW',
                              style: AppTextStyles.labelCaps.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.25),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Goal ${widget.data.goal.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Gauge + info ─────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Arc gauge
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) => CustomPaint(
                        size: const Size(100, 100),
                        painter: _ArcGaugePainter(
                          progress: _progress.value * (pct / 100),
                          goal: widget.data.goal / 100,
                          isHealthy: isHealthy,
                        ),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _progress,
                                  builder: (_, __) => Text(
                                    '${(_progress.value * pct).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Overall',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Info text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHealthy ? 'Looking good!' : 'Needs attention',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SmallStat(
                            icon: Icons.trending_up_rounded,
                            label: 'Projected',
                            value: '${proj.toStringAsFixed(1)}%',
                            color: proj >= widget.data.goal
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFCA5A5),
                          ),
                          const SizedBox(height: 4),
                          _SmallStat(
                            icon: Icons.event_busy_outlined,
                            label: 'Safe bunks',
                            value: '${widget.data.totalSafeBunks}',
                            color: widget.data.totalSafeBunks > 0
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFCA5A5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── 4 stat tiles ─────────────────────────────────────────
                Row(
                  children: [
                    _Tile(
                      value: '${pct.toStringAsFixed(1)}%',
                      label: 'Current',
                      icon: Icons.bar_chart_rounded,
                    ),
                    _VDivider(),
                    _Tile(
                      value: '${proj.toStringAsFixed(1)}%',
                      label: 'Projected',
                      icon: Icons.flag_outlined,
                    ),
                    _VDivider(),
                    _Tile(
                      value: '${widget.data.totalSafeBunks}',
                      label: 'Bunks',
                      icon: Icons.weekend_outlined,
                      isAlert: widget.data.totalSafeBunks == 0,
                    ),
                    _VDivider(),
                    _Tile(
                      value: '${widget.data.criticalCount}',
                      label: 'Critical',
                      icon: Icons.warning_amber_rounded,
                      isAlert: widget.data.criticalCount > 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SmallStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        color: Colors.white.withValues(alpha: 0.12));
  }
}

class _Tile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isAlert;
  const _Tile(
      {required this.value,
      required this.label,
      required this.icon,
      this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    final color = isAlert
        ? const Color(0xFFFCA5A5)
        : Colors.white.withValues(alpha: 0.9);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.75)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

/// Animated arc gauge painter (270° sweep).
class _ArcGaugePainter extends CustomPainter {
  final double progress;
  final double goal;
  final bool isHealthy;

  const _ArcGaugePainter(
      {required this.progress, required this.goal, required this.isHealthy});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 10;

    const startAngle = math.pi * 0.75;
    const sweepMax = math.pi * 1.5;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepMax,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Goal marker
    final goalAngle = startAngle + sweepMax * goal;
    canvas.drawCircle(
      Offset(cx + radius * math.cos(goalAngle),
          cy + radius * math.sin(goalAngle)),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Progress arc
    if (progress > 0) {
      final paint = Paint()
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      paint.shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepMax * progress,
        colors: isHealthy
            ? [const Color(0xFF34D399), const Color(0xFF6EE7B7)]
            : [const Color(0xFFF87171), const Color(0xFFFCA5A5)],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepMax * progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.progress != progress;
}
