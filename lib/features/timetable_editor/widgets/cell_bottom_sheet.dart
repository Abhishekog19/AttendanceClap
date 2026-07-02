/// Cell Bottom Sheet
///
/// Two modes:
///   isQuick=true  — lightweight tap popup: shows subject name, time, Remove button
///   isQuick=false — full long-press sheet: time picker, duration, notes, Delete
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/subject_model.dart';
import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

Future<void> showCellBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LectureBlock lecture,
  required SubjectModel? subject,
  required bool isQuick,
}) {
  if (isQuick) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickSheet(
        lecture: lecture,
        subject: subject,
        ref: ref,
      ),
    );
  }
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

// ─── Quick Sheet ──────────────────────────────────────────────────────────────

class _QuickSheet extends StatelessWidget {
  const _QuickSheet({
    required this.lecture,
    required this.subject,
    required this.ref,
  });

  final LectureBlock lecture;
  final SubjectModel? subject;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF191B23);
    final secondary = isDark ? const Color(0xFF8B8FA8) : const Color(0xFF8990B0);
    final name = subject?.name ?? 'Unknown';
    final color = subject != null
        ? hexToColor(subject!.effectiveColorHex)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject pill
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${lecture.startTime} – ${lecture.endTime}  •  ${lecture.durationMinutes} min',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: secondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(timetableEditorNotifierProvider.notifier)
                      .deleteLecture(lecture.id);
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startTime = widget.lecture.startTime;
    _durationMinutes = widget.lecture.durationMinutes;
    _notesCtrl = TextEditingController(text: widget.lecture.notes ?? '');
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
      setState(() {
        _startTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String get _endTime {
    final parts = _startTime.split(':');
    final startMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endMins = startMins + _durationMinutes;
    return '${(endMins ~/ 60).toString().padLeft(2, '0')}:${(endMins % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.ref
        .read(timetableEditorNotifierProvider.notifier)
        .updateLectureDetails(
          widget.lecture.id,
          startTime: _startTime,
          durationMinutes: _durationMinutes,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
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
                child: GestureDetector(
                  onTap: _pickStartTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: border),
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
