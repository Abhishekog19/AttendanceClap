/// Period Timing Setup Screen
///
/// Onboarding Screen 2: inserted between Subjects and the Timetable Grid.
/// Lets the user configure when their periods start and how long they are,
/// before entering the grid. Essentially the PeriodTimingSheet content in a
/// full-screen scrollable form within the OnboardingScaffold chrome.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/onboarding/providers/onboarding_state.dart';
import '../../../features/onboarding/widgets/onboarding_colors.dart';
import '../../../features/onboarding/widgets/onboarding_scaffold.dart';
import '../providers/timetable_editor_notifier.dart';

import '../models/timetable_editor_models.dart';

class PeriodTimingSetupScreen extends ConsumerStatefulWidget {
  const PeriodTimingSetupScreen({super.key});

  @override
  ConsumerState<PeriodTimingSetupScreen> createState() =>
      _PeriodTimingSetupScreenState();
}

class _PeriodTimingSetupScreenState
    extends ConsumerState<PeriodTimingSetupScreen> {
  // ── Same Every Day state ──────────────────────────────────────────────────
  TimeOfDay _firstStart = const TimeOfDay(hour: 9, minute: 0);
  int _lectureDuration = 50;
  int _breakDuration = 10;
  int _periodCount = 6;
  bool _addLunch = false;
  int _lunchAfterPeriod = 3;
  int _lunchDuration = 40;

  List<PeriodSlot> get _generatedPeriods {
    return _PeriodGenerator.generate(
      firstStart: _firstStart,
      lectureDuration: _lectureDuration,
      breakDuration: _breakDuration,
      periodCount: _periodCount,
      addLunch: _addLunch,
      lunchAfterPeriod: _lunchAfterPeriod,
      lunchDuration: _lunchDuration,
    );
  }

  Future<void> _saveAndContinue() async {
    final slots = _generatedPeriods;
    await ref
        .read(timetableEditorNotifierProvider.notifier)
        .updateDefaultSchedule(slots);
    if (mounted) {
      context.go(OnboardingStep.routeFor(OnboardingStep.timetable));
    }
  }

  @override
  Widget build(BuildContext context) {
    final periods = _generatedPeriods;

    return OnboardingScaffold(
      stepIndex:
          OnboardingStep.indexOf(OnboardingStep.periodTiming),
      totalSteps: OnboardingStep.all.length,
      onBack: () =>
          context.go(OnboardingStep.routeFor(OnboardingStep.subjects)),
      showSkip: true,
      onSkip: () =>
          context.go(OnboardingStep.routeFor(OnboardingStep.timetable)),
      skipLabel: 'Skip',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Set your period\ntimings',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us when your classes start and how long each one is. You can change this later.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // ── First class start ──────────────────────────────────────────
          _Label('First class starts at'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _firstStart,
              );
              if (t != null) setState(() => _firstStart = t);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: OnboardingColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OnboardingColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: OnboardingColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_firstStart.hour.toString().padLeft(2, '0')}:${_firstStart.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: OnboardingColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Lecture duration ───────────────────────────────────────────
          _StepperRow(
            label: 'Lecture duration',
            value: _lectureDuration,
            unit: 'min',
            min: 20,
            max: 180,
            step: 5,
            onChanged: (v) => setState(() => _lectureDuration = v),
          ),
          const SizedBox(height: 16),
          _StepperRow(
            label: 'Break between lectures',
            value: _breakDuration,
            unit: 'min',
            min: 0,
            max: 60,
            step: 5,
            onChanged: (v) => setState(() => _breakDuration = v),
          ),
          const SizedBox(height: 16),
          _StepperRow(
            label: 'Number of periods',
            value: _periodCount,
            unit: 'periods',
            min: 1,
            max: 12,
            step: 1,
            onChanged: (v) => setState(() => _periodCount = v),
          ),
          const SizedBox(height: 20),
          // ── Lunch toggle ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text('Add lunch break',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OnboardingColors.textPrimary,
                    )),
              ),
              Switch(
                value: _addLunch,
                onChanged: (v) => setState(() => _addLunch = v),
                activeThumbColor: OnboardingColors.primary,
              ),
            ],
          ),
          if (_addLunch) ...[
            const SizedBox(height: 12),
            _StepperRow(
              label: 'After period',
              value: _lunchAfterPeriod,
              unit: '',
              min: 1,
              max: _periodCount,
              step: 1,
              onChanged: (v) => setState(() => _lunchAfterPeriod = v),
            ),
            const SizedBox(height: 12),
            _StepperRow(
              label: 'Lunch duration',
              value: _lunchDuration,
              unit: 'min',
              min: 10,
              max: 90,
              step: 5,
              onChanged: (v) => setState(() => _lunchDuration = v),
            ),
          ],
          const SizedBox(height: 24),
          // ── Preview ────────────────────────────────────────────────────
          Text('Preview',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: OnboardingColors.textSecondary,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 8),
          ...periods.map((p) => _PeriodRow(slot: p)),
          const SizedBox(height: 32),
        ],
      ),
      cta: OnboardingCTAButton(
        label: 'Continue',
        onPressed: _saveAndContinue,
      ),
    );
  }
}

