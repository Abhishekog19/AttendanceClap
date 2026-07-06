import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_colors.dart';
import 'onboarding_progress_bar.dart';

/// Reusable scaffold for all onboarding screens.
/// Matches the Stitch Monochrome design:
/// - White/near-white background (#F9F9F9)
/// - Header: [back-button-circle] [linear-progress-bar] [step-label]
/// - Body: scrollable with 20px horizontal padding
/// - Bottom: Fixed black pill CTA button
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.body,
    required this.cta,
    this.ctaLabel = 'Continue',
    this.onCta,
    this.isCtaLoading = false,
    this.isCtaEnabled = true,
    this.showBack = true,
    this.onBack,
    this.showSkip = false,
    this.onSkip,
    this.skipLabel = 'Skip',
    this.title,
  });

  final int stepIndex;
  final int totalSteps;
  final Widget body;
  final Widget cta;
  final String ctaLabel;
  final VoidCallback? onCta;
  final bool isCtaLoading;
  final bool isCtaEnabled;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showSkip;
  final VoidCallback? onSkip;
  final String skipLabel;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: back button + progress bar + step label ──────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
              child: Row(
                children: [
                  if (showBack)
                    _CircleBackButton(onBack: onBack ?? () => Navigator.of(context).maybePop())
                  else
                    const SizedBox(width: 40),
                  const SizedBox(width: 12),
                  // Progress bar
                  Expanded(
                    child: OnboardingProgressBar(
                      currentStep: stepIndex,
                      totalSteps: totalSteps,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Step label or skip
                  if (showSkip)
                    GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        skipLabel,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: OnboardingColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${stepIndex + 1} of $totalSteps',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: OnboardingColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ── Body (scrollable) ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: body,
              ),
            ),
            // ── Bottom CTA ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: cta,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circle Back Button ────────────────────────────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBack,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: OnboardingColors.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: OnboardingColors.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Primary CTA Button ───────────────────────────────────────────────────────

/// Full-width black pill CTA button — matches Stitch design exactly.
/// Font: Plus Jakarta Sans 24px / weight 700 (headline-md)
/// Shape: rounded-full (stadium pill)
/// Trailing icon: arrow_forward
class OnboardingCTAButton extends StatelessWidget {
  const OnboardingCTAButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: ElevatedButton(
          onPressed: !enabled ? null : (isLoading ? () {} : onPressed),
          style: ElevatedButton.styleFrom(
            backgroundColor: OnboardingColors.primary,
            foregroundColor: OnboardingColors.onPrimary,
            disabledBackgroundColor: OnboardingColors.surfaceContainerHighest,
            disabledForegroundColor: OnboardingColors.outline,
            elevation: 4,
            shadowColor: Colors.black26,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: const StadiumBorder(),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? OnboardingColors.onPrimary
                            : OnboardingColors.outline,
                      ),
                    ),
                    if (showArrow) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: enabled
                            ? OnboardingColors.onPrimary
                            : OnboardingColors.outline,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
