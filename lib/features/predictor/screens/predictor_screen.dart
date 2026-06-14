import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/predictor_provider.dart';

class PredictorScreen extends ConsumerWidget {
  const PredictorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(predictorNotifierProvider);
    final notifier = ref.read(predictorNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg.withAlpha(230),
        title: Text('AttendanceAI',
            style: AppTextStyles.headlineMd.copyWith(color: primary)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Predict Your Attendance',
                style: AppTextStyles.headlineLg.copyWith(color: onSurface)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Simulate future scenarios and stay on track with your goals.',
              style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),

            // On mobile: stack vertically; on wider: side by side
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _SimulationTool(state: state, notifier: notifier, isDark: isDark)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 7, child: _PredictedOutcome(state: state, isDark: isDark)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _SimulationTool(state: state, notifier: notifier, isDark: isDark),
                    const SizedBox(height: AppSpacing.md),
                    _PredictedOutcome(state: state, isDark: isDark),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ImpactSummary(state: state, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _SimulationTool extends StatelessWidget {
  final PredictorState state;
  final PredictorNotifier notifier;
  final bool isDark;

  const _SimulationTool({required this.state, required this.notifier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Simulation Tool',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
          const SizedBox(height: AppSpacing.lg),

          // Attended stepper
          Text(
            'FUTURE CLASSES ATTENDED',
            style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Stepper(
            value: state.futureAttended,
            onDecrement: notifier.decrementAttended,
            onIncrement: notifier.incrementAttended,
            incrementColor: primary,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Missed stepper
          Text(
            'FUTURE CLASSES MISSED',
            style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Stepper(
            value: state.futureMissed,
            onDecrement: notifier.decrementMissed,
            onIncrement: notifier.incrementMissed,
            incrementColor: AppColors.tertiary,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),

          TextButton.icon(
            onPressed: notifier.reset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset Simulation'),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color incrementColor;
  final bool isDark;

  const _Stepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.incrementColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final container = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainer;
    final highest = isDark ? const Color(0xFF3A3D4A) : AppColors.surfaceContainerHighest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: highest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(Icons.remove, color: onSurface),
            ),
          ),
          Text('$value', style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: incrementColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictedOutcome extends StatelessWidget {
  final PredictorState state;
  final bool isDark;

  const _PredictedOutcome({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final (percentageColor, chipBg, chipFg, chipIcon, chipLabel) = switch (state.status) {
      PredictorStatus.safe => (
          primary, isDark ? AppColors.darkPrimaryContainer.withAlpha(80) : AppColors.primaryFixed,
          primary, Icons.check_circle_outline, 'Safe'
        ),
      PredictorStatus.caution => (
          AppColors.warning, AppColors.warningContainer,
          AppColors.onWarningContainer, Icons.warning_outlined, 'Caution'
        ),
      PredictorStatus.danger => (
          AppColors.error, AppColors.errorContainer,
          AppColors.onErrorContainer, Icons.report_outlined, 'Danger'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Predicted Outcome',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
          const SizedBox(height: AppSpacing.lg),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AnimatedPredictedPct(
                  percentage: state.predictedPercentage, color: percentageColor),
              const SizedBox(width: AppSpacing.md),
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chipIcon, size: 14, color: chipFg),
                    const SizedBox(width: 4),
                    Text(chipLabel,
                        style: AppTextStyles.labelMd.copyWith(color: chipFg)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Estimated Total Attendance',
              style: AppTextStyles.labelMd.copyWith(color: onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Safe Bunks Left',
                  value: '${state.safeBunks}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatBox(
                  label: 'Risk Level',
                  value: state.riskLevel,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Trend SVG chart
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              height: 80,
              child: CustomPaint(
                painter: _TrendChartPainter(
                  netChange: state.futureAttended - state.futureMissed,
                  color: percentageColor,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPredictedPct extends StatefulWidget {
  final double percentage;
  final Color color;

  const _AnimatedPredictedPct({required this.percentage, required this.color});

  @override
  State<_AnimatedPredictedPct> createState() => _AnimatedPredictedPctState();
}

class _AnimatedPredictedPctState extends State<_AnimatedPredictedPct>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _anim = Tween<double>(begin: widget.percentage, end: widget.percentage).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_AnimatedPredictedPct old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _anim = Tween<double>(begin: old.percentage, end: widget.percentage).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Text(
          '${_anim.value.toStringAsFixed(1)}%',
          style: AppTextStyles.displayLg.copyWith(color: widget.color),
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatBox({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelMd.copyWith(color: onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final int netChange;
  final Color color;
  final bool isDark;

  _TrendChartPainter({required this.netChange, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      Paint()..color = bg,
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final yOffset = (size.height * 0.6) - (netChange * 2).clamp(-20.0, 20.0);
    final midY = (size.height * 0.75) - (netChange * 1).clamp(-15.0, 15.0);

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, midY, size.width, yOffset);

    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width, yOffset), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrendChartPainter old) =>
      old.netChange != netChange || old.color != color;
}

class _ImpactSummary extends StatelessWidget {
  final PredictorState state;
  final bool isDark;

  const _ImpactSummary({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? Colors.white.withAlpha(13) : Colors.white;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Impact Summary',
                  style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.onSecondaryFixedVariant : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'Next 14 Days',
                  style: AppTextStyles.labelMd.copyWith(
                    color: isDark ? AppColors.secondaryFixed : AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _InsightItem(
            icon: Icons.trending_up,
            iconBg: isDark ? AppColors.darkPrimaryContainer.withAlpha(80) : AppColors.primaryFixed,
            iconColor: primary,
            title: 'Attendance Growth',
            subtitle: 'Your current strategy increases overall score over 2 weeks.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightItem(
            icon: Icons.warning_outlined,
            iconBg: AppColors.warningContainer,
            iconColor: AppColors.warning,
            title: 'Buffer Zone',
            subtitle: 'Missing 2 more classes will drop you below the ${state.goal.toStringAsFixed(0)}% threshold.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightItem(
            icon: Icons.event_available_outlined,
            iconBg: isDark ? AppColors.onSecondaryFixedVariant : AppColors.secondaryContainer,
            iconColor: isDark ? AppColors.secondaryFixed : AppColors.secondary,
            title: 'Consistency Rank',
            subtitle: 'Maintaining this attendance leads to high credit awards.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;

  const _InsightItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.labelMd.copyWith(
                    color: onSurface, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
