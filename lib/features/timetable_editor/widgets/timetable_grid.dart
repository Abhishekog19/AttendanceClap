/// TimetableGrid — Time-Continuous Weekly Grid
///
/// Used in both onboarding and edit modes. Mode only affects surrounding chrome.
///
/// Layout:
///   • Sticky time-label column (left)
///   • Sticky day-header row (top)
///   • Each row = 1 hour (gridStartHour to gridEndHour)
///   • Adjacent same-subject cells rendered as merged vertical block
///   • Subject library strip pinned below header
///
/// Cell interactions:
///   • Tap empty cell → place selected subject
///   • Tap occupied cell → quick popup (time, remove)
///   • Long-press occupied cell → detail sheet (time picker, duration, notes)
library;

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

const _kHourRowHeight = 56.0;    // height of each hour row
const _kCellWidth = 90.0;        // width of each day column
const _kLabelWidth = 52.0;       // sticky time-label column
const _kHeaderHeight = 48.0;     // sticky day-header row

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
  final _vertCtrl = ScrollController();
  final _horizBodyCtrl = ScrollController();
  final _horizHeaderCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizBodyCtrl.addListener(_syncScroll);
  }

  void _syncScroll() {
    if (_horizBodyCtrl.hasClients && _horizHeaderCtrl.hasClients) {
      if (_horizHeaderCtrl.offset != _horizBodyCtrl.offset) {
        _horizHeaderCtrl.jumpTo(_horizBodyCtrl.offset);
      }
    }
  }

  @override
  void dispose() {
    _horizBodyCtrl.removeListener(_syncScroll);
    _vertCtrl.dispose();
    _horizBodyCtrl.dispose();
    _horizHeaderCtrl.dispose();
    super.dispose();
  }

  // ── Colours ────────────────────────────────────────────────────────────────

  Color _bg(bool dark) => dark ? const Color(0xFF111318) : const Color(0xFFF7F7FB);
  Color _surface(bool dark) => dark ? const Color(0xFF1E2028) : Colors.white;
  Color _border(bool dark) => dark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED);
  Color _labelColor(bool dark) => dark ? const Color(0xFF8B8FA8) : const Color(0xFF8990B0);
  Color _headerText(bool dark) => dark ? Colors.white : const Color(0xFF191B23);
  Color _primaryColor(bool dark) => dark ? const Color(0xFFB4C5FF) : const Color(0xFF4F5EFF);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fullState = ref.watch(timetableEditorNotifierProvider);
    final editorData = fullState.data;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hours = editorData.hourRows;

    return ColoredBox(
      color: _bg(dark),
      child: Column(
        children: [
          // ── Subject library strip ────────────────────────────────────────
          SubjectLibraryStrip(
            onAddSubjectTap: widget.onAddSubjectTap,
          ),

          // ── Header row (day labels) ──────────────────────────────────────
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
                        right: BorderSide(color: _border(dark)),
                      ),
                    ),
                  ),
                ),
                // Day headers (horizontally synced with body)
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
                          accent: _primaryColor(dark),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Grid body (scrollable) ───────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sticky time-label column
                SizedBox(
                  width: _kLabelWidth,
                  child: SingleChildScrollView(
                    controller: _vertCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: hours.map((h) => _TimeLabelCell(
                        hour: h,
                        dark: dark,
                        labelColor: _labelColor(dark),
                        border: _border(dark),
                      )).toList(),
                    ),
                  ),
                ),
                // Scrollable day-columns
                Expanded(
                  child: SingleChildScrollView(
                    controller: _vertCtrl,
                    child: SingleChildScrollView(
                      controller: _horizBodyCtrl,
                      scrollDirection: Axis.horizontal,
                      child: _GridBody(
                        fullState: fullState,
                        hours: hours,
                        dark: dark,
                        border: _border(dark),
                        surface: _surface(dark),
                        onCellTap: _onCellTap,
                        onCellLongPress: _onCellLongPress,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Footer CTA ──────────────────────────────────────────────────
          if (widget.onFinish != null) _FooterBar(
            mode: widget.mode,
            dark: dark,
            onFinish: widget.onFinish!,
            primary: _primaryColor(dark),
          ),
        ],
      ),
    );
  }

  // ── Cell interactions ─────────────────────────────────────────────────────

  void _onCellTap(String day, int hour, LectureBlock? existing) {
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);

    if (existing != null) {
      // Tap on occupied cell → quick remove popup
      HapticFeedback.selectionClick();
      _showQuickPopup(day: day, lecture: existing);
    } else {
      // Tap empty cell → place subject if one is selected
      final selectedId = ref.read(timetableEditorNotifierProvider).ui.selectedSubjectId;
      if (selectedId != null) {
        HapticFeedback.lightImpact();
        notifier.placeLecture(day, hour);
      }
    }
  }

  void _onCellLongPress(String day, int hour, LectureBlock lecture) {
    HapticFeedback.mediumImpact();
    _showDetailSheet(lecture: lecture);
  }

  void _showQuickPopup({
    required String day,
    required LectureBlock lecture,
  }) {
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

  void _showDetailSheet({required LectureBlock lecture}) {
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

// ─── Grid Body ────────────────────────────────────────────────────────────────

class _GridBody extends StatelessWidget {
  const _GridBody({
    required this.fullState,
    required this.hours,
    required this.dark,
    required this.border,
    required this.surface,
    required this.onCellTap,
    required this.onCellLongPress,
  });

  final TimetableEditorFullState fullState;
  final List<int> hours;
  final bool dark;
  final Color border;
  final Color surface;
  final void Function(String day, int hour, LectureBlock? existing) onCellTap;
  final void Function(String day, int hour, LectureBlock lecture) onCellLongPress;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: kDayOrder.map((day) {
        return _DayColumn(
          day: day,
          fullState: fullState,
          hours: hours,
          dark: dark,
          border: border,
          surface: surface,
          onCellTap: onCellTap,
          onCellLongPress: onCellLongPress,
        );
      }).toList(),
    );
  }
}

