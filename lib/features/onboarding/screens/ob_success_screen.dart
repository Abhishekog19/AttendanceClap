import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/onboarding_notifier.dart';
import '../widgets/onboarding_colors.dart';

class ObSuccessScreen extends ConsumerStatefulWidget {
  const ObSuccessScreen({super.key});

  @override
  ConsumerState<ObSuccessScreen> createState() => _ObSuccessScreenState();
}

class _ObSuccessScreenState extends ConsumerState<ObSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);

    // Float animation
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      backgroundColor: OnboardingColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // ── Step pill ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: OnboardingColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: OnboardingColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: OnboardingColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Step 9 of 9',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: OnboardingColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Floating hero illustration ─────────────────────────
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: OnboardingColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: OnboardingColors.surfaceContainerHigh,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Large check
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              color: OnboardingColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 56,
                            ),
                          ),
                          // Stars badge
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: OnboardingColors.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: OnboardingColors.surface,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: OnboardingColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Headline ────────────────────────────────────────────
                Text(
                  'Your semester is ready.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: OnboardingColors.onSurface,
                    letterSpacing: -0.28,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Everything is set up. Let's make this your best semester yet.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: OnboardingColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Bento-grid stats ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.menu_book_rounded,
                        value: '${state.subjects.length}',
                        label: 'Subjects Added',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.date_range_rounded,
                        value: '${state.subjects.length * 4}',
                        label: 'Weekly Classes',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Attendance goal wide tile
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: OnboardingColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: OnboardingColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.ads_click_rounded,
                                size: 14,
                                color: OnboardingColors.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Attendance Goal',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: OnboardingColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set for success',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              color: OnboardingColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Circular goal badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: OnboardingColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${state.attendanceGoal.round()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── CTA ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OnboardingColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Tracking',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card (bento grid) ───────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OnboardingColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OnboardingColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: OnboardingColors.onSurface, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: OnboardingColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
