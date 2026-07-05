import 'package:flutter/material.dart';
import 'onboarding_colors.dart';

/// Segmented progress bar matching the Stitch Monochrome design.
/// Each step is a short pill — filled (primary) if completed or current,
/// unfilled (surface-container-highest) otherwise.
/// Active segment is slightly wider for visual emphasis.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isCompleted = i < currentStep;
        final isCurrent = i == currentStep;
        final isActive = isCompleted || isCurrent;

        return Expanded(
          flex: isCurrent ? 2 : 1,
          child: Padding(
            padding: EdgeInsets.only(right: i < totalSteps - 1 ? 3 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? OnboardingColors.primary
                    : OnboardingColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}
