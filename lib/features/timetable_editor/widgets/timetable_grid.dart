/// TimetableGrid — True Continuous Timeline Grid
///
/// Implements a Google-Calendar-style day-view grid where each day column
/// is a fixed-height Stack. LectureBlocks are Positioned absolutely by their
/// real start minute and duration — not row/slot-anchored.
///
/// Layout:
///   • Sticky time-label column (left)
///   • Sticky day-header row (top)
///   • Each day column is a Stack with:
///       - Background: CustomPaint drawing decorative hour separator lines
///       - Tap layer: GestureDetector → converts tap Y → snapped 15-min start
///       - Lecture blocks: Positioned by (startMins - rangeStart) * pxPerMin
///   • Subject library strip pinned below header
///
/// Placement:
///   • Tap empty area → snaps to nearest 15-min, places selected subject
///   • Tap occupied block → quick remove popup
///   • Long-press occupied block → detail sheet (time picker, duration, notes)
///
/// Same-subject contiguous detection:
///   blockA.endTime == blockB.startTime → suppress shared border between them
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/subject_model.dart';
import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';
import 'subject_library_strip.dart';
import 'cell_bottom_sheet.dart';

// ─── Mode enum ────────────────────────────────────────────────────────────────

enum TimetableGridMode { onboarding, edit }

// ─── Layout constants ─────────────────────────────────────────────────────────

const _kPxPerMinute = 1.2;       // 60 min = 72 px per hour
const _kCellWidth    = 90.0;
const _kLabelWidth   = 52.0;
const _kHeaderHeight = 48.0;
const _kMinSnapMinutes = 15;
// Bug-2: extra space below the last hour mark so content is never hidden
// behind the Customize bar (or onboarding footer) when scrolled to bottom.
const _kScrollBottomPad = 80.0;

// ─── Shared pixel ↔ time conversion utilities (Phase B) ─────────────────────
// Single source of truth — both the renderer AND every gesture handler call
// these. Prevents drift if layout constants or rangeStart ever diverge.

/// Converts an absolute minute value (since midnight) to a Y pixel offset
/// within the day column, given the column's visible range start and scale.
double minutesToY(int minutes, int rangeStart) =>
    (minutes - rangeStart) * _kPxPerMinute;

/// Converts a Y pixel offset within the day column back to an absolute
/// minute value (since midnight), given the column's visible range start.
int yToMinutes(double y, int rangeStart) =>
    rangeStart + (y / _kPxPerMinute).round();

// ─── Phase D — Drag state and candidate algorithm ─────────────────────────────

/// Tracks one in-progress long-press drag.
/// [ghostStartMins] is the snapped candidate position shown to the user.
class _DragInfo {
  final LectureBlock lecture;
  final String day;
  int ghostStartMins;

  _DragInfo({
    required this.lecture,
    required this.day,
    required this.ghostStartMins,
  });

  _DragInfo withGhost(int mins) => _DragInfo(
        lecture: lecture,
        day: day,
        ghostStartMins: mins,
      );
}

/// Candidate-snapping algorithm.
/// Candidates are generated from three sources:
///   1. Flush-after: start = end of each other block on this day.
///   2. Flush-before: start = start of each other block − dragged duration.
///   3. 15-min grid: rangeStart, rangeStart+15, …, rangeEnd − duration.
/// All candidates are filtered to [rangeStart, rangeEnd − duration] and must
/// not overlap any existing block (excluding the block being dragged).
/// Returns the candidate nearest to [fingerMins], or [fingerMins] clamped to
/// range if no valid candidate exists.
int _findBestCandidate({
  required int fingerMins,
  required int durationMinutes,
  required List<LectureBlock> lectures,
  required String excludeId,
  required int rangeStart,
  required int rangeEnd,
}) {
  final others = lectures.where((l) => l.id != excludeId).toList();

  final candidates = <int>{};

  // 1. Flush-after each other block
  for (final l in others) {
    candidates.add(l.startHour * 60 + l.startMinute + l.durationMinutes);
  }
  // 2. Flush-before each other block
  for (final l in others) {
    candidates.add(l.startHour * 60 + l.startMinute - durationMinutes);
  }
  // 3. 15-min grid throughout the range
  for (int m = rangeStart; m <= rangeEnd - durationMinutes; m += 15) {
    candidates.add(m);
  }

  // Filter: must be within the visible range AND must not overlap any other block
  bool overlaps(int start) {
    final end = start + durationMinutes;
    for (final l in others) {
      final lStart = l.startHour * 60 + l.startMinute;
      final lEnd = lStart + l.durationMinutes;
      if (start < lEnd && lStart < end) return true;
    }
    return false;
  }

  final valid = candidates
      .where((c) =>
          c >= rangeStart &&
          c + durationMinutes <= rangeEnd &&
          !overlaps(c))
      .toList()
    ..sort((a, b) => (a - fingerMins).abs().compareTo((b - fingerMins).abs()));

  if (valid.isEmpty) {
    return fingerMins.clamp(rangeStart, rangeEnd - durationMinutes);
  }
  return valid.first;
}

