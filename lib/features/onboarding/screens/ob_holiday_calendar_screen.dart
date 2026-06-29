import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

class ObHolidayCalendarScreen extends ConsumerStatefulWidget {
  const ObHolidayCalendarScreen({super.key});

  @override
  ConsumerState<ObHolidayCalendarScreen> createState() =>
      _ObHolidayCalendarScreenState();
}

class _ObHolidayCalendarScreenState
    extends ConsumerState<ObHolidayCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final semStart = state.semesterStart;
    final semEnd = state.semesterEnd;

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.holidays),
      totalSteps: OnboardingStep.all.length,
      showSkip: true,
      skipLabel: 'Skip',
      onSkip: () async {
        await notifier.skipHolidays();
        if (context.mounted) {
          context.go(OnboardingStep.routeFor(OnboardingStep.import));
        }
      },
      onBack: () =>
          context.go(OnboardingStep.routeFor(OnboardingStep.timetable)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Mark your\nholidays',
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
            'Tap any date to mark it as a holiday. Holidays are excluded from attendance calculations.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // ── Month navigation ──────────────────────────────────────
          _MonthNav(
            month: _focusedMonth,
            onPrev: () => setState(() => _focusedMonth =
                DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
            onNext: () => setState(() => _focusedMonth =
                DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
          ),
          const SizedBox(height: 16),
          // ── Calendar grid ─────────────────────────────────────────
          _CalendarGrid(
            month: _focusedMonth,
            holidays: state.holidays,
            semesterStart: semStart,
            semesterEnd: semEnd,
            onToggle: (d) => notifier.toggleHoliday(d),
          ),
          const SizedBox(height: 20),
          // ── Holiday count chip ────────────────────────────────────
          if (state.holidays.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: OnboardingColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.beach_access_rounded,
                      size: 16, color: OnboardingColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${state.holidays.length} holiday${state.holidays.length == 1 ? '' : 's'} marked',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: OnboardingColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
      cta: OnboardingCTAButton(
        label: 'Continue',
        onPressed: () async {
          await notifier.completeHolidays();
          if (context.mounted) {
            context.go(OnboardingStep.routeFor(OnboardingStep.import));
          }
        },
      ),
    );
  }
}

// ─── Month navigation ─────────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  const _MonthNav(
      {required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: OnboardingColors.textPrimary),
          onPressed: onPrev,
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: OnboardingColors.textPrimary,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded,
              color: OnboardingColors.textPrimary),
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ─── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.holidays,
    required this.semesterStart,
    required this.semesterEnd,
    required this.onToggle,
  });

  final DateTime month;
  final List<DateTime> holidays;
  final DateTime? semesterStart;
  final DateTime? semesterEnd;
  final ValueChanged<DateTime> onToggle;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isHoliday(DateTime d) => holidays.any((h) => _isSameDay(h, d));

  bool _inSemester(DateTime d) {
    if (semesterStart == null || semesterEnd == null) return true;
    return !d.isBefore(semesterStart!) && !d.isAfter(semesterEnd!);
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // firstDay.weekday: 1=Mon … 7=Sun
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Day headers
        Row(
          children: dayNames
              .map((n) => Expanded(
                    child: Center(
                      child: Text(n,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: OnboardingColors.textHint,
                          )),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final date = DateTime(month.year, month.month, dayNum);
              final isHoliday = _isHoliday(date);
              final inSem = _inSemester(date);
              final isToday = _isSameDay(date, DateTime.now());

              return Expanded(
                child: GestureDetector(
                  onTap: inSem ? () => onToggle(date) : null,
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isHoliday
                          ? OnboardingColors.primary
                          : isToday
                              ? OnboardingColors.surface
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isHoliday
                          ? Border.all(
                              color: OnboardingColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isHoliday || isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isHoliday
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
      ],
    );
  }
}
