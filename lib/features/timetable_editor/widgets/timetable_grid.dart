/// TimetableGrid — Shared grid widget (Section 3 + 4)
///
/// Used identically in onboarding and edit mode. Mode only changes the
/// surrounding chrome — this widget's internal logic is identical.
///
/// Layout: days as columns (horizontal scroll with snap), periods as rows
/// (vertical scroll). Sticky day-header row and sticky period-label column.
///
/// Implementation: two linked ScrollControllers (horizontal header + body)
/// with a fixed leading column. No external packages required beyond core Flutter.
///
/// Cell states:
///   empty     — dashed border, 44×44+ tap target
///   occupied  — color fill, short name, edit-pencil icon
///   multi-span — merged cell across spanPeriods rows (no internal dividers)
///   conflict  — warning border + badge

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';
import 'cell_bottom_sheet.dart';
import 'day_copy_suggestion_sheet.dart';
import 'period_timing_sheet.dart';
import 'subject_library_strip.dart';

// ─── Mode enum ────────────────────────────────────────────────────────────────

enum TimetableGridMode { onboarding, edit }

// ─── Constants ────────────────────────────────────────────────────────────────

const _kCellHeight = 54.0;      // minimum: 44 logical pixels per spec
const _kCellWidth = 86.0;       // column width for each day
const _kLabelWidth = 64.0;      // sticky period-label column
const _kHeaderHeight = 44.0;    // sticky day-header row
const _kDaysVisible = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

// ─── Main widget ──────────────────────────────────────────────────────────────

class TimetableGrid extends ConsumerStatefulWidget {
  const TimetableGrid({
    super.key,
    required this.mode,
    this.onFinish,
  });

  final TimetableGridMode mode;
  final VoidCallback? onFinish;

  @override
  ConsumerState<TimetableGrid> createState() => _TimetableGridState();
}

class _TimetableGridState extends ConsumerState<TimetableGrid> {
  final _vertScrollCtrl = ScrollController();
  final _horizBodyCtrl = ScrollController();
  final _horizHeaderCtrl = ScrollController();

  String _currentDay = 'MON';
  bool _summaryExpanded = false;

  @override
  void initState() {
    super.initState();
    // Sync horizontal scroll between header and body
    _horizBodyCtrl.addListener(() {
      if (_horizBodyCtrl.hasClients && _horizHeaderCtrl.hasClients) {
        if (_horizHeaderCtrl.offset != _horizBodyCtrl.offset) {
          _horizHeaderCtrl.jumpTo(_horizBodyCtrl.offset);
        }
      }
    });
  }

