/// Cell Bottom Sheet
///
/// Shown when the user taps an occupied timetable cell.
/// Contains: subject, duration stepper, faculty, classroom, notes,
/// duplicate, move, and delete actions (Section 6).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';


void showCellBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LectureBlock lecture,
  required TimetableSubject subject,
  required List<PeriodSlot> dayPeriods,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CellBottomSheet(
      lecture: lecture,
      subject: subject,
      dayPeriods: dayPeriods,
      ref: ref,
    ),
  );
}

class CellBottomSheet extends ConsumerStatefulWidget {
  const CellBottomSheet({
    super.key,
    required this.lecture,
    required this.subject,
    required this.dayPeriods,
    required this.ref,
  });

  final LectureBlock lecture;
  final TimetableSubject subject;
  final List<PeriodSlot> dayPeriods;
  final WidgetRef ref;

  @override
  ConsumerState<CellBottomSheet> createState() => _CellBottomSheetState();
}

class _CellBottomSheetState extends ConsumerState<CellBottomSheet> {
  late int _spanPeriods;
  late TextEditingController _facultyCtrl;
  late TextEditingController _classroomCtrl;
  late TextEditingController _notesCtrl;
  bool _isLab = false;

  @override
  void initState() {
    super.initState();
    _spanPeriods = widget.lecture.spanPeriods;
    _isLab = widget.lecture.isLab;
    _facultyCtrl =
        TextEditingController(text: widget.lecture.facultyName ?? '');
    _classroomCtrl =
        TextEditingController(text: widget.lecture.classroom ?? '');
    _notesCtrl = TextEditingController(text: widget.lecture.notes ?? '');
  }

  @override
  void dispose() {
    _facultyCtrl.dispose();
    _classroomCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _maxSpan {
    final periods = widget.dayPeriods;
    final startIdx = periods.indexWhere((p) => p.id == widget.lecture.startPeriodId);
    if (startIdx == -1) return 1;
    return periods.length - startIdx;
  }

  void _save() {
    ref.read(timetableEditorNotifierProvider.notifier).updateLecture(
      widget.lecture.id,
      spanPeriods: _spanPeriods,
      facultyName: _facultyCtrl.text.trim().isEmpty
          ? null
          : _facultyCtrl.text.trim(),
      classroom: _classroomCtrl.text.trim().isEmpty
          ? null
          : _classroomCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isLab: _isLab,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);
    // surface intentionally unused (kept for consistency)
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final border = isDark ? const Color(0xFF434655) : const Color(0xFFDDDDDD);
    final primaryColor =
        isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);
    final subjectColor = hexToColor(widget.subject.colorHex);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            // Subject header
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: subjectColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.subject.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
                // Change subject
                TextButton(
                  onPressed: () => _openSubjectPicker(context),
                  child: Text('Change',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duration stepper
            _SectionHeader('Duration', secondary),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$_spanPeriods period${_spanPeriods > 1 ? 's' : ''}${_isLab ? ' (Lab)' : ''}',
                    style:
                        GoogleFonts.inter(fontSize: 14, color: onSurface),
                  ),
                ),
                Row(
                  children: [
                    _StepBtn(
                      icon: Icons.remove_rounded,
                      enabled: _spanPeriods > 1,
                      primaryColor: primaryColor,
                      secondary: secondary,
                      surface: surface,
                      onTap: () => setState(() => _spanPeriods--),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_spanPeriods',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: onSurface),
                      ),
                    ),
                    _StepBtn(
                      icon: Icons.add_rounded,
                      enabled: _spanPeriods < _maxSpan,
                      primaryColor: primaryColor,
                      secondary: secondary,
                      surface: surface,
                      onTap: () => setState(() => _spanPeriods++),
                    ),
                  ],
                ),
              ],
            ),
            if (_spanPeriods >= _maxSpan)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No more periods after the last one on this day',
                  style: GoogleFonts.inter(fontSize: 11, color: secondary),
                ),
              ),
            const SizedBox(height: 8),
            // Lab toggle
            Row(
              children: [
                Text('Mark as Lab',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onSurface)),
                const Spacer(),
                Switch(
                  value: _isLab,
                  onChanged: (v) => setState(() => _isLab = v),
                  activeThumbColor: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Faculty
            _OptionalField(
              label: 'Faculty (optional)',
              controller: _facultyCtrl,
              isDark: isDark,
              onSurface: onSurface,
              secondary: secondary,
              surface: surface,
              border: border,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 10),

            // Classroom
            _OptionalField(
              label: 'Classroom (optional)',
              controller: _classroomCtrl,
              isDark: isDark,
              onSurface: onSurface,
              secondary: secondary,
              surface: surface,
              border: border,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 10),

            // Notes
            _OptionalField(
              label: 'Notes (optional)',
              controller: _notesCtrl,
              isDark: isDark,
              onSurface: onSurface,
              secondary: secondary,
              surface: surface,
              border: border,
              primaryColor: primaryColor,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Action buttons row
            Row(
              children: [
                _ActionChip(
                  icon: Icons.copy_rounded,
                  label: 'Duplicate',
                  color: primaryColor,
                  surface: surface,
                  onTap: () {
                    Navigator.of(context).pop();
                    ref
                        .read(timetableEditorNotifierProvider.notifier)
                        .duplicateLecture(widget.lecture.id);
                  },
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.open_with_rounded,
                  label: 'Move',
                  color: primaryColor,
                  surface: surface,
                  onTap: () {
                    Navigator.of(context).pop();
                    final notifier =
                        ref.read(timetableEditorNotifierProvider.notifier);
                    notifier.startMoveLecture(widget.lecture.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor:
                      isDark ? const Color(0xFF002576) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),

            // Delete button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final notifier =
                      ref.read(timetableEditorNotifierProvider.notifier);
                  notifier.deleteLecture(widget.lecture.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.subject.shortName} removed',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => notifier.undo(),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                child: Text('Delete Lecture',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFBA1A1A),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubjectPicker(BuildContext context) {
    Navigator.of(context).pop();
    // Re-open placement mode — user taps the cell again to confirm new subject
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectPickerSheet(
        lectureId: widget.lecture.id,
        widgetRef: widget.ref,
      ),
    );
  }
}

// ─── Subject picker (for "Change Subject") ────────────────────────────────────

class _SubjectPickerSheet extends ConsumerWidget {
  const _SubjectPickerSheet(
      {required this.lectureId, required this.widgetRef});
  final String lectureId;
  final WidgetRef widgetRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timetableEditorNotifierProvider);
    final subjects = state.data.subjects;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final border = isDark ? const Color(0xFF434655) : const Color(0xFFDDDDDD);


    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration:
                  BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Change Subject',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: onSurface)),
          const SizedBox(height: 12),
          ...subjects.map((s) {
            final color = hexToColor(s.colorHex);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(s.shortName,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              title: Text(s.name,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurface)),
              onTap: () {
                Navigator.of(context).pop();
                ref
                    .read(timetableEditorNotifierProvider.notifier)
                    .updateLecture(lectureId, subjectId: s.id);
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5),
      );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.primaryColor,
    required this.secondary,
    required this.surface,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color primaryColor;
  final Color secondary;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? primaryColor : secondary.withAlpha(80),
          ),
        ),
      );
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      );
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.onSurface,
    required this.secondary,
    required this.surface,
    required this.border,
    required this.primaryColor,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color onSurface;
  final Color secondary;
  final Color surface;
  final Color border;
  final Color primaryColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 14, color: onSurface),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: secondary),
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
      );
}