// ─── Day Column ───────────────────────────────────────────────────────────────

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.fullState,
    required this.hours,
    required this.dark,
    required this.border,
    required this.surface,
    required this.onCellTap,
    required this.onCellLongPress,
  });

  final String day;
  final TimetableEditorFullState fullState;
  final List<int> hours;
  final bool dark;
  final Color border;
  final Color surface;
  final void Function(String day, int hour, LectureBlock? existing) onCellTap;
  final void Function(String day, int hour, LectureBlock lecture) onCellLongPress;

  @override
  Widget build(BuildContext context) {
    final data = fullState.data;
    final selectedSubjectId = fullState.ui.selectedSubjectId;

    return SizedBox(
      width: _kCellWidth,
      child: Column(
        children: hours.map((hour) {
          final lecture = data.lectureAtHour(day, hour);
          final isStartHour = lecture != null && lecture.startHour == hour;
          final isInMultiHour = lecture != null && !isStartHour;
          final hasConflict = lecture != null &&
              fullState.conflicts.containsKey(lecture.id);
          final subject = lecture != null ? data.subjectById(lecture.subjectId) : null;
          final isPlacementMode = selectedSubjectId != null;

          if (isInMultiHour) {
            // Interior of a multi-hour block — render blank continuation
            return _ContinuationCell(
              height: _kHourRowHeight,
              color: subject != null
                  ? hexToColor(subject.effectiveColorHex).withValues(alpha: 0.85)
                  : Colors.grey.shade300,
              border: border,
              dark: dark,
            );
          }

          return _HourCell(
            height: _kHourRowHeight,
            lecture: lecture,
            subject: subject,
            hasConflict: hasConflict,
            isPlacementMode: isPlacementMode,
            dark: dark,
            border: border,
            surface: surface,
            onTap: () => onCellTap(day, hour, lecture),
            onLongPress: lecture != null
                ? () => onCellLongPress(day, hour, lecture)
                : null,
          );
        }).toList(),
      ),
    );
  }
}

// ─── Hour Cell ────────────────────────────────────────────────────────────────

class _HourCell extends StatelessWidget {
  const _HourCell({
    required this.height,
    required this.lecture,
    required this.subject,
    required this.hasConflict,
    required this.isPlacementMode,
    required this.dark,
    required this.border,
    required this.surface,
    required this.onTap,
    this.onLongPress,
  });

  final double height;
  final LectureBlock? lecture;
  final SubjectModel? subject;
  final bool hasConflict;
  final bool isPlacementMode;
  final bool dark;
  final Color border;
  final Color surface;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isEmpty = lecture == null;

    // Empty cell appearance
    if (isEmpty) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          width: _kCellWidth,
          decoration: BoxDecoration(
            color: isPlacementMode
                ? (dark
                    ? const Color(0xFF282A34)
                    : const Color(0xFFF0F2FF))
                : surface,
            border: Border.all(
              color: border,
              width: 0.5,
            ),
          ),
          child: isPlacementMode
              ? Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: dark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFCCCFE8),
                  ),
                )
              : null,
        ),
      );
    }

    // Occupied cell
    final color = subject != null
        ? hexToColor(subject!.effectiveColorHex)
        : Colors.grey.shade400;
    final textColor = _contrastColor(color);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        width: _kCellWidth,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          border: hasConflict
              ? Border.all(
                  color: Colors.red.shade400,
                  width: 2,
                )
              : Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 0.5,
                ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  subject?.effectiveShortName ?? '?',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasConflict)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: Colors.red.shade300,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.35 ? const Color(0xFF111318) : Colors.white;
  }
}

// ─── Continuation Cell (interior of multi-hour block) ────────────────────────

class _ContinuationCell extends StatelessWidget {
  const _ContinuationCell({
    required this.height,
    required this.color,
    required this.border,
    required this.dark,
  });

  final double height;
  final Color color;
  final Color border;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: _kCellWidth,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.4), width: 0.5),
          right: BorderSide(color: color.withValues(alpha: 0.4), width: 0.5),
          bottom: BorderSide(color: color.withValues(alpha: 0.6), width: 0.5),
        ),
      ),
    );
  }
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
          right: BorderSide(color: border, width: 0.5),
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

// ─── Time Label Cell ──────────────────────────────────────────────────────────

class _TimeLabelCell extends StatelessWidget {
  const _TimeLabelCell({
    required this.hour,
    required this.dark,
    required this.labelColor,
    required this.border,
  });

  final int hour;
  final bool dark;
  final Color labelColor;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final label = _formatHour(hour);
    return Container(
      height: _kHourRowHeight,
      width: _kLabelWidth,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: border, width: 0.5),
          right: BorderSide(color: border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 4, top: 6),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
          textAlign: TextAlign.right,
        ),
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

// ─── Footer Bar ──────────────────────────────────────────────────────────────

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.mode,
    required this.dark,
    required this.onFinish,
    required this.primary,
  });

  final TimetableGridMode mode;
  final bool dark;
  final VoidCallback onFinish;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final label = mode == TimetableGridMode.onboarding
        ? 'Finish Setup →'
        : 'Done';

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
              label,
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