// ─── Period Generator (shared with PeriodTimingSheet) ────────────────────────

class _PeriodGenerator {
  static List<PeriodSlot> generate({
    required TimeOfDay firstStart,
    required int lectureDuration,
    required int breakDuration,
    required int periodCount,
    required bool addLunch,
    required int lunchAfterPeriod,
    required int lunchDuration,
  }) {
    final slots = <PeriodSlot>[];
    int current = firstStart.hour * 60 + firstStart.minute;
    int lectureNum = 1;

    for (int i = 0; i < periodCount; i++) {
      if (addLunch && i == lunchAfterPeriod) {
        final lunchStart = _fmt(current);
        current += lunchDuration;
        slots.add(PeriodSlot(
          id: 'lunch_setup',
          label: 'Lunch',
          startTime: lunchStart,
          endTime: _fmt(current),
          type: PeriodType.lunch,
        ));
        current += breakDuration;
      }

      final start = _fmt(current);
      current += lectureDuration;
      slots.add(PeriodSlot(
        id: 'p$lectureNum',
        label: 'Period $lectureNum',
        startTime: start,
        endTime: _fmt(current),
        type: PeriodType.lecture,
      ));
      lectureNum++;

      if (i < periodCount - 1 &&
          !(addLunch && i + 1 == lunchAfterPeriod)) {
        final bStart = _fmt(current);
        current += breakDuration;
        slots.add(PeriodSlot(
          id: 'break_$i',
          label: 'Break',
          startTime: bStart,
          endTime: _fmt(current),
          type: PeriodType.breakPeriod,
        ));
      }
    }
    return slots;
  }

  static String _fmt(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

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

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OnboardingColors.textPrimary,
                    )),
                if (unit.isNotEmpty)
                  Text('$value $unit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OnboardingColors.textSecondary,
                      )),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: OnboardingColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: value <= min
                        ? OnboardingColors.textHint
                        : OnboardingColors.primary,
                  ),
                  onPressed: value <= min ? null : () => onChanged(value - step),
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: OnboardingColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: value >= max
                        ? OnboardingColors.textHint
                        : OnboardingColors.primary,
                  ),
                  onPressed: value >= max ? null : () => onChanged(value + step),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      );
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.slot});
  final PeriodSlot slot;

  @override
  Widget build(BuildContext context) {
    final isBreak = slot.type != PeriodType.lecture;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isBreak
            ? OnboardingColors.surface
            : OnboardingColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBreak
              ? OnboardingColors.border
              : OnboardingColors.borderFocus.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(slot.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isBreak
                      ? OnboardingColors.textSecondary
                      : OnboardingColors.textPrimary,
                )),
          ),
          Text('${slot.startTime} – ${slot.endTime}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isBreak
                    ? OnboardingColors.textHint
                    : OnboardingColors.textSecondary,
              )),
        ],
      ),
    );
  }
}
