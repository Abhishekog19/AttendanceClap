import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

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
    final fmt = DateFormat('d MMM');

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.semester),
      totalSteps: OnboardingStep.all.length,
      onBack: () => context.go(OnboardingStep.routeFor(OnboardingStep.college)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          // ── Title ───────────────────────────────────────────────────
          Text(
            'Set your timeline',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.onSurface,
              height: 1.28,
              letterSpacing: -0.28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define your semester dates and set an attendance goal to stay on track.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: OnboardingColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // ── Semester name ─────────────────────────────────────────────
          _FieldLabel('Semester Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            onChanged: notifier.setSemesterName,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              color: OnboardingColors.onSurface,
            ),
            decoration: _fieldDeco('e.g. Semester 3 / Fall 2025'),
          ),
          const SizedBox(height: 24),

          // ── Date range cards (bento style) ────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DateCard(
                  label: 'START DATE',
                  icon: Icons.flight_takeoff_rounded,
                  value: state.semesterStart != null
                      ? fmt.format(state.semesterStart!)
                      : 'Select',
                  subValue: state.semesterStart != null
                      ? DateFormat('EEEE, yyyy').format(state.semesterStart!)
                      : 'Tap to choose',
                  onTap: () => _pickDate(context, true),
                  isSet: state.semesterStart != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateCard(
                  label: 'END DATE',
                  icon: Icons.flight_land_rounded,
                  value: state.semesterEnd != null
                      ? fmt.format(state.semesterEnd!)
                      : 'Select',
                  subValue: state.semesterEnd != null
                      ? DateFormat('EEEE, yyyy').format(state.semesterEnd!)
                      : 'Tap to choose',
                  onTap: () => _pickDate(context, false),
                  isSet: state.semesterEnd != null,
                ),
              ),
            ],
          ),

          // ── Duration banner ────────────────────────────────────────────
          if (state.semesterStart != null &&
              state.semesterEnd != null &&
              !state.semesterEnd!.isBefore(state.semesterStart!)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: OnboardingColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: OnboardingColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: OnboardingColors.onSurface,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Semester Duration',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: OnboardingColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: OnboardingColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: OnboardingColors.surfaceVariant),
                    ),
                    child: Text(
                      '${state.semesterEnd!.difference(state.semesterStart!).inDays} Days',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OnboardingColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),

          // ── Attendance target section ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: OnboardingColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: OnboardingColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Label
                Row(
                  children: [
                    const Icon(
                      Icons.ads_click_rounded,
                      size: 14,
                      color: OnboardingColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TARGET ATTENDANCE',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: OnboardingColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Large value display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${state.attendanceGoal.round()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: OnboardingColors.onSurface,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: OnboardingColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stepper row
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        if (state.attendanceGoal > 50) {
                          notifier.setAttendanceGoal(state.attendanceGoal - 1);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: OnboardingColors.primary,
                          inactiveTrackColor: OnboardingColors.surfaceVariant,
                          thumbColor: OnboardingColors.surfaceContainerLowest,
                          overlayColor: OnboardingColors.primary.withValues(alpha: 0.08),
                          trackHeight: 6,
                          thumbShape: const _PillThumbShape(),
                        ),
                        child: Slider(
                          value: state.attendanceGoal,
                          min: 50,
                          max: 100,
                          divisions: 50,
                          onChanged: notifier.setAttendanceGoal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        if (state.attendanceGoal < 100) {
                          notifier.setAttendanceGoal(state.attendanceGoal + 1);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Most universities require at least 75% attendance to pass a course.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: OnboardingColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(height: 12),
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
        label: 'Continue Setup',
        isLoading: state.isLoading,
        enabled: state.semesterValid,
        onPressed: () async {
          final ok = await notifier.saveSemester();
          if (ok && context.mounted) {
            final nextStep = ref.read(onboardingNotifierProvider).currentStep;
            context.go(OnboardingStep.routeFor(nextStep));
          }
        },
      ),
    );
  }
}

// ─── Date card (bento style) ──────────────────────────────────────────────────

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.subValue,
    required this.onTap,
    required this.isSet,
  });

  final String label;
  final IconData icon;
  final String value;
  final String subValue;
  final VoidCallback onTap;
  final bool isSet;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OnboardingColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSet
                ? OnboardingColors.outlineVariant
                : OnboardingColors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSet
                        ? OnboardingColors.surfaceContainerHighest
                        : OnboardingColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: OnboardingColors.onSurface),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: OnboardingColors.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isSet
                    ? OnboardingColors.onSurface
                    : OnboardingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subValue,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: OnboardingColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stepper button ────────────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: OnboardingColors.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: OnboardingColors.onSurfaceVariant, size: 22),
      ),
    );
  }
}

// ─── Custom pill-shaped slider thumb ──────────────────────────────────────────

class _PillThumbShape extends SliderComponentShape {
  const _PillThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(32, 32);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required ui.TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer circle (white with border)
    final borderPaint = Paint()
      ..color = OnboardingColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fillPaint = Paint()
      ..color = OnboardingColors.surfaceContainerLowest
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 14, fillPaint);
    canvas.drawCircle(center, 14, borderPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = OnboardingColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, dotPaint);
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _monochromeCalendar(BuildContext ctx, Widget? child) {
  return Theme(
    data: ThemeData(
      colorScheme: const ColorScheme.light(
        primary: OnboardingColors.primary,
        onPrimary: Colors.white,
        surface: OnboardingColors.background,
        onSurface: OnboardingColors.onSurface,
      ),
    ),
    child: child!,
  );
}

InputDecoration _fieldDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        color: OnboardingColors.outline,
      ),
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
    );

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: OnboardingColors.onSurfaceVariant,
          letterSpacing: 0.1,
        ),
      );
}
