import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/manual_timetable_provider.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  /// If non-null, the screen is in edit mode and pre-populates all fields.
  final TimetableEntry? existing;

  const ManualEntryScreen({super.key, this.existing});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  // ── Form state ────────────────────────────────────────────────────────────
  String? _selectedSubjectName;
  String _selectedDay = 'Monday';
  String _startTime = '09:00';
  String _endTime = '10:00';
  late TextEditingController _roomCtrl;
  late TextEditingController _newSubjectCtrl;
  bool _isNewSubject = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedSubjectName = e?.subject;
    _selectedDay = e?.day ?? 'Monday';
    _startTime = e?.startTime ?? '09:00';
    _endTime = e?.endTime ?? '10:00';
    _roomCtrl = TextEditingController(text: e?.room ?? '');
    _newSubjectCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    _newSubjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final notifierState = ref.watch(manualTimetableNotifierProvider);
    final isSaving = notifierState.status == ManualEntryStatus.saving;

    // Listen for success/error
    ref.listen(manualTimetableNotifierProvider, (prev, next) {
      if (next.status == ManualEntryStatus.success) {
        final sessions = next.generatedSessions ?? 0;
        final msg = _isEditing
            ? 'Class updated successfully'
            : sessions > 0
                ? 'Class added — $sessions sessions generated'
                : 'Class entry saved';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(manualTimetableNotifierProvider.notifier).reset();
          context.pop(true); // pop with success signal
        }
      }
      if (next.status == ManualEntryStatus.error && next.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isSaving ? null : () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Class' : 'Add Class',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton(
              onPressed: isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Update' : 'Save',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Subject ──────────────────────────────────────────────────────
            _sectionLabel('SUBJECT', onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),

            subjectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (subjects) {
                final subjectNames =
                    subjects.map((s) => s.name).toList()..sort();

                if (_isNewSubject) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _newSubjectCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'New Subject Name *',
                          prefixIcon: const Icon(Icons.menu_book_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Pick from list',
                            onPressed: () =>
                                setState(() => _isNewSubject = false),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v?.trim().isEmpty == true
                            ? 'Please enter a subject name'
                            : null,
                      ),
                    ],
                  );
                }

                return DropdownButtonFormField<String>(
                  value: subjectNames.contains(_selectedSubjectName)
                      ? _selectedSubjectName
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: [
                    ...subjectNames.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name,
                              overflow: TextOverflow.ellipsis),
                        )),
                    const DropdownMenuItem(
                      value: '__new__',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Add new subject…',
                              style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == '__new__') {
                      setState(() {
                        _isNewSubject = true;
                        _selectedSubjectName = null;
                      });
                    } else {
                      setState(() => _selectedSubjectName = v);
                    }
                  },
                  validator: (_) {
                    if (!_isNewSubject && _selectedSubjectName == null) {
                      return 'Please select or create a subject';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Day ──────────────────────────────────────────────────────────
            _sectionLabel('DAY', onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.xs),
                itemCount: _days.length,
                itemBuilder: (ctx, i) {
                  final day = _days[i];
                  final selected = day == _selectedDay;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary
                            : primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: selected
                              ? primary
                              : primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        day.substring(0, 3),
                        style: TextStyle(
                          color: selected ? Colors.white : primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Time ─────────────────────────────────────────────────────────
            _sectionLabel('TIME', onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Start Time',
                    time: _startTime,
                    icon: Icons.access_time,
                    onPicked: (t) => setState(() => _startTime = t),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  child: Icon(Icons.arrow_forward,
                      color: onSurfaceVariant, size: 18),
                ),
                Expanded(
                  child: _TimePickerField(
                    label: 'End Time',
                    time: _endTime,
                    icon: Icons.access_time_filled,
                    onPicked: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),

            // Time validation message
            if (_endTime.compareTo(_startTime) <= 0)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'End time must be after start time',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.error),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // ── Room (optional) ───────────────────────────────────────────────
            _sectionLabel('ROOM (OPTIONAL)', onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _roomCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Room number / lab name',
                prefixIcon: Icon(Icons.room_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            // ── Active semester info ───────────────────────────────────────
            if (!_isEditing) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primary, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'If an active semester exists, class sessions will be '
                        'generated from today to the end of the semester.',
                        style: AppTextStyles.bodySm
                            .copyWith(color: onSurface, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: AppTextStyles.labelCaps.copyWith(color: color),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation: time order
    if (_endTime.compareTo(_startTime) <= 0) return;

    final subjectName = _isNewSubject
        ? _newSubjectCtrl.text.trim()
        : _selectedSubjectName ?? '';

    if (subjectName.isEmpty) return;

    final entry = TimetableEntry(
      id: widget.existing?.id,
      subject: subjectName,
      day: _selectedDay,
      startTime: _startTime,
      endTime: _endTime,
      room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
      confidence: 1.0,
    );

    final notifier = ref.read(manualTimetableNotifierProvider.notifier);
    if (_isEditing) {
      await notifier.updateEntry(entry);
    } else {
      await notifier.addEntry(entry);
    }
  }
}

// ── Time Picker Field ─────────────────────────────────────────────────────────

class _TimePickerField extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final void Function(String) onPicked;

  const _TimePickerField({
    required this.label,
    required this.time,
    required this.icon,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: () async {
        final parts = time.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          onPicked(
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodySm
                          .copyWith(color: onSurfaceVariant, fontSize: 10)),
                  Text(time,
                      style: AppTextStyles.bodyLg.copyWith(
                          color: onSurface, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 14, color: onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
