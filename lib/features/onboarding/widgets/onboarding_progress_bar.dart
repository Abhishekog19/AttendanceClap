import 'package:flutter/material.dart';
import 'onboarding_colors.dart';

/// Segmented step-progress indicator matching the Stitch Monochrome design.
/// Filled segments for completed steps, animated partial fill for current step.
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
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 4,
              decoration: BoxDecoration(
                color: (isCompleted || isCurrent)
                    ? OnboardingColors.progressFill
                    : OnboardingColors.progressBg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
