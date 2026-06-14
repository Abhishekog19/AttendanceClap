import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../providers/timetable_ocr_provider.dart';

class TimetableReviewScreen extends ConsumerWidget {
  const TimetableReviewScreen({super.key});

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(editedTimetableProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final allEntries =
        schedule.values.expand((e) => e).toList();
    final hasLowConf = allEntries.any((e) => e.isLowConfidence);
    final totalSubjects = allEntries.map((e) => e.subject).toSet().length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review Timetable',
          style: AppTextStyles.bodyLg.copyWith(
                        color: onSurface, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: allEntries.isEmpty
                ? null
                : () => context.push('/timetable/semester-setup'),
            icon: const Icon(Icons.check),
            label: const Text('Confirm'),
            style: TextButton.styleFrom(foregroundColor: primary),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _StatChip(
                  label: '$totalSubjects subjects',
                  icon: Icons.menu_book_outlined,
                  color: primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatChip(
                  label: '${allEntries.length} classes/week',
                  icon: Icons.calendar_today_outlined,
                  color: Colors.green,
                ),
                if (hasLowConf) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _StatChip(
                    label: 'Low confidence',
                    icon: Icons.warning_amber_outlined,
                    color: Colors.amber,
                  ),
                ],
              ],
            ),
          ),

          if (hasLowConf)
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Amber entries had low OCR confidence. Tap to verify.',
                      style: AppTextStyles.bodySm.copyWith(
                          color: Colors.amber.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // ── Day groups ───────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, 100),
              itemCount: _days.length,
              itemBuilder: (context, i) {
                final day = _days[i];
                final entries = schedule[day] ?? [];
                if (entries.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.lg, bottom: AppSpacing.sm),
                      child: Text(
                        day,
                        style: AppTextStyles.headlineMd.copyWith(
                            color: onSurface),
                      ),
                    ),
                    ...entries.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final e = entry.value;
                      return _EntryCard(
                        entry: e,
                        onEdit: () => _showEditSheet(
                          context,
                          ref,
                          day,
                          idx,
                          e,
                          isDark,
                          primary,
                        ),
                        onDelete: () {
                          ref
                              .read(editedTimetableProvider.notifier)
                              .removeEntry(day, idx);
                        },
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref, isDark, primary),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    String day,
    int index,
    TimetableEntry entry,
    bool isDark,
    Color primary,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EntryEditSheet(
        initial: entry,
        onSave: (updated) {
          ref.read(editedTimetableProvider.notifier).updateEntry(
                day,
                index,
                updated,
              );
        },
      ),
    );
  }

  void _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color primary,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EntryEditSheet(
        initial: const TimetableEntry(
          subject: '',
          day: 'Monday',
          startTime: '09:00',
          endTime: '10:00',
        ),
        onSave: (entry) {
          ref.read(editedTimetableProvider.notifier).addEntry(entry);
        },
      ),
    );
  }
}

// ── Entry Card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final TimetableEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
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
    final borderColor = entry.isLowConfidence
        ? Colors.amber.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Time column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.startTime,
                        style: AppTextStyles.labelMd.copyWith(
                            color: onSurface, fontWeight: FontWeight.bold)),
                    Text(entry.endTime,
                        style: AppTextStyles.bodySm.copyWith(
                            color: onSurfaceVariant)),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                // Divider
                Container(width: 1, height: 40,
                    color: borderColor),
                const SizedBox(width: AppSpacing.md),
                // Subject info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (entry.isLowConfidence)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.xs),
                              child: const Icon(Icons.warning_amber,
                                  color: Colors.amber, size: 14),
                            ),
                          Expanded(
                            child: Text(entry.subject,
                                style: AppTextStyles.bodyLg.copyWith(
                                    color: onSurface,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      if (entry.faculty != null)
                        Text(entry.faculty!,
                            style: AppTextStyles.bodySm.copyWith(
                                color: onSurfaceVariant)),
                      if (entry.room != null)
                        Text(entry.room!,
                            style: AppTextStyles.bodySm.copyWith(
                                color: onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: AppColors.error.withValues(alpha: 0.7),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.bodySm.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Edit / Add Entry Bottom Sheet ─────────────────────────────────────────────

class _EntryEditSheet extends StatefulWidget {
  final TimetableEntry initial;
  final void Function(TimetableEntry) onSave;

  const _EntryEditSheet({required this.initial, required this.onSave});

  @override
  State<_EntryEditSheet> createState() => _EntryEditSheetState();
}

class _EntryEditSheetState extends State<_EntryEditSheet> {
  late TextEditingController _subjectCtrl;
  late TextEditingController _facultyCtrl;
  late TextEditingController _roomCtrl;
  late String _selectedDay;
  late String _startTime;
  late String _endTime;

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.initial.subject);
    _facultyCtrl = TextEditingController(text: widget.initial.faculty ?? '');
    _roomCtrl = TextEditingController(text: widget.initial.room ?? '');
    _selectedDay = widget.initial.day;
    _startTime = widget.initial.startTime;
    _endTime = widget.initial.endTime;
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _facultyCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Edit Class',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
          const SizedBox(height: AppSpacing.lg),

          // Subject
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Subject *',
              prefixIcon: Icon(Icons.menu_book_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Day selector
          DropdownButtonFormField<String>(
            value: _selectedDay,
            decoration: const InputDecoration(
              labelText: 'Day *',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(),
            ),
            items: _days
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDay = v ?? _selectedDay),
          ),
          const SizedBox(height: AppSpacing.md),

          // Time row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        hintText: _startTime,
                        prefixIcon: const Icon(Icons.access_time),
                        border: const OutlineInputBorder(),
                      ),
                      controller:
                          TextEditingController(text: _startTime),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        hintText: _endTime,
                        prefixIcon: const Icon(Icons.access_time_filled),
                        border: const OutlineInputBorder(),
                      ),
                      controller:
                          TextEditingController(text: _endTime),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Faculty
          TextField(
            controller: _facultyCtrl,
            decoration: const InputDecoration(
              labelText: 'Faculty (optional)',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Room
          TextField(
            controller: _roomCtrl,
            decoration: const InputDecoration(
              labelText: 'Room (optional)',
              prefixIcon: Icon(Icons.room_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text('Save Changes',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  void _save() {
    if (_subjectCtrl.text.trim().isEmpty) return;
    final updated = TimetableEntry(
      subject: _subjectCtrl.text.trim(),
      day: _selectedDay,
      startTime: _startTime,
      endTime: _endTime,
      faculty:
          _facultyCtrl.text.trim().isEmpty ? null : _facultyCtrl.text.trim(),
      room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
      confidence: 1.0, // user-confirmed
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }
}


