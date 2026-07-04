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
                            onBlockLongPress: _onBlockLongPress,
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

  // Long-press: retained until Phase D replaces it with drag.
  // Never called when in placement mode (column handler takes precedence).
  void _onBlockLongPress(LectureBlock lecture) {
    HapticFeedback.mediumImpact();
    final state = ref.read(timetableEditorNotifierProvider);
    final subject = state.data.subjectById(lecture.subjectId);
    showCellBottomSheet(
      context: context,
      ref: ref,
      lecture: lecture,
      subject: subject,
    );
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

class _TimelineColumn extends StatelessWidget {
  const _TimelineColumn({
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
    required this.onBlockLongPress,
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
  final void Function(LectureBlock) onBlockLongPress;

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
            // ── Background: column fill + right border ─────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _kCellWidth,
              height: columnHeight,
              color: isPlacementMode
                  ? (dark
                      ? const Color(0xFF1A1C25)
                      : const Color(0xFFF0F2FF))
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
                  child: _BlockCell(
                    lecture: lecture,
                    subject: subject,
                    hasConflict: hasConflict,
                    suppressBottom: suppressBottom,
                    dark: dark,
                    isRevealed: isRevealed,
                    blockHeight: height,
                    blockTop: top,
                    columnHeight: columnHeight,
                    onReveal: () => onRevealBlock(lecture),
                    onDelete: () => onDeleteBlock(lecture),
                    onOpenSheet: () => onOpenBlockSheet(lecture),
                    onLongPress: () => onBlockLongPress(lecture),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  int _startMins(LectureBlock l) =>
      l.startHour * 60 + l.startMinute;
}

// ─── Block Cell (Phase C state machine) ────────────────────────────────────────

class _BlockCell extends StatelessWidget {
  const _BlockCell({
    required this.lecture,
    required this.subject,
    required this.hasConflict,
    required this.suppressBottom,
    required this.dark,
    required this.isRevealed,
    required this.blockHeight,
    required this.blockTop,
    required this.columnHeight,
    required this.onReveal,
    required this.onDelete,
    required this.onOpenSheet,
    required this.onLongPress,
  });

  final LectureBlock lecture;
  final SubjectModel? subject;
  final bool hasConflict;
  final bool suppressBottom;
  final bool dark;
  final bool isRevealed;
  final double blockHeight;
  final double blockTop;
  final double columnHeight;
  final VoidCallback onReveal;
  final VoidCallback onDelete;
  final VoidCallback onOpenSheet;
  final VoidCallback onLongPress;

  // A block shorter than this threshold (~25 min at 1.2 px/min) can't display
  // name + time + cross without clipping in revealed state.
  static const _kShortBlockThreshold = 30.0;
  // Minimum height of the revealed overlay for short blocks.
  static const _kRevealedMinHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final tile = _LectureBlockTile(
      lecture: lecture,
      subject: subject,
      hasConflict: hasConflict,
      suppressBottom: suppressBottom,
      dark: dark,
      isRevealed: isRevealed,
      onDelete: isRevealed ? onDelete : null,
    );

    if (!isRevealed) {
      // Collapsed: tap reveals, long-press opens detail sheet.
      return GestureDetector(
        onTap: onReveal,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: tile,
      );
    }

    // Revealed: body tap opens sheet, long-press opens sheet.
    // The × icon GestureDetector lives inside _LectureBlockTile and is
    // handled first (innermost wins in Flutter's gesture arena).
    Widget body = GestureDetector(
      onTap: onOpenSheet,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: tile,
    );

    // Small-block overflow: allow revealed overlay to extend beyond the
    // Positioned bounds so content isn't clipped.
    if (blockHeight < _kShortBlockThreshold) {
      // Prefer overflowing downward; near column bottom, overflow upward.
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

// ─── Lecture Block Tile ──────────────────────────────────────────────────────────────
// Phase C: accepts [isRevealed] to show time range + × icon in revealed state.
// The × icon has its OWN GestureDetector with HitTestBehavior.opaque so that
// tapping it fires [onDelete] and does NOT propagate to the body tap handler
// in _BlockCell (innermost GestureDetector wins in Flutter's gesture arena).

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

    return Container(
      decoration: BoxDecoration(
        // Revealed: slightly brighter fill to signal the active state.
        color: isRevealed
            ? color.withValues(alpha: 0.97)
            : color.withValues(alpha: 0.88),
        borderRadius: borderRadius,
        border: hasConflict
            ? Border.all(color: Colors.red.shade400, width: 1.5)
            : Border(
                top:   BorderSide(color: color, width: 1),
                left:  BorderSide(color: color.withValues(alpha: 0.6), width: 0.5),
                right: BorderSide(color: color.withValues(alpha: 0.6), width: 0.5),
                bottom: suppressBottom
                    ? BorderSide.none
                    : BorderSide(color: color.withValues(alpha: 0.6), width: 0.5),
              ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Content: name + time range ──────────────────────────────────────
          Padding(
            // Right padding widens to make room for × when revealed
            padding: EdgeInsets.fromLTRB(5, 4, isRevealed ? 18 : 5, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                // In revealed state: always show time range.
                // In collapsed state: show only if block >= 30 min tall.
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

          // ── Conflict warning icon (only in collapsed state) ─────────────────
          // In revealed state the × icon takes this corner instead.
          if (hasConflict && !isRevealed)
            Positioned(
              top: 3,
              right: 3,
              child: Icon(
                Icons.warning_amber_rounded,
                size: 10,
                color: Colors.red.shade300,
              ),
            ),

          // ── Revealed: × delete button ─────────────────────────────────────
          // Innermost GestureDetector: wins the gesture arena, so this tap
          // NEVER also triggers the block-body tap handler in _BlockCell.
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
                  child: Icon(
                    Icons.close_rounded,
                    size: 11,
                    color: dimText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Hour Line Painter ────────────────────────────────────────────────────────

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
