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
    _collegeCtrl.dispose();
    _courseCtrl.dispose();
    _yearCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
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
          const SizedBox(height: 32),
          Text(
            'Tell us about\nyour college',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalise your experience and generate the right academic calendar.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          _ObField(
            label: 'College / University',
            hint: 'e.g. IIT Bombay',
            controller: _collegeCtrl,
            onChanged: notifier.setCollegeName,
          ),
          const SizedBox(height: 20),
          _ObField(
            label: 'Course / Programme',
            hint: 'e.g. B.Tech Computer Science',
            controller: _courseCtrl,
            onChanged: notifier.setCourseName,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ObField(
                  label: 'Year',
                  hint: 'e.g. 2nd Year',
                  controller: _yearCtrl,
                  onChanged: notifier.setYear,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ObField(
                  label: 'Section',
                  hint: 'e.g. A',
                  controller: _sectionCtrl,
                  onChanged: notifier.setSection,
                ),
              ),
            ],
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: GoogleFonts.inter(
                  fontSize: 13, color: OnboardingColors.error),
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
            context.go(OnboardingStep.routeFor(OnboardingStep.semester));
          }
        },
      ),
    );
  }
}

// ─── Reusable monochrome text field ──────────────────────────────────────────

class _ObField extends StatelessWidget {
  const _ObField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: OnboardingColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: OnboardingColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: OnboardingColors.textHint,
            ),
            filled: true,
            fillColor: OnboardingColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OnboardingColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OnboardingColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: OnboardingColors.borderFocus, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
