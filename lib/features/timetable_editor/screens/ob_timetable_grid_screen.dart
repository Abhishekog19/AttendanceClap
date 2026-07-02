/// Onboarding Timetable Grid Screen
///
/// Wraps TimetableGrid in an onboarding-consistent shell:
///   • Same white background as other onboarding screens
///   • Top bar with back button + Skip
///   • Progress bar (step 4 of 8)
///   • TimetableGrid fills all remaining space (no horizontal padding,
///     no outer scroll — the grid manages its own scroll internally)
///   • "Done" CTA at bottom drives onboarding navigation
///
/// Subjects come from the canonical subjectsStreamProvider — no seeding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/onboarding/providers/onboarding_notifier.dart';
import '../../../features/onboarding/providers/onboarding_state.dart';
import '../../../features/onboarding/widgets/onboarding_colors.dart';
import '../../../features/onboarding/widgets/onboarding_progress_bar.dart';
import '../widgets/timetable_grid.dart';

class ObTimetableGridScreen extends ConsumerWidget {
  const ObTimetableGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final stepIndex = OnboardingStep.indexOf(OnboardingStep.timetable);
    final totalSteps = OnboardingStep.all.length;

    return Scaffold(
      backgroundColor: OnboardingColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar (matches OnboardingScaffold style) ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: OnboardingColors.primary),
                    onPressed: () => notifier.navigateBack(
                        context, OnboardingStep.subjects),
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                  // Skip button
                  TextButton(
                    onPressed: () async {
                      await notifier.skipTimetable();
                      if (context.mounted) {
                        notifier.navigateNext(
                            context, OnboardingStep.timetable);
                      }
                    },
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: OnboardingColors.skipBtn,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OnboardingProgressBar(
                currentStep: stepIndex,
                totalSteps: totalSteps,
              ),
            ),
            const SizedBox(height: 8),

            // ── Heading ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Text(
                'Build your timetable',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: OnboardingColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Select a subject below, then tap a slot to place it.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: OnboardingColors.textSecondary,
                ),
              ),
            ),

            // ── Timetable grid (takes all remaining space) ───────────────
            const Expanded(
              child: TimetableGrid(
                mode: TimetableGridMode.onboarding,
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await notifier.completeTimetable();
                          if (context.mounted) {
                            notifier.navigateNext(
                                context, OnboardingStep.timetable);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnboardingColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: OnboardingColors.border,
                    disabledForegroundColor: OnboardingColors.textHint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Finish Setup',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
