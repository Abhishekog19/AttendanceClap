/// Edit Timetable Screen
///
/// Post-onboarding timetable editor.
///
/// Design:
/// • Top-right "Done" button: the ONLY primary action. Every placement already
///   autosaves instantly (Firestore fire-and-forget). Done flushes any pending
///   debounced session regeneration then pops. No "unsaved changes" state ever
///   exists — "Done" purely means "I'm finished looking at this screen."
/// • Bottom "Customize" button: opens a bottom sheet for timetable-level config
///   (default lecture duration, visible hour range). Not lecture-level details.
/// • No duplicate Done/footer button inside the grid — TimetableGrid footer bar
///   is shown only in onboarding mode.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/timetable_editor_notifier.dart';
import '../widgets/timetable_grid.dart';

class EditTimetableScreen extends ConsumerStatefulWidget {
  const EditTimetableScreen({super.key});

  @override
  ConsumerState<EditTimetableScreen> createState() =>
      _EditTimetableScreenState();
}

class _EditTimetableScreenState extends ConsumerState<EditTimetableScreen> {
  bool _isSaving = false;

  /// Done: flush any pending debounced session regen then pop.
  Future<void> _onDone() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(timetableEditorNotifierProvider.notifier)
          .flushRegeneration();
    } catch (_) {
      // Best-effort — don't block navigation on failure
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).maybePop();
      }
    }
  }

  void _showCustomize(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CustomizeSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final border = isDark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primary),
          onPressed: _isSaving ? null : _onDone,
          tooltip: 'Done',
        ),
        title: Text(
          'Edit Timetable',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _onDone,
              child: Text(
                'Done',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Grid takes all remaining space
          const Expanded(
            child: TimetableGrid(mode: TimetableGridMode.edit),
          ),

          // Customize / settings action pinned at the bottom
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2028) : Colors.white,
              border: Border(top: BorderSide(color: border)),
            ),
            child: SafeArea(
              top: false,
              child: TextButton.icon(
                onPressed: () => _showCustomize(context),
                icon: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF8B8FA8)
                      : const Color(0xFF8990B0),
                ),
                label: Text(
                  'Customize',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF8B8FA8)
                        : const Color(0xFF8990B0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Customize Bottom Sheet ───────────────────────────────────────────────────

class _CustomizeSheet extends ConsumerStatefulWidget {
  const _CustomizeSheet({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends ConsumerState<_CustomizeSheet> {
  late int _duration;
  late int _startHour;
  late int _endHour;

  @override
  void initState() {
    super.initState();
    final data = ref.read(timetableEditorNotifierProvider).data;
    _duration  = data.defaultLectureDurationMinutes;
    _startHour = data.gridStartHour;
    _endHour   = data.gridEndHour;
  }

  @override
  Widget build(BuildContext context) {
    final bg      = widget.isDark ? const Color(0xFF1E2028) : Colors.white;
    final onSurf  = widget.isDark ? Colors.white : const Color(0xFF191B23);
    final hint    = widget.isDark ? const Color(0xFF8B8FA8) : const Color(0xFF8990B0);
    final primary = widget.isDark ? const Color(0xFFB4C5FF) : const Color(0xFF4F5EFF);
    final border  = widget.isDark ? const Color(0xFF282A34) : const Color(0xFFE1E2ED);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
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
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Customize',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: onSurf,
            ),
          ),
          const SizedBox(height: 24),

          // Default lecture duration
          _SettingRow(
            label: 'Default duration',
            hint: hint,
            onSurface: onSurf,
            child: Row(
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  onTap: () {
                    if (_duration > 15) setState(() => _duration -= 15);
                  },
                  dark: widget.isDark,
                  primary: primary,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$_duration min',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurf,
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add,
                  onTap: () {
                    if (_duration < 300) setState(() => _duration += 15);
                  },
                  dark: widget.isDark,
                  primary: primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grid hour range
          _SettingRow(
            label: 'Start hour',
            hint: hint,
            onSurface: onSurf,
            child: Row(
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  onTap: () {
                    if (_startHour > 0) setState(() => _startHour--);
                  },
                  dark: widget.isDark,
                  primary: primary,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$_startHour:00',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurf,
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add,
                  onTap: () {
                    if (_startHour < _endHour - 1) setState(() => _startHour++);
                  },
                  dark: widget.isDark,
                  primary: primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SettingRow(
            label: 'End hour',
            hint: hint,
            onSurface: onSurf,
            child: Row(
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  onTap: () {
                    if (_endHour > _startHour + 1) setState(() => _endHour--);
                  },
                  dark: widget.isDark,
                  primary: primary,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$_endHour:00',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurf,
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add,
                  onTap: () {
                    if (_endHour < 24) setState(() => _endHour++);
                  },
                  dark: widget.isDark,
                  primary: primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final notifier =
                    ref.read(timetableEditorNotifierProvider.notifier);

                // Validate that no saved lecture falls outside the new range.
                final lectures =
                    ref.read(timetableEditorNotifierProvider).data.lectures;
                final outsideBounds = lectures.where((l) {
                  final startMins = l.startHour * 60 + l.startMinute;
                  final endMins = startMins + l.durationMinutes;
                  return startMins < _startHour * 60 ||
                      endMins > _endHour * 60;
                }).toList();

                if (outsideBounds.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${outsideBounds.length} lecture${outsideBounds.length == 1 ? '' : 's'} '
                        'fall outside the new hour range. '
                        'Adjust or remove them first.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                notifier.updateDefaultLectureDuration(_duration);
                notifier.updateGridHourRange(_startHour, _endHour);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.child,
    required this.hint,
    required this.onSurface,
  });

  final String label;
  final Widget child;
  final Color hint;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: hint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.dark,
    required this.primary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final Color primary;

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
        child: Icon(icon, size: 16, color: primary),
      ),
    );
  }
}
