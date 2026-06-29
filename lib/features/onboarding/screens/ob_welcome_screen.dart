import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/auth_repository.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

class ObWelcomeScreen extends ConsumerWidget {
  const ObWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: OnboardingColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              // ── Hero illustration ─────────────────────────────────────
              const Center(child: _HeroIllustration()),
              const SizedBox(height: 48),
              // ── Headline ──────────────────────────────────────────────
              Text(
                'Track smarter,\nnot harder.',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: OnboardingColors.textPrimary,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AttendanceAI keeps your attendance on track so you never miss a lecture that matters — and never skip one you can\'t afford to miss.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: OnboardingColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              // ── Feature pills ────────────────────────────────────────
              const _FeaturePills(),
              const Spacer(),
              // ── Primary CTA ───────────────────────────────────────────
              OnboardingCTAButton(
                label: 'Get Started',
                // Navigate directly — no Firestore write needed on welcome.
                // The step key is saved when the user advances from College Details.
                onPressed: () =>
                    context.go(OnboardingStep.routeFor(OnboardingStep.college)),
              ),
              const SizedBox(height: 12),
              // ── Sign Out ──────────────────────────────────────────────
              // User is always logged in at this point (router gate ensures it).
              // Offer Sign Out in case they want to switch accounts.
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    // Router will redirect to /auth/login automatically
                    // via authStateChanges listener.
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OnboardingColors.textSecondary,
                    side: const BorderSide(color: OnboardingColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: const BoxDecoration(
        color: OnboardingColors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: OnboardingColors.border, width: 2),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: OnboardingColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 48),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: OnboardingColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('75%',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePills extends StatelessWidget {
  const _FeaturePills();

  static const _features = [
    (Icons.calendar_today_rounded, 'Timetable Builder'),
    (Icons.trending_up_rounded, 'Smart Predictions'),
    (Icons.beach_access_rounded, 'Leave Planner'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _features.map((f) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: OnboardingColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: OnboardingColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$1, size: 15, color: OnboardingColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                f.$2,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: OnboardingColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