  @override
  void dispose() {
    _vertScrollCtrl.dispose();
    _horizBodyCtrl.dispose();
    _horizHeaderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableEditorNotifierProvider);
    final editorState = state.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF111318) : const Color(0xFFFAF8FF);
    final onSurface = isDark ? Colors.white : const Color(0xFF191B23);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF434655);
    final surface = isDark ? const Color(0xFF1E2028) : Colors.white;
    final border = isDark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED);

    // Use default schedule if no periods configured
    final periodsForDisplay = editorState.defaultSchedule.isNotEmpty
        ? editorState.defaultSchedule
        : _defaultFallbackPeriods();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Subject library strip ──────────────────────────────────────
            SubjectLibraryStrip(
              onAddSubjectTap: () => _showAddSubjectSheet(context),
            ),

            // ── Progress indicator (onboarding only) ───────────────────────
            if (widget.mode == TimetableGridMode.onboarding)
              _ProgressIndicator(
                filled: editorState.filledWeekdayCount,
                isDark: isDark,
                onSurface: onSurface,
                secondary: secondary,
              ),

            // ── Grid area ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // Sticky header row (day names)
                  _StickyDayHeader(
                    horizCtrl: _horizHeaderCtrl,
                    days: _kDaysVisible,
                    currentDay: _currentDay,
                    lectures: editorState.lectures,
                    isDark: isDark,
                    onSurface: onSurface,
                    secondary: secondary,
                    surface: surface,
                    border: border,
                  ),
                  // Grid body
                  Expanded(
                    child: _GridBody(
                      editorState: editorState,
                      conflicts: state.conflicts,
                      ui: state.ui,
                      periods: periodsForDisplay,
                      horizCtrl: _horizBodyCtrl,
                      vertCtrl: _vertScrollCtrl,
                      isDark: isDark,
                      onSurface: onSurface,
                      secondary: secondary,
                      surface: surface,
                      border: border,
                      onDayScrolled: (day) {
                        if (_currentDay != day) {
                          setState(() => _currentDay = day);
                          _maybeShowDayCopySuggestion(day);
                        }
                      },
                      onCellTap: (day, periodId) =>
                          _onCellTap(context, day, periodId, editorState, state),
                    ),
                  ),
                ],
              ),
            ),

            // ── Live Summary card ──────────────────────────────────────────
            _LiveSummaryCard(
              editorState: editorState,
              expanded: _summaryExpanded ||
                  widget.mode == TimetableGridMode.onboarding,
              isDark: isDark,
              onSurface: onSurface,
              secondary: secondary,
              surface: surface,
              border: border,
              onToggle: () => setState(() => _summaryExpanded = !_summaryExpanded),
            ),

            // ── Undo/Redo toolbar ──────────────────────────────────────────
            _UndoRedoBar(isDark: isDark, secondary: secondary, surface: surface),

            // ── Bottom CTA ────────────────────────────────────────────────
            _BottomCta(
              mode: widget.mode,
              isDark: isDark,
              onFinish: widget.onFinish,
              onTimingTap: () => _showTimingSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Interaction handlers ─────────────────────────────────────────────────────

  void _onCellTap(
    BuildContext context,
    String day,
    String periodId,
    TimetableEditorState editorState,
    TimetableEditorFullState fullState,
  ) {
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);
    final existingLecture = notifier.lectureAtCell(day, periodId);

    if (existingLecture != null) {
      // Occupied cell
      if (fullState.ui.isPlacementMode) {
        // In placement mode: open bottom sheet to confirm change
        final subject = editorState.subjectById(existingLecture.subjectId);
        if (subject == null) return;
        final periods = editorState.periodsForDay(day);
        showCellBottomSheet(
          context: context,
          ref: ref,
          lecture: existingLecture,
          subject: subject,
          dayPeriods: periods,
        );
      } else {
        // Normal tap: open bottom sheet
        final subject = editorState.subjectById(existingLecture.subjectId);
        if (subject == null) return;
        final periods = editorState.periodsForDay(day);
        showCellBottomSheet(
          context: context,
          ref: ref,
          lecture: existingLecture,
          subject: subject,
          dayPeriods: periods,
        );
      }
    } else {
      // Empty cell
      notifier.placeLecture(day, periodId);
    }
  }

  void _maybeShowDayCopySuggestion(String day) {
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);
    if (!notifier.shouldShowDayCopySuggestion(day)) return;

    final prevIdx = kDayOrder.indexOf(day) - 1;
    if (prevIdx < 0) return;
    final prevDay = kDayOrder[prevIdx];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDayCopySuggestion(
        context: context,
        ref: ref,
        currentDay: day,
        previousDay: prevDay,
      );
    });
  }

  void _showTimingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PeriodTimingSheet(),
    );
  }

  void _showAddSubjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSubjectSheet(),
    );
  }

  List<PeriodSlot> _defaultFallbackPeriods() {
    // 6 periods, 50 min each, 10 min break, starting 9:00
    const slots = <PeriodSlot>[
      PeriodSlot(id: 'p1', label: 'P1', startTime: '09:00', endTime: '09:50', type: PeriodType.lecture),
      PeriodSlot(id: 'b1', label: 'Break', startTime: '09:50', endTime: '10:00', type: PeriodType.breakPeriod),
      PeriodSlot(id: 'p2', label: 'P2', startTime: '10:00', endTime: '10:50', type: PeriodType.lecture),
      PeriodSlot(id: 'b2', label: 'Break', startTime: '10:50', endTime: '11:00', type: PeriodType.breakPeriod),
      PeriodSlot(id: 'p3', label: 'P3', startTime: '11:00', endTime: '11:50', type: PeriodType.lecture),
      PeriodSlot(id: 'lunch', label: 'Lunch', startTime: '11:50', endTime: '12:30', type: PeriodType.lunch),
      PeriodSlot(id: 'p4', label: 'P4', startTime: '12:30', endTime: '13:20', type: PeriodType.lecture),
      PeriodSlot(id: 'b3', label: 'Break', startTime: '13:20', endTime: '13:30', type: PeriodType.breakPeriod),
      PeriodSlot(id: 'p5', label: 'P5', startTime: '13:30', endTime: '14:20', type: PeriodType.lecture),
      PeriodSlot(id: 'b4', label: 'Break', startTime: '14:20', endTime: '14:30', type: PeriodType.breakPeriod),
      PeriodSlot(id: 'p6', label: 'P6', startTime: '14:30', endTime: '15:20', type: PeriodType.lecture),
    ];
    return slots;
  }
}

