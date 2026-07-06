import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

class ObCollegeDetailsScreen extends ConsumerStatefulWidget {
  const ObCollegeDetailsScreen({super.key});

  @override
  ConsumerState<ObCollegeDetailsScreen> createState() =>
      _ObCollegeDetailsScreenState();
}

class _ObCollegeDetailsScreenState
    extends ConsumerState<ObCollegeDetailsScreen> {
  final _collegeCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final s = ref.read(onboardingNotifierProvider);
    _collegeCtrl.text = s.collegeName;
    _courseCtrl.text = s.courseName;
    _yearCtrl.text = s.year;
    _sectionCtrl.text = s.section;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _collegeCtrl.dispose();
    _courseCtrl.dispose();
    _yearCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  void _scheduleAutosave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final repo = ref.read(onboardingRepositoryProvider);
      final s = ref.read(onboardingNotifierProvider);
      if (s.collegeName.isNotEmpty || s.courseName.isNotEmpty) {
        repo.saveCollegeDetails(
          collegeName: s.collegeName,
          courseName: s.courseName,
          year: s.year,
          section: s.section,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.college),
      totalSteps: OnboardingStep.all.length,
      showBack: true,
      onBack: () => context.go(OnboardingStep.routeFor(OnboardingStep.welcome)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          // ── Title ───────────────────────────────────────────────────
          Text(
            'Tell us about\nyour studies',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.onBackground,
              height: 1.28,
              letterSpacing: -0.28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us tailor your schedule and deadlines.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: OnboardingColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // ── College Name ─────────────────────────────────────────────
          _ObFieldLabel('College Name'),
          const SizedBox(height: 8),
          _ObTextField(
            controller: _collegeCtrl,
            hint: 'e.g. IIT Bombay',
            prefixIcon: Icons.account_balance_outlined,
            onChanged: (v) {
              notifier.setCollegeName(v);
              _scheduleAutosave();
            },
          ),
          const SizedBox(height: 24),

          // ── Course ───────────────────────────────────────────────────
          _ObFieldLabel('Course / Programme'),
          const SizedBox(height: 8),
          _ObTextField(
            controller: _courseCtrl,
            hint: 'e.g. B.Tech Computer Science',
            prefixIcon: Icons.school_outlined,
            onChanged: (v) {
              notifier.setCourseName(v);
              _scheduleAutosave();
            },
          ),
          const SizedBox(height: 24),

          // ── Year & Section ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ObFieldLabel('Year'),
                    const SizedBox(height: 8),
                    _ObTextField(
                      controller: _yearCtrl,
                      hint: 'e.g. 2nd',
                      prefixIcon: Icons.calendar_today_outlined,
                      onChanged: (v) {
                        notifier.setYear(v);
                        _scheduleAutosave();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ObFieldLabel('Section'),
                    const SizedBox(height: 8),
                    _ObTextField(
                      controller: _sectionCtrl,
                      hint: 'e.g. A',
                      prefixIcon: Icons.group_outlined,
                      onChanged: (v) {
                        notifier.setSection(v);
                        _scheduleAutosave();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: OnboardingColors.error,
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
      cta: OnboardingCTAButton(
        label: 'Continue',
        isLoading: state.isLoading,
        enabled: state.collegeName.isNotEmpty && state.courseName.isNotEmpty,
        onPressed: () async {
          final ok = await notifier.saveCollegeDetails();
          if (ok && context.mounted) {
            await notifier.navigateNext(context, OnboardingStep.college);
          }
        },
      ),
    );
  }
}

// ─── Shared field label ────────────────────────────────────────────────────────

class _ObFieldLabel extends StatelessWidget {
  const _ObFieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: OnboardingColors.onSurfaceVariant,
          letterSpacing: 0.1,
        ),
      );
}

// ─── Styled text field ────────────────────────────────────────────────────────

class _ObTextField extends StatelessWidget {
  const _ObTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: OnboardingColors.onSurface,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          color: OnboardingColors.outline,
        ),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  prefixIcon,
                  size: 20,
                  color: OnboardingColors.onSurfaceVariant,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: OnboardingColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: OnboardingColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: OnboardingColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: OnboardingColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