// ─── Main widget ──────────────────────────────────────────────────────────────

class TimetableGrid extends ConsumerStatefulWidget {
  const TimetableGrid({
    super.key,
    required this.mode,
    this.onFinish,
    this.onAddSubjectTap,
  });

  final TimetableGridMode mode;
  final VoidCallback? onFinish;
  final VoidCallback? onAddSubjectTap;

  @override
  ConsumerState<TimetableGrid> createState() => _TimetableGridState();
}

class _TimetableGridState extends ConsumerState<TimetableGrid> {
  final _vertBodyCtrl  = ScrollController();
  final _vertLabelCtrl = ScrollController();
  final _horizBodyCtrl   = ScrollController();
  final _horizHeaderCtrl = ScrollController();

  // Phase C: per-block revealed state. Only one block can be revealed at a time.
  // Null = all blocks are in their collapsed (default) state.
  String? _revealedId;

  // Phase D: active drag tracking.
  _DragInfo? _drag;
  // One GlobalKey per day column so onDragUpdate can convert global→local Y.
  final _columnKeys = {
    for (final day in kDayOrder) day: GlobalKey()
  };

  @override
  void initState() {
    super.initState();
    _horizBodyCtrl.addListener(_syncHoriz);
    _vertBodyCtrl.addListener(_syncVert);
  }

  void _syncHoriz() {
    if (_horizBodyCtrl.hasClients && _horizHeaderCtrl.hasClients) {
      if (_horizHeaderCtrl.offset != _horizBodyCtrl.offset) {
        _horizHeaderCtrl.jumpTo(_horizBodyCtrl.offset);
      }
    }
  }

  void _syncVert() {
    if (_vertBodyCtrl.hasClients && _vertLabelCtrl.hasClients) {
      if (_vertLabelCtrl.offset != _vertBodyCtrl.offset) {
        _vertLabelCtrl.jumpTo(_vertBodyCtrl.offset);
      }
    }
  }

  @override
  void dispose() {
    _horizBodyCtrl.removeListener(_syncHoriz);
    _vertBodyCtrl.removeListener(_syncVert);
    _vertBodyCtrl.dispose();
    _vertLabelCtrl.dispose();
    _horizBodyCtrl.dispose();
    _horizHeaderCtrl.dispose();
    super.dispose();
  }

  // ── Colours ────────────────────────────────────────────────────────────────