// ─── Sticky Day Header ────────────────────────────────────────────────────────

class _StickyDayHeader extends StatelessWidget {
  const _StickyDayHeader({
    required this.horizCtrl,
    required this.days,
    required this.currentDay,
    required this.lectures,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
    required this.surface,
    required this.border,
  });

  final ScrollController horizCtrl;
  final List<String> days;
  final String currentDay;
  final List<LectureBlock> lectures;
  final bool isDark;
  final Color onSurface;
  final Color secondary;
  final Color surface;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);

    return Container(
      color: surface,
      child: Row(
        children: [
          // Corner spacer above period-label column
          Container(
            width: _kLabelWidth,
            height: _kHeaderHeight,
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
          ),
          // Scrollable day names (linked to body horizontal scroll)
          Expanded(
            child: SingleChildScrollView(
              controller: horizCtrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // driven by body
              child: Row(
                children: days.map((day) {
                  final isActive = day == currentDay;
                  final hasLectures =
                      lectures.any((l) => l.day == day);
                  return Container(
                    width: _kCellWidth,
                    height: _kHeaderHeight,
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withAlpha(isDark ? 40 : 20)
                          : surface,
                      border: Border(
                        left: BorderSide(color: border, width: 0.5),
                        bottom: BorderSide(
                          color: isActive ? primaryColor : border,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? primaryColor : secondary,
                          ),
                        ),
                        if (hasLectures)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isActive ? primaryColor : secondary.withAlpha(150),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid Body ────────────────────────────────────────────────────────────────

class _GridBody extends StatelessWidget {
  const _GridBody({
    required this.editorState,
    required this.conflicts,
    required this.ui,
    required this.periods,
    required this.horizCtrl,
    required this.vertCtrl,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
    required this.surface,
    required this.border,
    required this.onDayScrolled,
    required this.onCellTap,
  });

  final TimetableEditorState editorState;
  final Map<String, ConflictInfo> conflicts;
  final TimetableEditorUiState ui;
  final List<PeriodSlot> periods;
  final ScrollController horizCtrl;
  final ScrollController vertCtrl;
  final bool isDark;
  final Color onSurface;
  final Color secondary;
  final Color surface;
  final Color border;
  final ValueChanged<String> onDayScrolled;
  final void Function(String day, String periodId) onCellTap;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.horizontal) {
          // Determine which day column is most centered in viewport
          final offset = horizCtrl.hasClients ? horizCtrl.offset : 0.0;
          final dayIdx = (offset / _kCellWidth).round().clamp(0, kDayOrder.length - 1);
          onDayScrolled(kDayOrder[dayIdx]);
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: vertCtrl,
        scrollDirection: Axis.vertical,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky period-label column (vertical scroll with body, not horizontal)
            _PeriodLabelColumn(
              periods: periods,
              isDark: isDark,
              onSurface: onSurface,
              secondary: secondary,
              surface: surface,
              border: border,
            ),
            // Scrollable grid body
            Expanded(
              child: SingleChildScrollView(
                controller: horizCtrl,
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: kDayOrder.map((day) {
                    return _DayColumn(
                      day: day,
                      periods: editorState.periodsForDay(day).isEmpty
                          ? periods
                          : editorState.periodsForDay(day),
                      defaultPeriods: periods,
                      lectures: editorState.lecturesForDay(day),
                      subjects: editorState.subjects,
                      conflicts: conflicts,
                      ui: ui,
                      isDark: isDark,
                      onSurface: onSurface,
                      secondary: secondary,
                      surface: surface,
                      border: border,
                      onCellTap: (periodId) => onCellTap(day, periodId),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period label column ──────────────────────────────────────────────────────

class _PeriodLabelColumn extends StatelessWidget {
  const _PeriodLabelColumn({
    required this.periods,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
    required this.surface,
    required this.border,
  });

  final List<PeriodSlot> periods;
  final bool isDark;
  final Color onSurface;
  final Color secondary;
  final Color surface;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kLabelWidth,
      child: Column(
        children: periods.map((slot) {
          final isBreak = slot.type != PeriodType.lecture;
          return Container(
            height: isBreak ? _kCellHeight * 0.6 : _kCellHeight,
            width: _kLabelWidth,
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                right: BorderSide(color: border, width: 1),
                bottom: BorderSide(color: border, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isBreak ? secondary.withAlpha(150) : onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  slot.startTime,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: secondary.withAlpha(isBreak ? 100 : 200),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Day column ───────────────────────────────────────────────────────────────

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.periods,
    required this.defaultPeriods,
    required this.lectures,
    required this.subjects,
    required this.conflicts,
    required this.ui,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
    required this.surface,
    required this.border,
    required this.onCellTap,
  });

  final String day;
  final List<PeriodSlot> periods;
  final List<PeriodSlot> defaultPeriods;
  final List<LectureBlock> lectures;
  final List<TimetableSubject> subjects;
  final Map<String, ConflictInfo> conflicts;
  final TimetableEditorUiState ui;
  final bool isDark;
  final Color onSurface;
  final Color secondary;
  final Color surface;
  final Color border;
  final ValueChanged<String> onCellTap;

  @override
  Widget build(BuildContext context) {
    // Build a map of periodId → lecture that starts at that period
    final lectureByPeriod = <String, LectureBlock>{};
    for (final l in lectures) {
      lectureByPeriod[l.startPeriodId] = l;
    }

    // Build set of period IDs that are "consumed" by a multi-span lecture
    final consumedIds = <String>{};
    for (final l in lectures) {
      if (l.spanPeriods > 1) {
        final startIdx = periods.indexWhere((p) => p.id == l.startPeriodId);
        if (startIdx != -1) {
          for (int i = 1; i < l.spanPeriods && startIdx + i < periods.length; i++) {
            consumedIds.add(periods[startIdx + i].id);
          }
        }
      }
    }

    return SizedBox(
      width: _kCellWidth,
      child: Column(
        children: periods.asMap().entries.map((entry) {
          final i = entry.key;
          final slot = entry.value;
          final isBreak = slot.type != PeriodType.lecture;

          // Skip consumed cells (part of multi-span)
          if (consumedIds.contains(slot.id)) {
            return const SizedBox.shrink();
          }

          final lecture = lectureByPeriod[slot.id];
          final subject = lecture != null
              ? subjects.firstWhere(
                  (s) => s.id == lecture.subjectId,
                  orElse: () => TimetableSubject(
                    id: lecture.subjectId,
                    name: '?',
                    shortName: '?',
                    colorHex: kSubjectColorPalette[0],
                  ),
                )
              : null;

          // Compute height for multi-span cells
          double cellHeight = isBreak ? _kCellHeight * 0.6 : _kCellHeight;
          if (lecture != null && lecture.spanPeriods > 1) {
            double total = cellHeight;
            for (int j = 1;
                j < lecture.spanPeriods && i + j < periods.length;
                j++) {
              final next = periods[i + j];
              total += (next.type != PeriodType.lecture)
                  ? _kCellHeight * 0.6
                  : _kCellHeight;
            }
            cellHeight = total;
          }

          final hasConflict = lecture != null && conflicts.containsKey(lecture.id);
          final isPlacementMode = ui.isPlacementMode;

          return _GridCell(
            slot: slot,
            lecture: lecture,
            subject: subject,
            height: cellHeight,
            hasConflict: hasConflict,
            conflictMessage: hasConflict ? conflicts[lecture!.id]?.message : null,
            isPlacementMode: isPlacementMode,
            isPickupMode: ui.isPickupMode,
            isDark: isDark,
            onSurface: onSurface,
            secondary: secondary,
            border: border,
            onTap: () => onCellTap(slot.id),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Grid Cell ────────────────────────────────────────────────────────────────

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.slot,
    required this.lecture,
    required this.subject,
    required this.height,
    required this.hasConflict,
    required this.conflictMessage,
    required this.isPlacementMode,
    required this.isPickupMode,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
    required this.border,
    required this.onTap,
  });

  final PeriodSlot slot;
  final LectureBlock? lecture;
  final TimetableSubject? subject;
  final double height;
  final bool hasConflict;
  final String? conflictMessage;
  final bool isPlacementMode;
  final bool isPickupMode;
  final bool isDark;
  final Color onSurface;
  final Color secondary;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBreak = slot.type != PeriodType.lecture;
    final isEmpty = lecture == null;

    // Break/lunch cells — dimmer, not tappable for placement
    if (isBreak) {
      return Container(
        width: _kCellWidth,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E2028).withAlpha(180)
              : const Color(0xFFF5F5F5),
          border: Border(
            left: BorderSide(color: border, width: 0.5),
            bottom: BorderSide(color: border, width: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            slot.label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: secondary.withAlpha(120),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (isEmpty) {
      // Empty lecture cell
      return _EmptyCell(
        height: height,
        isPlacementMode: isPlacementMode,
        isDark: isDark,
        border: border,
        onTap: onTap,
      );
    }

    // Occupied cell
    return _OccupiedCell(
      lecture: lecture!,
      subject: subject!,
      height: height,
      hasConflict: hasConflict,
      conflictMessage: conflictMessage,
      isDark: isDark,
      border: border,
      onTap: onTap,
    );
  }
}

// ─── Empty Cell ───────────────────────────────────────────────────────────────

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({
    required this.height,
    required this.isPlacementMode,
    required this.isDark,
    required this.border,
    required this.onTap,
  });

  final double height;
  final bool isPlacementMode;
  final bool isDark;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      splashColor: primaryColor.withAlpha(30),
      highlightColor: primaryColor.withAlpha(15),
      child: Container(
        width: _kCellWidth,
        height: height,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: border, width: 0.5),
            bottom: BorderSide(color: border, width: 0.5),
          ),
        ),
        child: Center(
          child: isPlacementMode
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(isDark ? 50 : 25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.add_rounded,
                      size: 14, color: primaryColor),
                )
              : CustomPaint(
                  size: const Size(20, 20),
                  painter: _DashedBorderPainter(color: border),
                ),
        ),
      ),
    );
  }
}

// ─── Occupied Cell ────────────────────────────────────────────────────────────

class _OccupiedCell extends StatelessWidget {
  const _OccupiedCell({
    required this.lecture,
    required this.subject,
    required this.height,
    required this.hasConflict,
    required this.conflictMessage,
    required this.isDark,
    required this.border,
    required this.onTap,
  });

  final LectureBlock lecture;
  final TimetableSubject subject;
  final double height;
  final bool hasConflict;
  final String? conflictMessage;
  final bool isDark;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subjectColor = hexToColor(subject.colorHex);
    final bgColor = subjectColor.withAlpha(isDark ? 60 : 45);
    final textColor = isDark ? Colors.white : const Color(0xFF111111);

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _kCellWidth,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(
              color: subjectColor,
              width: 3,
            ),
            top: BorderSide(color: border, width: 0.5),
            right: BorderSide(color: border, width: 0.5),
            bottom: BorderSide(color: border, width: 0.5),
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.shortName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: subjectColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lecture.isLab)
                    Text(
                      'Lab',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: subjectColor.withAlpha(200),
                      ),
                    ),
                  if (lecture.classroom != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          lecture.classroom!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: textColor.withAlpha(120),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Edit pencil icon
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.edit_rounded,
                size: 10,
                color: textColor.withAlpha(80),
              ),
            ),
            // Conflict badge
            if (hasConflict)
              Positioned(
                bottom: 4,
                right: 4,
                child: Tooltip(
                  message: conflictMessage ?? 'Conflict',
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
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

// ─── Dashed border painter ────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)));
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
              distance, (distance + dashWidth).clamp(0, metric.length)),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ─── Progress indicator ────────────────────────────────────────────────────────

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.filled,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
  });

  final int filled;
  final bool isDark;
  final Color onSurface;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(
            filled >= 5
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            size: 14,
            color: filled >= 5
                ? const Color(0xFF16A34A)
                : secondary,
          ),
          const SizedBox(width: 6),
          Text(
            '$filled of 5 weekdays have at least one class',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Summary Card ────────────────────────────────────────────────────────

class _LiveSummaryCard extends StatelessWidget {
  const _LiveSummaryCard({
    required this.editorState,
    required this.expanded,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
    required this.surface,
    required this.border,
    required this.onToggle,
  });

  final TimetableEditorState editorState;
  final bool expanded;
  final bool isDark;
  final Color onSurface;
  final Color secondary;
  final Color surface;
  final Color border;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final totalLectures = editorState.totalWeeklyLectures;
    final subjects = editorState.subjects.length;
    final labs = editorState.labSessionCount;
    final freeSlots = editorState.defaultSchedule
        .where((s) => s.type == PeriodType.lecture)
        .length *
        7 -
        totalLectures;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Weekly Summary',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 16,
                  color: secondary,
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(label: 'Classes', value: '$totalLectures/week', onSurface: onSurface, secondary: secondary),
                  const SizedBox(width: 16),
                  _StatChip(label: 'Subjects', value: '$subjects', onSurface: onSurface, secondary: secondary),
                  const SizedBox(width: 16),
                  _StatChip(label: 'Labs', value: '$labs', onSurface: onSurface, secondary: secondary),
                  const SizedBox(width: 16),
                  _StatChip(label: 'Free', value: '${freeSlots < 0 ? 0 : freeSlots}', onSurface: onSurface, secondary: secondary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.onSurface,
    required this.secondary,
  });

  final String label;
  final String value;
  final Color onSurface;
  final Color secondary;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: onSurface)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: secondary)),
        ],
      );
}

// ─── Undo/Redo toolbar ────────────────────────────────────────────────────────

class _UndoRedoBar extends ConsumerWidget {
  const _UndoRedoBar({
    required this.isDark,
    required this.secondary,
    required this.surface,
  });

  final bool isDark;
  final Color secondary;
  final Color surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);
    final canUndo = notifier.canUndo;
    final canRedo = notifier.canRedo;

    return Container(
      color: surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: canUndo ? () => notifier.undo() : null,
            icon: Icon(Icons.undo_rounded,
                size: 20,
                color: canUndo ? secondary : secondary.withAlpha(60)),
            tooltip: 'Undo',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: canRedo ? () => notifier.redo() : null,
            icon: Icon(Icons.redo_rounded,
                size: 20,
                color: canRedo ? secondary : secondary.withAlpha(60)),
            tooltip: 'Redo',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom CTA ───────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.mode,
    required this.isDark,
    required this.onFinish,
    required this.onTimingTap,
  });

  final TimetableGridMode mode;
  final bool isDark;
  final VoidCallback? onFinish;
  final VoidCallback onTimingTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);
    final surface = isDark ? const Color(0xFF1E2028) : Colors.white;
    final border = isDark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED);

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Timing/settings FAB
          GestureDetector(
            onTap: onTimingTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282A34) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Icon(Icons.schedule_rounded,
                  size: 20, color: primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor:
                      isDark ? const Color(0xFF002576) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  mode == TimetableGridMode.onboarding
                      ? 'Finish Setup'
                      : 'Done',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
