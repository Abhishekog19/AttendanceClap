/// Cell Bottom Sheet
///
/// Phase C: the quick-remove path (isQuick=true) has been removed.
/// Quick-remove is now the inline × button on each block.
/// This function always shows the full detail sheet:
/// start time picker (with overlap warning), duration stepper, notes, delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/subject_model.dart';
import '../../../data/repositories/subject_repository.dart';
import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

/// Opens the full lecture detail sheet for [lecture].
/// Phase C: [isQuick] path removed — the × inline button handles quick-remove.
Future<void> showCellBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LectureBlock lecture,
  required SubjectModel? subject,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DetailSheet(
      lecture: lecture,
      subject: subject,
      ref: ref,
    ),
  );
}

// ─── Detail Sheet ─────────────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({
    required this.lecture,
    required this.subject,
    required this.ref,
  });

  final LectureBlock lecture;
  final SubjectModel? subject;
  final WidgetRef ref;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late String _startTime;
  late int _durationMinutes;
  late TextEditingController _notesCtrl;
  String? _selectedColor;
  bool _saving = false;
  // Phase C: overlap warning — shown when the user picks a time that
  // conflicts with another lecture on the same day.
  String? _overlapWarning;

  @override
  void initState() {
    super.initState();
    _startTime = widget.lecture.startTime;
    _durationMinutes = widget.lecture.durationMinutes;
    _notesCtrl = TextEditingController(text: widget.lecture.notes ?? '');
    _selectedColor = widget.subject?.colorHex;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final parts = _startTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final newStart =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _startTime = newStart;
        _overlapWarning = _checkOverlap(newStart, _durationMinutes);
      });
    }
  }

  // Phase C: check if a proposed [startTime, startTime+duration] range
  // overlaps any other lecture on the same day (excluding this lecture itself).
  String? _checkOverlap(String startTime, int durationMinutes) {
    final state = widget.ref.read(timetableEditorNotifierProvider);
    final lectures = state.data.lecturesForDay(widget.lecture.day);
    final parts = startTime.split(':');
    final newStart = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final newEnd = newStart + durationMinutes;
    for (final l in lectures) {
      if (l.id == widget.lecture.id) continue; // skip self
      final lStart = l.startHour * 60 + l.startMinute;
      final lEnd = lStart + l.durationMinutes;
      if (newStart < lEnd && lStart < newEnd) {
        final subject = state.data.subjectById(l.subjectId);
        final name = subject?.effectiveShortName ?? l.subjectId;
        return 'Overlaps with $name (${l.startTime}–${l.endTime})';
      }
    }
    return null;
  }

  String get _endTime {
    final parts = _startTime.split(':');
    final startMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endMins = (startMins + _durationMinutes) % (24 * 60);
    return '${(endMins ~/ 60).toString().padLeft(2, '0')}:${(endMins % 60).toString().padLeft(2, '0')}';
  }
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Save lecture details
      await widget.ref
          .read(timetableEditorNotifierProvider.notifier)
          .updateLectureDetails(
            widget.lecture.id,
            startTime: _startTime,
            durationMinutes: _durationMinutes,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      // Save color change if subject exists and color changed
      final subject = widget.subject;
      if (subject != null &&
          _selectedColor != null &&
          _selectedColor != subject.colorHex) {
        final updated = subject.copyWith(colorHex: _selectedColor);
        await widget.ref
            .read(subjectRepositoryProvider)
            .updateSubject(updated);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF191B23);
    final secondary = isDark ? const Color(0xFF8B8FA8) : const Color(0xFF8990B0);
    final primary = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF4F5EFF);
    final border = isDark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED);
    final name = widget.subject?.name ?? 'Unknown';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                // Start time picker
                _DetailRow(
                  label: 'Start',
                  dark: isDark,
                  secondary: secondary,
                  border: border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _overlapWarning != null
                                  ? Colors.red.shade400
                                  : border,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _startTime,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ),
                      ),
                      if (_overlapWarning != null) ...[  
                        const SizedBox(height: 4),
                        Text(
                          _overlapWarning!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Duration stepper
                _DetailRow(
                  label: 'Duration',
                  dark: isDark,
                  secondary: secondary,
                  border: border,
                  child: Row(
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (_durationMinutes > 15) {
                            setState(() => _durationMinutes -= 15);
                          }
                        },
                        dark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_durationMinutes min',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        onTap: () {
                          if (_durationMinutes < 300) {
                            setState(() => _durationMinutes += 15);
                          }
                        },
                        dark: isDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '→ $_endTime',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Notes
                TextField(
                  controller: _notesCtrl,
                  style: GoogleFonts.inter(fontSize: 14, color: onSurface),
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)',
                    hintStyle: GoogleFonts.inter(color: secondary),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primary),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF111318)
                        : const Color(0xFFF7F7FB),
                  ),
                ),
                const SizedBox(height: 20),
                // Save / Delete buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.ref
                              .read(timetableEditorNotifierProvider.notifier)
                              .deleteLecture(widget.lecture.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.child,
    required this.dark,
    required this.secondary,
    required this.border,
  });

  final String label;
  final Widget child;
  final bool dark;
  final Color secondary;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.dark,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF282A34) : const Color(0xFFF0F2FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16,
            color: dark ? Colors.white70 : const Color(0xFF4F5EFF)),
      ),
    );
  }
}