  Color _bg(bool dark)        => dark ? const Color(0xFF111318) : const Color(0xFFF7F7FB);
  Color _surface(bool dark)   => dark ? const Color(0xFF1E2028) : Colors.white;
  Color _border(bool dark)    => dark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED);
  Color _labelColor(bool dark)=> dark ? const Color(0xFF8B8FA8) : const Color(0xFF8990B0);
  Color _headerText(bool dark)=> dark ? Colors.white : const Color(0xFF191B23);
  Color _primary(bool dark)   => dark ? const Color(0xFFB4C5FF) : const Color(0xFF4F5EFF);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fullState  = ref.watch(timetableEditorNotifierProvider);
    final editorData = fullState.data;
    final dark       = Theme.of(context).brightness == Brightness.dark;

    final rangeStart = editorData.gridStartHour * 60; // minutes since midnight
    final rangeEnd   = editorData.gridEndHour   * 60;
    final totalMins  = rangeEnd - rangeStart;
    final columnHeight = totalMins * _kPxPerMinute;

    // Build hour mark list for both labels and background lines
    final hourMarks = <int>[
      for (int h = editorData.gridStartHour; h <= editorData.gridEndHour; h++) h,
    ];

    return ColoredBox(
      color: _bg(dark),
      child: Column(
        children: [
          // ── Subject library strip ──────────────────────────────────────────
          SubjectLibraryStrip(
            onAddSubjectTap: widget.onAddSubjectTap,
          ),

          // ── Header row (day labels) ────────────────────────────────────────
          SizedBox(
            height: _kHeaderHeight,
            child: Row(
              children: [
                // Corner cell
                SizedBox(
                  width: _kLabelWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _surface(dark),
                      border: Border(
                        bottom: BorderSide(color: _border(dark)),
                        right:  BorderSide(color: _border(dark)),
                      ),
                    ),
                  ),
                ),
                // Scrolling day headers (synced with body)
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizHeaderCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: kDayOrder.map((day) {
                        final hasLectures =
                            editorData.lecturesForDay(day).isNotEmpty;
                        return _DayHeaderCell(
                          day: day,
                          hasLectures: hasLectures,
                          dark: dark,
                          textColor: _headerText(dark),
                          border: _border(dark),
                          surface: _surface(dark),
                          accent: _primary(dark),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Grid body (scrollable) ─────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sticky time-label column
                SizedBox(
                  width: _kLabelWidth,
                  child: SingleChildScrollView(
                    controller: _vertLabelCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    // Bug-2: extend by _kScrollBottomPad to match body scroll.
                    padding: const EdgeInsets.only(bottom: _kScrollBottomPad),
                    child: _TimeLabelColumn(
                      hourMarks: hourMarks,
                      columnHeight: columnHeight,
                      rangeStart: rangeStart,
                      dark: dark,
                      labelColor: _labelColor(dark),
                      border: _border(dark),
                    ),
                  ),
                ),
                // Horizontally + vertically scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    controller: _vertBodyCtrl,
                    // Bug-2: bottom padding so the last row is scrollable
                    // above the Customize bar / onboarding footer.
                    padding: const EdgeInsets.only(bottom: _kScrollBottomPad),
                    child: SingleChildScrollView(
                      controller: _horizBodyCtrl,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: kDayOrder.map((day) {
                          // Phase A: pass only per-day data so only the
                          // affected column rebuilds when one lecture changes.
                          final dayLectures = editorData.lecturesForDay(day);
                          final dayConflicts = <String>{
                            for (final id in fullState.conflicts.keys)
                              if (dayLectures.any((l) => l.id == id)) id,
                          };
                          return _TimelineColumn(
                            key: _columnKeys[day],
                            day: day,
                            lectures: dayLectures,
                            conflictIds: dayConflicts,
                            isPlacementMode: fullState.ui.selectedSubjectId != null,
                            subjects: editorData.subjects,
                            columnHeight: columnHeight,
                            rangeStart: rangeStart,
                            dark: dark,
                            border: _border(dark),
                            surface: _surface(dark),
                            primary: _primary(dark),
                            // Phase C: reveal/collapse state
                            revealedId: _revealedId,
                            onTapDown: (localY) =>
                                _onColumnTap(day, localY, rangeStart, editorData),
                            onRevealBlock: _onRevealBlock,
                            onDeleteBlock: _onDeleteBlock,
                            onOpenBlockSheet: _onOpenBlockSheet,
                            onCollapseRevealed: _onCollapseRevealed,
                            // Phase D: drag state for this column
                            dragInfo: (_drag?.day == day) ? _drag : null,
                            onDragStart: (lecture) =>
                                _onDragStart(lecture, rangeStart),
                            onDragUpdate: (global) =>
                                _onDragUpdate(day, global, rangeStart),
                            onDragEnd: () => _onDragEnd(),
                            onDragCancel: () => _onDragCancel(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Footer CTA (onboarding only) ───────────────────────────────────
          if (widget.mode == TimetableGridMode.onboarding &&
              widget.onFinish != null)
            _FooterBar(
              dark: dark,
              onFinish: widget.onFinish!,
              primary: _primary(dark),
            ),
        ],
      ),
    );
  }

  // ── Interaction handlers ───────────────────────────────────────────────

  void _onColumnTap(
    String day,
    double localY,
    int rangeStart,
    TimetableEditorState data,
  ) {
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);
    final selectedId =
        ref.read(timetableEditorNotifierProvider).ui.selectedSubjectId;
    if (selectedId == null) return;

    // Phase B: use shared yToMinutes utility — single source of truth.
    final rawMin = yToMinutes(localY, rangeStart);
    // Snap to nearest 15 minutes
    final snapped = ((rawMin / _kMinSnapMinutes).round() * _kMinSnapMinutes)
        .clamp(rangeStart, rangeStart + (data.gridEndHour - data.gridStartHour) * 60 - 15);
    final h = snapped ~/ 60;
    final m = snapped % 60;
    final startTime =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    HapticFeedback.lightImpact();
    notifier.placeLectureAt(day, startTime).then((placed) {
      if (!placed) {
        // Slot is occupied — give a distinct haptic so the user knows
        HapticFeedback.mediumImpact();
      }
    });
  }

  // Phase C: Tap a collapsed block → reveal it.
  // Tap a revealed block (via _onRevealBlock again) → collapse it.
  void _onRevealBlock(LectureBlock lecture) {
    HapticFeedback.selectionClick();
    setState(() {
      _revealedId = (_revealedId == lecture.id) ? null : lecture.id;
    });
  }

  // Phase C: Cross (x) tapped — immediate delete, no dialog.
  void _onDeleteBlock(LectureBlock lecture) {
    HapticFeedback.mediumImpact();
    setState(() => _revealedId = null);
    ref.read(timetableEditorNotifierProvider.notifier).deleteLecture(lecture.id);
  }

  // Phase C: Revealed block body tapped — open full detail sheet.
  void _onOpenBlockSheet(LectureBlock lecture) {
    setState(() => _revealedId = null);
    HapticFeedback.selectionClick();
    final subject = ref.read(timetableEditorNotifierProvider).data.subjectById(lecture.subjectId);
    showCellBottomSheet(
      context: context,
      ref: ref,
      lecture: lecture,
      subject: subject,
    );
  }

  // Phase C: Tap anywhere outside a block — collapse the revealed block.
  void _onCollapseRevealed() {
    if (_revealedId != null) setState(() => _revealedId = null);
  }

  // ── Phase D: Drag handlers ────────────────────────────────────────────────

  /// Long-press began — haptic + record drag start.
  /// [initialGhostMins] is the lecture's current start so the ghost
  /// appears exactly where the block already is.
  void _onDragStart(LectureBlock lecture, int rangeStart) {
    HapticFeedback.mediumImpact();
    // Collapse any revealed block so the UI stays unambiguous during drag.
    setState(() {
      _revealedId = null;
      _drag = _DragInfo(
        lecture: lecture,
        day: lecture.day,
        ghostStartMins: lecture.startHour * 60 + lecture.startMinute,
      );
    });
  }

  /// Finger moved — re-run candidate snapping and update ghost position.
  void _onDragUpdate(String day, Offset globalPos, int rangeStart) {
    if (_drag == null) return;
    // Convert global finger position to local Y within the day column.
    final box = _columnKeys[day]?.currentContext?.findRenderObject()
        as RenderBox?;
    if (box == null) return;
    final localY = box.globalToLocal(globalPos).dy;
    final fingerMins = yToMinutes(localY, rangeStart);

    // Re-run candidate algorithm on the latest state.
    final state = ref.read(timetableEditorNotifierProvider);
    final rangeEnd = state.data.gridEndHour * 60;
    final candidate = _findBestCandidate(
      fingerMins: fingerMins,
      durationMinutes: _drag!.lecture.durationMinutes,
      lectures: state.data.lecturesForDay(day),
      excludeId: _drag!.lecture.id,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    if (candidate != _drag!.ghostStartMins) {
      setState(() => _drag!.ghostStartMins = candidate);
    }
  }

  /// Drag released — commit the ghost position as the new start time.
  void _onDragEnd() {
    if (_drag == null) return;
    final ghostMins = _drag!.ghostStartMins;
    final h = ghostMins ~/ 60;
    final m = ghostMins % 60;
    final newStart =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    HapticFeedback.lightImpact();
    ref.read(timetableEditorNotifierProvider.notifier).updateLectureTime(
          _drag!.lecture.id,
          startTime: newStart,
          durationMinutes: _drag!.lecture.durationMinutes,
        );
    setState(() => _drag = null);
  }

  /// Drag cancelled (finger lifted outside a valid target, scroll interrupted).
  void _onDragCancel() {
    if (_drag != null) setState(() => _drag = null);
  }
}

// ─── Time Label Column ────────────────────────────────────────────────────────

class _TimeLabelColumn extends StatelessWidget {
  const _TimeLabelColumn({
    required this.hourMarks,
    required this.columnHeight,
    required this.rangeStart,
    required this.dark,
    required this.labelColor,
    required this.border,
  });

  final List<int> hourMarks;
  final double columnHeight;
  final int rangeStart;
  final bool dark;
  final Color labelColor;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kLabelWidth,
      height: columnHeight,
      child: Stack(
        children: [
          // Right border line
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: border),
          ),
          // Hour labels positioned at their exact Y coordinate
          ...hourMarks.map((h) {
            final y = (h * 60 - rangeStart) * _kPxPerMinute;
            return Positioned(
              top: y - 8,
              left: 0,
              right: 6,
              child: Text(
                _formatHour(h),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
                textAlign: TextAlign.right,
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}

// ─── Timeline Column ──────────────────────────────────────────────────────────
// Phase A: receives only per-day data so only the affected column rebuilds.
// Phase C: receives revealedId + callbacks for the state machine.
// Phase D: receives dragInfo + drag callbacks; renders ghost + hover tint.

class _TimelineColumn extends StatelessWidget {
  const _TimelineColumn({
    super.key,
    required this.day,
    required this.lectures,
    required this.conflictIds,
    required this.isPlacementMode,
    required this.subjects,
    required this.columnHeight,
    required this.rangeStart,
    required this.dark,
    required this.border,
    required this.surface,
    required this.primary,
    required this.onTapDown,
    // Phase C callbacks
    required this.revealedId,
    required this.onRevealBlock,
    required this.onDeleteBlock,
    required this.onOpenBlockSheet,
    required this.onCollapseRevealed,
    // Phase D callbacks
    required this.dragInfo,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final String day;
  final List<LectureBlock> lectures;
  final Set<String> conflictIds;
  final bool isPlacementMode;
  final List<SubjectModel> subjects;
  final double columnHeight;
  final int rangeStart;
  final bool dark;
  final Color border;
  final Color surface;
  final Color primary;
  final void Function(double localY) onTapDown;
  // Phase C
  final String? revealedId;
  final void Function(LectureBlock) onRevealBlock;
  final void Function(LectureBlock) onDeleteBlock;
  final void Function(LectureBlock) onOpenBlockSheet;
  final VoidCallback onCollapseRevealed;
  // Phase D
  final _DragInfo? dragInfo;
  final void Function(LectureBlock) onDragStart;
  final void Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;

  SubjectModel? _subjectById(String id) {
    try {
      return subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedLectures = [...lectures]
      ..sort((a, b) => _startMins(a).compareTo(_startMins(b)));
    final isDragActive = dragInfo != null;

    return GestureDetector(
      // Placement mode: tap empty area to place lecture
      onTapDown: isPlacementMode
          ? (details) => onTapDown(details.localPosition.dy)
          : null,
      // Phase C: tap empty area (not on any block) collapses revealed block
      onTap: isPlacementMode ? null : onCollapseRevealed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _kCellWidth,
        height: columnHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── Background: column fill + drag hover tint ─────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _kCellWidth,
              height: columnHeight,
              color: isPlacementMode
                  ? (dark
                      ? const Color(0xFF1A1C25)
                      : const Color(0xFFF0F2FF))
                  : isDragActive
                      // Phase D: subtle tint while dragging in this column
                      ? (dark
                          ? const Color(0xFF1D1F2B)
                          : const Color(0xFFF3F4FF))
                      : surface,
            ),
            // Right border
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 0.5, color: border),
            ),

            // ── Background: hour separator lines ───────────────────────────
            CustomPaint(
              size: Size(_kCellWidth, columnHeight),
              painter: _HourLinePainter(
                rangeStartMins: rangeStart,
                rangeEndMins: rangeStart +
                    (columnHeight / _kPxPerMinute).round(),
                border: border,
              ),
            ),

            // ── Placement mode: "+ add" hint icon ──────────────────────────
            if (isPlacementMode && sortedLectures.isEmpty)
              Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: dark
                      ? const Color(0xFF434655)
                      : const Color(0xFFBBBFD9),
                ),
              ),

            // ── Lecture blocks ─────────────────────────────────────────────
            ...sortedLectures.map((lecture) {
              final subject = _subjectById(lecture.subjectId);
              final hasConflict = conflictIds.contains(lecture.id);
              final isRevealed = revealedId == lecture.id;
              final isDraggingThis = dragInfo?.lecture.id == lecture.id;

              final startMins = _startMins(lecture);
              // Phase B: use shared minutesToY utility
              final top = math.max(0.0, minutesToY(startMins, rangeStart));
              final height = math.max(
                  20.0, lecture.durationMinutes * _kPxPerMinute);

              // Contiguous same-subject block detection (suppress bottom border)
              final nextSameSubject = sortedLectures.firstWhereOrNull(
                (l) =>
                    l.subjectId == lecture.subjectId &&
                    l.startTime == lecture.endTime,
              );
              final suppressBottom = nextSameSubject != null;

              return Positioned(
                key: ValueKey(lecture.id),
                top: top,
                left: 1,
                right: 1,
                height: height,
                // Phase A: RepaintBoundary isolates each block's paint pass
                child: RepaintBoundary(
                  // Phase C: _BlockCell handles collapsed/revealed state machine
                  // Phase D: isDragging dims the block while it floats
                  child: _BlockCell(
                    lecture: lecture,
                    subject: subject,
                    hasConflict: hasConflict,
                    suppressBottom: suppressBottom,
                    dark: dark,
                    isRevealed: isRevealed,
                    isDragging: isDraggingThis,
                    blockHeight: height,
                    blockTop: top,
                    columnHeight: columnHeight,
                    onReveal: () => onRevealBlock(lecture),
                    onDelete: () => onDeleteBlock(lecture),
                    onOpenSheet: () => onOpenBlockSheet(lecture),
                    onDragStart: () => onDragStart(lecture),
                    onDragUpdate: onDragUpdate,
                    onDragEnd: onDragEnd,
                    onDragCancel: onDragCancel,
                  ),
                ),
              );
            }),

            // ── Phase D: Drag ghost (snapped candidate preview) ─────────────
            if (isDragActive) ...[
              Positioned(
                top: math.max(
                    0.0, minutesToY(dragInfo!.ghostStartMins, rangeStart)),
                left: 1,
                right: 1,
                height: math.max(
                    20.0,
                    dragInfo!.lecture.durationMinutes * _kPxPerMinute),
                child: IgnorePointer(
                  child: _DragGhost(
                    subject: _subjectById(dragInfo!.lecture.subjectId),
                    dark: dark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _startMins(LectureBlock l) =>
      l.startHour * 60 + l.startMinute;
}

// ─── Block Cell (Phase C/D state machine) ───────────────────────────────────────
//
// Phase C state machine: collapsed → revealed → cross-delete / edit-sheet.
// Phase D: long-press triggers LongPressDraggable instead of opening a sheet.
//   feedback  = _DragFeedback (floating tile that follows finger)
//   childWhenDragging = 35% opacity tile (stays in original position)
//   isDragging = true when THIS block is the one being dragged.

class _BlockCell extends StatelessWidget {
  const _BlockCell({
    required this.lecture,
    required this.subject,
    required this.hasConflict,
    required this.suppressBottom,
    required this.dark,
    required this.isRevealed,
    required this.isDragging,
    required this.blockHeight,
    required this.blockTop,
    required this.columnHeight,
    required this.onReveal,
    required this.onDelete,
    required this.onOpenSheet,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final LectureBlock lecture;
  final SubjectModel? subject;
  final bool hasConflict;
  final bool suppressBottom;
  final bool dark;
  final bool isRevealed;
  /// True when this block is currently being dragged (it floats as feedback).
  final bool isDragging;
  final double blockHeight;
  final double blockTop;
  final double columnHeight;
  final VoidCallback onReveal;
  final VoidCallback onDelete;
  final VoidCallback onOpenSheet;
  final VoidCallback onDragStart;
  final void Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;

  // A block shorter than this threshold (~25 min at 1.2 px/min) can't display
  // name + time + cross without clipping in revealed state.
  static const _kShortBlockThreshold = 30.0;
  // Minimum height of the revealed overlay for short blocks.
  static const _kRevealedMinHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    // When dragging, the block dims in-place; the floating feedback is shown
    // by LongPressDraggable separately.
    final tile = Opacity(
      opacity: isDragging ? 0.30 : 1.0,
      child: _LectureBlockTile(
        lecture: lecture,
        subject: subject,
        hasConflict: hasConflict,
        suppressBottom: suppressBottom,
        dark: dark,
        isRevealed: isRevealed && !isDragging,
        onDelete: (isRevealed && !isDragging) ? onDelete : null,
      ),
    );

    // Phase D: feedback widget that floats with the finger.
    final feedback = _DragFeedback(
      lecture: lecture,
      subject: subject,
      blockHeight: blockHeight,
    );

    Widget body;
    if (!isRevealed) {
      // Collapsed: tap → reveal.  Long-press → drag.
      body = GestureDetector(
        onTap: onReveal,
        behavior: HitTestBehavior.opaque,
        child: LongPressDraggable<LectureBlock>(
          data: lecture,
          delay: const Duration(milliseconds: 350),
          feedback: feedback,
          childWhenDragging: Opacity(opacity: 0.30, child: tile),
          onDragStarted: onDragStart,
          onDragUpdate: (d) => onDragUpdate(d.globalPosition),
          onDragEnd: (_) => onDragEnd(),
          onDraggableCanceled: (_, __) => onDragCancel(),
          child: tile,
        ),
      );
    } else {
      // Revealed: tap body → open detail sheet.  Long-press → drag.
      body = GestureDetector(
        onTap: onOpenSheet,
        behavior: HitTestBehavior.opaque,
        child: LongPressDraggable<LectureBlock>(
          data: lecture,
          delay: const Duration(milliseconds: 350),
          feedback: feedback,
          childWhenDragging: Opacity(opacity: 0.30, child: tile),
          onDragStarted: onDragStart,
          onDragUpdate: (d) => onDragUpdate(d.globalPosition),
          onDragEnd: (_) => onDragEnd(),
          onDraggableCanceled: (_, __) => onDragCancel(),
          child: tile,
        ),
      );
    }

    // Small-block overflow: allow revealed overlay to extend beyond the
    // Positioned bounds so content isn't clipped.
    if (blockHeight < _kShortBlockThreshold) {
      final spaceBelow = columnHeight - blockTop - blockHeight;
      final alignment = spaceBelow >= _kRevealedMinHeight - blockHeight
          ? Alignment.topLeft
          : Alignment.bottomLeft;
      body = OverflowBox(
        alignment: alignment,
        minHeight: _kRevealedMinHeight,
        maxHeight: _kRevealedMinHeight,
        minWidth: 0,
        maxWidth: double.infinity,
        child: body,
      );
    }

    return body;
  }
}

// ─── Lecture Block Tile ───────────────────────────────────────────────────────
// Phase C: accepts [isRevealed] to show time range + × icon in revealed state.

class _LectureBlockTile extends StatelessWidget {
  const _LectureBlockTile({
    required this.lecture,
    required this.subject,
    required this.hasConflict,
    required this.suppressBottom,
    required this.dark,
    required this.isRevealed,
    this.onDelete,
  });

  final LectureBlock lecture;
  final SubjectModel? subject;
  final bool hasConflict;
  final bool suppressBottom;
  final bool dark;
  final bool isRevealed;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = subject != null
        ? hexToColor(subject!.effectiveColorHex)
        : Colors.grey.shade400;
    final textColor = color.computeLuminance() > 0.35
        ? const Color(0xFF111318)
        : Colors.white;
    final dimText = textColor.withValues(alpha: 0.70);

    final borderRadius = BorderRadius.only(
      topLeft:     const Radius.circular(5),
      topRight:    const Radius.circular(5),
      bottomLeft:  suppressBottom ? Radius.zero : const Radius.circular(5),
      bottomRight: suppressBottom ? Radius.zero : const Radius.circular(5),
    );

    // SizedBox.expand() forces this widget to fill the Positioned block's
    // tight constraints. Without it, Container (no explicit height) +
    // Stack (loosens constraints → minHeight=0) + Column(max) would collapse
    // the Column to zero height, making the text invisible while the
    // DecoratedBox background still showed (explaining the "colored but blank" bug).
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: isRevealed
              ? color.withValues(alpha: 0.95)
              : color.withValues(alpha: 0.88),
          borderRadius: borderRadius,
          // IMPORTANT: borderRadius requires a uniform-colored Border.
          // Using different colors per side throws at paint time → blank tile.
          border: hasConflict
              ? Border.all(color: Colors.red.shade400, width: 1.5)
              : Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Subject name + time range ──────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(5, 4, isRevealed ? 18 : 5, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisSize.min: Stack loosens constraints (minHeight → 0),
                // so expanding would collapse to 0. SizedBox.expand() fills
                // the block; Column just wraps its content.
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subject short name — always shown.
                  Text(
                    subject?.effectiveShortName ?? '?',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Time range — shown when block >= 30 min or when revealed.
                  if (isRevealed || lecture.durationMinutes >= 30)
                    Text(
                      '${lecture.startTime}–${lecture.endTime}',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: dimText,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // ── Conflict icon ───────────────────────────────────────────────
            if (hasConflict && !isRevealed)
              Positioned(
                top: 3,
                right: 3,
                child: Icon(Icons.warning_amber_rounded,
                    size: 10, color: Colors.red.shade300),
              ),

            // ── × delete button (revealed only) ────────────────────────────
            if (isRevealed)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    child: Icon(Icons.close_rounded, size: 11, color: dimText),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/// The floating widget that follows the finger during a drag.
/// Rendered at 1.03× scale with elevation shadow to give a "lifted" feel.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({
    required this.lecture,
    required this.subject,
    required this.blockHeight,
  });

  final LectureBlock lecture;
  final SubjectModel? subject;
  final double blockHeight;

  @override
  Widget build(BuildContext context) {
    final color = subject != null
        ? hexToColor(subject!.effectiveColorHex)
        : Colors.grey.shade400;
    final textColor = color.computeLuminance() > 0.35
        ? const Color(0xFF111318)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.03,
        child: Container(
          width: _kCellWidth - 2,
          height: blockHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.40),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subject?.effectiveShortName ?? '?',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (blockHeight >= 24)
                Text(
                  '${lecture.startTime}–${lecture.endTime}',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: textColor.withValues(alpha: 0.75),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ghost block shown at the snapped candidate position during drag.
/// Uses an outlined style so it's clearly distinct from real blocks.
class _DragGhost extends StatelessWidget {
  const _DragGhost({
    required this.subject,
    required this.dark,
  });

  final SubjectModel? subject;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = subject != null
        ? hexToColor(subject!.effectiveColorHex)
        : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: 0.60),
          width: 1.5,
        ),
      ),
    );
  }
}

// ─── Hour Line Painter ──────────────────────────────────────────────────────────

class _HourLinePainter extends CustomPainter {
  const _HourLinePainter({
    required this.rangeStartMins,
    required this.rangeEndMins,
    required this.border,
  });

  final int rangeStartMins;
  final int rangeEndMins;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = border
      ..strokeWidth = 0.5;

    // Draw a horizontal line at each whole-hour boundary
    final startHour = (rangeStartMins / 60).ceil();
    final endHour   = (rangeEndMins   / 60).floor();
    for (int h = startHour; h <= endHour; h++) {
      final y = (h * 60 - rangeStartMins) * _kPxPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw a subtler 30-min half-hour line
    final halfPaint = Paint()
      ..color = border.withValues(alpha: 0.4)
      ..strokeWidth = 0.3;
    for (int h = startHour; h < endHour; h++) {
      final y = (h * 60 + 30 - rangeStartMins) * _kPxPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), halfPaint);
    }
  }

  @override
  bool shouldRepaint(_HourLinePainter old) =>
      old.rangeStartMins != rangeStartMins ||
      old.rangeEndMins != rangeEndMins ||
      old.border != border;
}

// ─── Day Header Cell ──────────────────────────────────────────────────────────

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({
    required this.day,
    required this.hasLectures,
    required this.dark,
    required this.textColor,
    required this.border,
    required this.surface,
    required this.accent,
  });

  final String day;
  final bool hasLectures;
  final bool dark;
  final Color textColor;
  final Color border;
  final Color surface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kCellWidth,
      height: _kHeaderHeight,
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(color: border),
          right:  BorderSide(color: border, width: 0.5),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: hasLectures ? accent : textColor,
              ),
            ),
            if (hasLectures)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer Bar (onboarding only) ────────────────────────────────────────────

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.dark,
    required this.onFinish,
    required this.primary,
  });

  final bool dark;
  final VoidCallback onFinish;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E2028) : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Finish Setup →',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Extension helpers ────────────────────────────────────────────────────────

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
