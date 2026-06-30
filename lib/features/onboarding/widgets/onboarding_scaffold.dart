import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_colors.dart';
import 'onboarding_progress_bar.dart';

/// Reusable scaffold for all onboarding screens.
/// Applies the Monochrome theme (white background, black CTAs) and
/// hosts the progress bar, back button, optional Skip button, and CTA slot.
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
      backgroundColor: OnboardingColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────
            _TopBar(
              showBack: showBack,
              onBack: onBack ?? () => Navigator.of(context).maybePop(),
              showSkip: showSkip,
              onSkip: onSkip,
              skipLabel: skipLabel,
            ),
            // ── Progress bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OnboardingProgressBar(
                currentStep: stepIndex,
                totalSteps: totalSteps,
              ),
            ),
            const SizedBox(height: 8),
            // ── Body (scrollable) ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: body,
              ),
            ),
            // ── Bottom CTA ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: cta,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.onBack,
    required this.showSkip,
    required this.onSkip,
    required this.skipLabel,
  });

  final bool showBack;
  final VoidCallback onBack;
  final bool showSkip;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: OnboardingColors.primary, size: 22),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          if (showSkip)
            TextButton(
              onPressed: onSkip,
              child: Text(
                skipLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: OnboardingColors.skipBtn,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Primary CTA Button ───────────────────────────────────────────────────────

/// Full-width black CTA button used on all onboarding screens.
class OnboardingCTAButton extends StatelessWidget {
  const OnboardingCTAButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        // Use a no-op when loading so the button keeps primary styling (not
        // the disabled style). Taps are silently swallowed while isLoading.
        onPressed: !enabled ? null : (isLoading ? () {} : onPressed),
        style: ElevatedButton.styleFrom(
          backgroundColor: OnboardingColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OnboardingColors.border,
          disabledForegroundColor: OnboardingColors.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
      ),
    );
  }
}
