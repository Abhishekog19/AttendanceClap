import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

class ObAttendanceImportScreen extends ConsumerStatefulWidget {
  const ObAttendanceImportScreen({super.key});

  @override
  ConsumerState<ObAttendanceImportScreen> createState() =>
      _ObAttendanceImportScreenState();
}

class _ObAttendanceImportScreenState
    extends ConsumerState<ObAttendanceImportScreen> {
  @override
  void initState() {
    super.initState();
    // Initialise import data for all subjects on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingNotifierProvider.notifier).initImportData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.import),
      totalSteps: OnboardingStep.all.length,
      showSkip: true,
      skipLabel: 'Skip',
      onSkip: () async {
        await notifier.skipImport();
        if (context.mounted) {
          context.go(OnboardingStep.routeFor(OnboardingStep.review));
        }
      },
      onBack: () =>
          context.go(OnboardingStep.routeFor(OnboardingStep.holidays)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Import existing\nattendance',
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
            'Already attending classes this semester? Sync your current status so your predictions are accurate from day one.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: OnboardingColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: OnboardingColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Skip this step to start fresh with zero attendance.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: OnboardingColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // ── Per-subject cards ─────────────────────────────────────
          if (state.importData.isEmpty)
            Center(
              child: Text('No subjects found.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: OnboardingColors.textSecondary)),
            )
          else
            ...state.importData.values.map((d) => _SubjectImportCard(
                  data: d,
                  semesterStart: state.semesterStart,
                  semesterEnd: state.semesterEnd,
                  notifier: notifier,
                )),
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
        label: 'Save & Continue',
        isLoading: state.isLoading,
        onPressed: () async {
          final ok = await notifier.saveImport();
          if (ok && context.mounted) {
            context.go(OnboardingStep.routeFor(OnboardingStep.review));
          }
        },
      ),
    );
  }
}

// ─── Per-Subject Import Card ──────────────────────────────────────────────────

class _SubjectImportCard extends StatefulWidget {
  const _SubjectImportCard({
    required this.data,
    required this.semesterStart,
    required this.semesterEnd,
    required this.notifier,
  });

  final SubjectImportData data;
  final DateTime? semesterStart;
  final DateTime? semesterEnd;
  final OnboardingNotifier notifier;

  @override
  State<_SubjectImportCard> createState() => _SubjectImportCardState();
}

class _SubjectImportCardState extends State<_SubjectImportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OnboardingColors.border),
      ),
      child: Column(
        children: [
          // ── Header (always visible) ───────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: OnboardingColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        d.subjectName.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: OnboardingColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.subjectName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OnboardingColors.textPrimary,
                            )),
                        if (d.method == ImportMethod.manualCount &&
                            d.manualTotal > 0)
                          Text(
                            '${d.manualAttended}/${d.manualTotal} classes',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: OnboardingColors.textSecondary,
                            ),
                          )
                        else if (d.method == ImportMethod.markAbsentDates &&
                            d.absentDates.isNotEmpty)
                          Text(
                            '${d.absentDates.length} absent date${d.absentDates.length == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: OnboardingColors.textSecondary,
                            ),
                          )
                        else
                          Text('Not set — will start at 0',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: OnboardingColors.textHint,
                              )),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: OnboardingColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // ── Expanded body ─────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: OnboardingColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Method selector
                  Row(
                    children: [
                      _MethodChip(
                        label: 'Manual Count',
                        selected:
                            d.method == ImportMethod.manualCount,
                        onTap: () => widget.notifier.setImportMethod(
                            d.subjectId, ImportMethod.manualCount),
                      ),
                      const SizedBox(width: 8),
                      _MethodChip(
                        label: 'Mark Absences',
                        selected:
                            d.method == ImportMethod.markAbsentDates,
                        onTap: () => widget.notifier.setImportMethod(
                            d.subjectId, ImportMethod.markAbsentDates),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (d.method == ImportMethod.manualCount)
                    _ManualCountInput(
                      data: d,
                      notifier: widget.notifier,
                    )
                  else
                    _AbsentDatesPicker(
                      data: d,
                      semesterStart: widget.semesterStart,
                      semesterEnd: widget.semesterEnd,
                      notifier: widget.notifier,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? OnboardingColors.chipSelected
              : OnboardingColors.chipUnselected,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? OnboardingColors.chipSelectedText
                : OnboardingColors.chipUnselectedText,
          ),
        ),
      ),
    );
  }
}

