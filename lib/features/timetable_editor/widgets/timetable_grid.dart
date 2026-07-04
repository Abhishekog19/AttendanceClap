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
                            onTapDown: (localY) =>
                                _onColumnTap(day, localY, rangeStart, editorData),
                            onBlockTap: (lecture) => _onBlockTap(lecture),
                            onBlockLongPress: (lecture) =>
                                _onBlockLongPress(lecture),
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

  // ── Interaction handlers ──────────────────────────────────────────────────

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

  void _onBlockTap(LectureBlock lecture) {
    HapticFeedback.selectionClick();
    final state = ref.read(timetableEditorNotifierProvider);
    final subject = state.data.subjectById(lecture.subjectId);
    showCellBottomSheet(
      context: context,
      ref: ref,
      lecture: lecture,
      subject: subject,
      isQuick: true,
    );
  }

  void _onBlockLongPress(LectureBlock lecture) {
    HapticFeedback.mediumImpact();
    final state = ref.read(timetableEditorNotifierProvider);
    final subject = state.data.subjectById(lecture.subjectId);
    showCellBottomSheet(
      context: context,
      ref: ref,
      lecture: lecture,
      subject: subject,
      isQuick: false,
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
    required this.onBlockTap,
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
  final void Function(LectureBlock) onBlockTap;
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
      onTapDown: isPlacementMode
          ? (details) => onTapDown(details.localPosition.dy)
          : null,
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
                  child: GestureDetector(
                    onTap: () => onBlockTap(lecture),
                    onLongPress: () => onBlockLongPress(lecture),
                    behavior: HitTestBehavior.opaque,
                    child: _LectureBlockTile(
                      lecture: lecture,
                      subject: subject,
                      hasConflict: hasConflict,
                      suppressBottom: suppressBottom,
                      dark: dark,
                    ),
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

// ─── Lecture Block Tile ───────────────────────────────────────────────────────

class _LectureBlockTile extends StatelessWidget {
  const _LectureBlockTile({
    required this.lecture,
    required this.subject,
    required this.hasConflict,
    required this.suppressBottom,
    required this.dark,
  });

  final LectureBlock lecture;
  final SubjectModel? subject;
  final bool hasConflict;
  final bool suppressBottom;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = subject != null
        ? hexToColor(subject!.effectiveColorHex)
        : Colors.grey.shade400;
    final textColor = color.computeLuminance() > 0.35
        ? const Color(0xFF111318)
        : Colors.white;

    final borderRadius = BorderRadius.only(
      topLeft:     const Radius.circular(5),
      topRight:    const Radius.circular(5),
      bottomLeft:  suppressBottom ? Radius.zero : const Radius.circular(5),
      bottomRight: suppressBottom ? Radius.zero : const Radius.circular(5),
    );

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 4, 5, 2),
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
                if (lecture.durationMinutes >= 30)
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
          if (hasConflict)
            Positioned(
              top: 3,
              right: 3,
              child: Icon(
                Icons.warning_amber_rounded,
                size: 10,
                color: Colors.red.shade300,
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
