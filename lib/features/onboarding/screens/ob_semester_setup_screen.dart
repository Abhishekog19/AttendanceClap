import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

class ObSemesterSetupScreen extends ConsumerStatefulWidget {
  const ObSemesterSetupScreen({super.key});

  @override
  ConsumerState<ObSemesterSetupScreen> createState() =>
      _ObSemesterSetupScreenState();
}

class _ObSemesterSetupScreenState
    extends ConsumerState<ObSemesterSetupScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = ref.read(onboardingNotifierProvider);
    _nameCtrl.text = s.semesterName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final state = ref.read(onboardingNotifierProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (state.semesterStart ?? now)
          : (state.semesterEnd ?? now.add(const Duration(days: 120))),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => _monochromeCalendar(ctx, child),
    );
    if (picked != null) {
      if (isStart) {
        notifier.setSemesterStart(picked);
      } else {
        notifier.setSemesterEnd(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final fmt = DateFormat('dd MMM yyyy');

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.semester),
      totalSteps: OnboardingStep.all.length,
      onBack: () => context.go(OnboardingStep.routeFor(OnboardingStep.college)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Set up your\nsemester',
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
            'We use your semester dates to calculate exactly how many classes you have and can safely miss.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          // ── Semester name ─────────────────────────────────────────
          _Label('Semester Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            onChanged: notifier.setSemesterName,
            style: GoogleFonts.inter(fontSize: 15, color: OnboardingColors.textPrimary),
            decoration: _fieldDeco('e.g. Semester 3 / Fall 2025'),
          ),
          const SizedBox(height: 24),
          // ── Date range ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Start Date',
                  value: state.semesterStart != null
                      ? fmt.format(state.semesterStart!)
                      : 'Select',
                  onTap: () => _pickDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTile(
                  label: 'End Date',
                  value: state.semesterEnd != null
                      ? fmt.format(state.semesterEnd!)
                      : 'Select',
                  onTap: () => _pickDate(context, false),
                ),
              ),
            ],
          ),
          if (state.semesterStart != null && state.semesterEnd != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: OnboardingColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 16, color: OnboardingColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${state.semesterEnd!.difference(state.semesterStart!).inDays ~/ 7} weeks · ${state.semesterEnd!.difference(state.semesterStart!).inDays} days',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: OnboardingColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          // ── Attendance goal ───────────────────────────────────────
          _Label('Global Attendance Target'),
          const SizedBox(height: 4),
          Text(
            'Minimum attendance percentage required across all subjects',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: OnboardingColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: OnboardingColors.primary,
                    inactiveTrackColor: OnboardingColors.progressBg,
                    thumbColor: OnboardingColors.primary,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: state.attendanceGoal,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    onChanged: notifier.setAttendanceGoal,
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 36,
                decoration: BoxDecoration(
                  color: OnboardingColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${state.attendanceGoal.round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!,
                style: GoogleFonts.inter(
                    fontSize: 13, color: OnboardingColors.error)),
          ],
          const SizedBox(height: 32),
        ],
      ),
      cta: OnboardingCTAButton(
        label: 'Continue',
        isLoading: state.isLoading,
        enabled: state.semesterValid,
        onPressed: () async {
          final ok = await notifier.saveSemester();
          if (ok && context.mounted) {
            context.go(OnboardingStep.routeFor(OnboardingStep.subjects));
          }
        },
      ),
    );
  }
}

Widget _monochromeCalendar(BuildContext ctx, Widget? child) {
  return Theme(
    data: ThemeData(
      colorScheme: const ColorScheme.light(
        primary: OnboardingColors.primary,
        onPrimary: Colors.white,
        surface: OnboardingColors.bg,
        onSurface: OnboardingColors.textPrimary,
      ),
    ),
    child: child!,
  );
}

InputDecoration _fieldDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 15, color: OnboardingColors.textHint),
      filled: true,
      fillColor: OnboardingColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: OnboardingColors.borderFocus, width: 1.5),
      ),
    );

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: OnboardingColors.textPrimary,
        ),
      );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final hasValue = value != 'Select';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OnboardingColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OnboardingColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: OnboardingColors.textHint,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14,
                    color: hasValue
                        ? OnboardingColors.textPrimary
                        : OnboardingColors.textHint),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasValue
                        ? OnboardingColors.textPrimary
                        : OnboardingColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