// ─── Method A: Manual Count ───────────────────────────────────────────────────

class _ManualCountInput extends StatelessWidget {
  const _ManualCountInput({required this.data, required this.notifier});
  final SubjectImportData data;
  final OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Classes conducted so far',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: OnboardingColors.textPrimary,
            )),
        const SizedBox(height: 10),
        _Stepper(
          label: 'Total classes held',
          value: data.manualTotal,
          onDecrement: () => notifier.setManualTotal(
              data.subjectId,
              (data.manualTotal - 1).clamp(0, 999)),
          onIncrement: () =>
              notifier.setManualTotal(data.subjectId, data.manualTotal + 1),
        ),
        const SizedBox(height: 12),
        _Stepper(
          label: 'Classes I attended',
          value: data.manualAttended,
          onDecrement: () => notifier.setManualAttended(
              data.subjectId,
              (data.manualAttended - 1).clamp(0, data.manualTotal)),
          onIncrement: () => notifier.setManualAttended(
              data.subjectId,
              (data.manualAttended + 1).clamp(0, data.manualTotal)),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });
  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: OnboardingColors.textSecondary,
              )),
        ),
        Row(
          children: [
            _StepBtn(icon: Icons.remove, onTap: onDecrement),
            const SizedBox(width: 12),
            SizedBox(
              width: 32,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: OnboardingColors.textPrimary,
                  )),
            ),
            const SizedBox(width: 12),
            _StepBtn(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: OnboardingColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OnboardingColors.border),
        ),
        child: Icon(icon, size: 18, color: OnboardingColors.textPrimary),
      ),
    );
  }
}

// ─── Method B: Mark Absent Dates ─────────────────────────────────────────────

class _AbsentDatesPicker extends StatefulWidget {
  const _AbsentDatesPicker({
    required this.data,
    required this.semesterStart,
    required this.semesterEnd,
    required this.notifier,
  });
  final SubjectImportData data;
  final DateTime? semesterStart;
  final DateTime? semesterEnd;
  final OnboardingNotifier notifier;

  @override
  State<_AbsentDatesPicker> createState() => _AbsentDatesPickerState();
}

class _AbsentDatesPickerState extends State<_AbsentDatesPicker> {
  DateTime _month = DateTime.now();

  bool _isSame(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inSemester(DateTime d) {
    final s = widget.semesterStart;
    final e = widget.semesterEnd;
    if (s == null || e == null) return true;
    return !d.isBefore(s) && !d.isAfter(e);
  }

  @override
  Widget build(BuildContext context) {
    final absent = widget.data.absentDates;
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: () => setState(() =>
                  _month = DateTime(_month.year, _month.month - 1)),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Center(
                child: Text(DateFormat('MMM yyyy').format(_month),
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: OnboardingColors.textPrimary)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: () => setState(() =>
                  _month = DateTime(_month.year, _month.month + 1)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIdx = row * 7 + col;
              final dayNum = cellIdx - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 36));
              }
              final date = DateTime(_month.year, _month.month, dayNum);
              final isAbsent = absent.any((d) => _isSame(d, date));
              final inSem = _inSemester(date);

              return Expanded(
                child: GestureDetector(
                  onTap: inSem
                      ? () => widget.notifier
                          .toggleAbsentDate(widget.data.subjectId, date)
                      : null,
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isAbsent
                          ? OnboardingColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isAbsent ? FontWeight.w700 : FontWeight.w400,
                          color: isAbsent
                              ? Colors.white
                              : inSem
                                  ? OnboardingColors.textPrimary
                                  : OnboardingColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
        if (absent.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('${absent.length} absent day${absent.length == 1 ? '' : 's'} marked',
              style: GoogleFonts.inter(
                  fontSize: 12, color: OnboardingColors.textSecondary)),
        ],
      ],
    );
  }
}
