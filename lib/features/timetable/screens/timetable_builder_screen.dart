/// TimetableBuilderScreen
///
/// Full-week manual timetable builder with:
///   • Auto-save to Firebase (addTimetableEntry / updateTimetableEntry / deleteTimetableEntry)
///   • Subject+Faculty+Room autocomplete from BuilderRecentsService (SharedPreferences)
///   • Edit slot → optional "Apply changed fields to all days where subject appears"
///   • Copy day: copy all slots from another day into this one
///   • Duplicate slot to another day (single card copy icon)
///   • Clear day: remove all entries for a day
///   • No drag-and-drop (removed)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../providers/timetable_ocr_provider.dart';
import '../services/builder_recents_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
];

const _kQuickSlots = [
  ('08:00', '09:00'), ('09:00', '10:00'), ('10:00', '11:00'),
  ('11:00', '12:00'), ('12:00', '13:00'), ('13:00', '14:00'),
  ('14:00', '15:00'), ('15:00', '16:00'), ('16:00', '17:00'),
  ('17:00', '18:00'),
];

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: field-level diff & apply across all days
// ─────────────────────────────────────────────────────────────────────────────

/// Finds every entry across [schedule] whose subject matches [original.subject]
/// and updates ONLY the fields that changed between [original] and [updated].
/// Returns the new full schedule + a list of (id, updatedEntry) pairs to
/// persist to Firebase.
({
  Map<String, List<TimetableEntry>> schedule,
  List<(String id, TimetableEntry entry)> toUpdate,
}) _applyDiffToAllDays({
  required Map<String, List<TimetableEntry>> schedule,
  required TimetableEntry original,
  required TimetableEntry updated,
}) {
  final subjectChanged = original.subject != updated.subject;
  final facultyChanged = original.faculty != updated.faculty;
  final roomChanged = original.room != updated.room;

  final newSchedule =
      Map<String, List<TimetableEntry>>.from(schedule);
  final toUpdate = <(String id, TimetableEntry entry)>[];

  for (final day in newSchedule.keys) {
    final entries = List<TimetableEntry>.from(newSchedule[day] ?? []);
    bool dayChanged = false;
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.subject == original.subject) {
        final patched = e.copyWith(
          subject: subjectChanged ? updated.subject : null,
          faculty: facultyChanged ? updated.faculty : null,
          room: roomChanged ? updated.room : null,
        );
        entries[i] = patched;
        dayChanged = true;
        if (patched.id != null) {
          toUpdate.add((patched.id!, patched));
        }
      }
    }
    if (dayChanged) newSchedule[day] = entries;
  }
  return (schedule: newSchedule, toUpdate: toUpdate);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────

class TimetableBuilderScreen extends ConsumerStatefulWidget {
  const TimetableBuilderScreen({super.key});

  @override
  ConsumerState<TimetableBuilderScreen> createState() =>
      _TimetableBuilderScreenState();
}

class _TimetableBuilderScreenState
    extends ConsumerState<TimetableBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;
  bool _syncing = false; // true while Done button is regenerating sessions

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _kDays.length, vsync: this);
    // ensureLoaded() must be awaited so SharedPreferences data is available
    // before _SlotSheet's addPostFrameCallback reads BuilderRecentsService.all.
    BuilderRecentsService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {}); // trigger rebuild if recents affect UI
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final current = ref.read(editedTimetableProvider);
    if (current.isNotEmpty) return; // already loaded

    setState(() => _loading = true);
    try {
      // Try to restore any previously auto-saved entries from Firebase
      final repo = ref.read(timetableRepositoryProvider);
      final entries = await repo.watchTimetableEntries().first;
      if (entries.isEmpty) {
        // Fresh start — seed empty days
        ref.read(editedTimetableProvider.notifier).setAll({
          for (final d in _kDays) d: [],
        });
      } else {
        // Group by day and restore
        final byDay = <String, List<TimetableEntry>>{
          for (final d in _kDays) d: [],
        };
        for (final e in entries) {
          byDay.putIfAbsent(e.day, () => []).add(e);
        }
        for (final list in byDay.values) {
          list.sort((a, b) => a.startTime.compareTo(b.startTime));
        }
        ref.read(editedTimetableProvider.notifier).setAll(byDay);
      }
    } catch (_) {
      ref.read(editedTimetableProvider.notifier).setAll({
        for (final d in _kDays) d: [],
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Smart Done handler ──────────────────────────────────────────────────────

  /// Called when the user taps "Done".
  ///  - Semester exists → regenerate sessions in-place, navigate to schedule.
  ///  - No semester      → push to semester-setup (first-time flow).
  Future<void> _handleDone() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    try {
      final repo = ref.read(timetableRepositoryProvider);
      final semester = await repo.getActiveSemester();

      if (semester != null) {
        // ── Re-generate sessions from whatever is in timetable_entries ──
        final entries = await repo.watchTimetableEntries().first;
        if (entries.isEmpty) {
          // Entries were cleared — just go to setup
          if (mounted) context.push('/timetable/semester-setup');
          return;
        }

        // Ensure subjects exist for any new classes added
        final subjectIdMap = await repo.createSubjectsFromTimetable(entries);

        // Wipe old sessions and regenerate (prevents duplicates)
        await repo.deleteAllSessions();
        await repo.saveClassSessions(
          entries: entries,
          semester: semester,
          subjectIdMap: subjectIdMap,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Schedule updated with your latest classes!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
        context.go('/timetable');
      } else {
        // ── First time: go through semester-setup ──
        if (mounted) context.push('/timetable/semester-setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to sync schedule: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(editedTimetableProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final totalEntries = schedule.values.expand((e) => e).length;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primary),
              const SizedBox(height: AppSpacing.md),
              Text('Loading your timetable…',
                  style: AppTextStyles.bodySm.copyWith(color: onVariant)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Build Timetable',
                style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
            if (totalEntries > 0)
              Text(
                '$totalEntries class${totalEntries == 1 ? '' : 'es'} · saved',
                style: AppTextStyles.bodySm.copyWith(color: Colors.green),
              ),
          ],
        ),
        actions: [
          if (totalEntries > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilledButton.icon(
                onPressed: _syncing ? null : _handleDone,
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: Text(_syncing ? 'Syncing…' : 'Done'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: primary,
          unselectedLabelColor: onVariant,
          indicatorColor: primary,
          tabs: _kDays.map((d) {
            final count = schedule[d]?.length ?? 0;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d.substring(0, 3)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 18,
                      height: 18,
                      decoration:
                          BoxDecoration(color: primary, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _kDays
            .map((day) => _DayTab(
                  day: day,
                  allDays: _kDays,
                  primary: primary,
                  onSurface: onSurface,
                  onVariant: onVariant,
                  isDark: isDark,
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Day Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DayTab extends ConsumerWidget {
  final String day;
  final List<String> allDays;
  final Color primary;
  final Color onSurface;
  final Color onVariant;
  final bool isDark;

  const _DayTab({
    required this.day,
    required this.allDays,
    required this.primary,
    required this.onSurface,
    required this.onVariant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(editedTimetableProvider)[day] ?? [];
    final schedule = ref.watch(editedTimetableProvider);
    final hasAnyEntries = schedule.values.any((e) => e.isNotEmpty);

    return Column(
      children: [
        // ── Action row ───────────────────────────────────────────────────────
        if (hasAnyEntries)
          _ActionRow(
            day: day,
            allDays: allDays,
            hasEntries: entries.isNotEmpty,
            primary: primary,
            onVariant: onVariant,
            onCopyFrom: (src) => _copyFrom(context, ref, src),
            onClearDay: () => _clearDay(context, ref),
          ),

        // ── Slot list ────────────────────────────────────────────────────────
        Expanded(
          child: entries.isEmpty
              ? _EmptyDayPlaceholder(
                  day: day,
                  primary: primary,
                  onVariant: onVariant,
                  onAdd: () => _showAddSheet(context, ref),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) => _SlotCard(
                    key: ValueKey(
                        '${entries[i].id ?? '$day-$i'}_${entries[i].startTime}'),
                    entry: entries[i],
                    index: i,
                    day: day,
                    allDays: allDays,
                    primary: primary,
                    onSurface: onSurface,
                    onVariant: onVariant,
                    isDark: isDark,
                    onDelete: () => _deleteEntry(context, ref, i),
                    onEdit: () => _showEditSheet(context, ref, entries[i], i),
                    onDuplicateTo: (targetDay) =>
                        _duplicateTo(context, ref, entries[i], targetDay),
                  ),
                ),
        ),

        // ── Add button ───────────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddSheet(context, ref),
                icon: const Icon(Icons.add),
                label: Text('Add Slot to $day'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Firebase-backed mutations ──────────────────────────────────────────────

  Future<void> _deleteEntry(
      BuildContext context, WidgetRef ref, int index) async {
    final entry =
        (ref.read(editedTimetableProvider)[day] ?? [])[index];
    // Remove from local state immediately (optimistic)
    ref.read(editedTimetableProvider.notifier).removeEntry(day, index);
    // Firebase
    if (entry.id != null) {
      try {
        await ref
            .read(timetableRepositoryProvider)
            .deleteTimetableEntry(entry.id!);
      } catch (_) {
        // Non-critical: local state is already consistent
      }
    }
  }

  Future<void> _copyFrom(
      BuildContext context, WidgetRef ref, String sourceDay) async {
    final sourceEntries =
        ref.read(editedTimetableProvider)[sourceDay] ?? [];
    if (sourceEntries.isEmpty) return;

    final repo = ref.read(timetableRepositoryProvider);
    final s = Map<String, List<TimetableEntry>>.from(
        ref.read(editedTimetableProvider));
    final existing = List<TimetableEntry>.from(s[day] ?? []);

    for (final e in sourceEntries) {
      if (existing.any((x) => x.startTime == e.startTime)) continue;
      // Save to Firebase
      final newEntry = TimetableEntry(
        subject: e.subject,
        day: day,
        startTime: e.startTime,
        endTime: e.endTime,
        faculty: e.faculty,
        room: e.room,
        confidence: 1.0,
      );
      try {
        final id = await repo.addTimetableEntry(newEntry);
        existing.add(newEntry.copyWith(id: id));
      } catch (_) {
        existing.add(newEntry);
      }
    }
    existing.sort((a, b) => a.startTime.compareTo(b.startTime));
    s[day] = existing;
    ref.read(editedTimetableProvider.notifier).setAll(s);
  }

  Future<void> _clearDay(BuildContext context, WidgetRef ref) async {
    final entries = ref.read(editedTimetableProvider)[day] ?? [];
    final repo = ref.read(timetableRepositoryProvider);

    // Clear local immediately
    final s = Map<String, List<TimetableEntry>>.from(
        ref.read(editedTimetableProvider));
    s[day] = [];
    ref.read(editedTimetableProvider.notifier).setAll(s);

    // Firebase delete (fire-and-forget)
    for (final e in entries) {
      if (e.id != null) {
        repo.deleteTimetableEntry(e.id!).catchError((_) {});
      }
    }
  }

  Future<void> _duplicateTo(
    BuildContext context,
    WidgetRef ref,
    TimetableEntry entry,
    String targetDay,
  ) async {
    final repo = ref.read(timetableRepositoryProvider);
    final newEntry = TimetableEntry(
      subject: entry.subject,
      day: targetDay,
      startTime: entry.startTime,
      endTime: entry.endTime,
      faculty: entry.faculty,
      room: entry.room,
      confidence: 1.0,
    );
    try {
      final id = await repo.addTimetableEntry(newEntry);
      ref
          .read(editedTimetableProvider.notifier)
          .addEntry(newEntry.copyWith(id: id));
    } catch (_) {
      ref.read(editedTimetableProvider.notifier).addEntry(newEntry);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"${entry.subject}" added to $targetDay'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotSheet(
        mode: _SheetMode.add,
        day: day,
        primary: primary,
        onSurface: onSurface,
        onVariant: onVariant,
        isDark: isDark,
        onSave: (entry, applyAll) async {
          await _commitAdd(ref, entry);
        },
      ),
    );
  }

  Future<void> _showEditSheet(
      BuildContext context, WidgetRef ref, TimetableEntry existing, int index) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotSheet(
        mode: _SheetMode.edit,
        day: day,
        existing: existing,
        primary: primary,
        onSurface: onSurface,
        onVariant: onVariant,
        isDark: isDark,
        onSave: (updated, applyAll) async {
          await _commitEdit(ref, existing, updated, index, applyAll);
        },
      ),
    );
  }

  Future<void> _commitAdd(WidgetRef ref, TimetableEntry entry) async {
    final repo = ref.read(timetableRepositoryProvider);
    try {
      final id = await repo.addTimetableEntry(entry);
      ref
          .read(editedTimetableProvider.notifier)
          .addEntry(entry.copyWith(id: id));
    } catch (_) {
      // Save locally even if Firebase fails
      ref.read(editedTimetableProvider.notifier).addEntry(entry);
    }
    // Save combo to recents
    BuilderRecentsService.instance.save(entry.subject,
        faculty: entry.faculty, room: entry.room);
  }

  Future<void> _commitEdit(
    WidgetRef ref,
    TimetableEntry original,
    TimetableEntry updated,
    int index,
    bool applyAll,
  ) async {
    final repo = ref.read(timetableRepositoryProvider);

    if (applyAll) {
      // Apply field-level diff to all days
      final result = _applyDiffToAllDays(
        schedule: ref.read(editedTimetableProvider),
        original: original,
        updated: updated,
      );
      ref.read(editedTimetableProvider.notifier).setAll(result.schedule);
      // Persist all changed entries
      for (final (id, entry) in result.toUpdate) {
        repo.updateTimetableEntry(id, entry).catchError((_) {});
      }
    } else {
      // Update only this entry
      ref.read(editedTimetableProvider.notifier).updateEntry(day, index, updated);
      if (updated.id != null) {
        repo
            .updateTimetableEntry(updated.id!, updated)
            .catchError((_) {});
      }
    }

    // Update combo recents
    BuilderRecentsService.instance.save(updated.subject,
        faculty: updated.faculty, room: updated.room);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action row (Copy from / Clear day)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final String day;
  final List<String> allDays;
  final bool hasEntries;
  final Color primary;
  final Color onVariant;
  final void Function(String) onCopyFrom;
  final VoidCallback onClearDay;

  const _ActionRow({
    required this.day,
    required this.allDays,
    required this.hasEntries,
    required this.primary,
    required this.onVariant,
    required this.onCopyFrom,
    required this.onClearDay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Row(
        children: [
          _Chip(
            icon: Icons.copy_all_outlined,
            label: 'Copy from…',
            color: primary,
            onTap: () => _showCopyPicker(context),
          ),
          const Spacer(),
          if (hasEntries)
            _Chip(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear day',
              color: AppColors.error,
              onTap: () => _confirmClear(context),
            ),
        ],
      ),
    );
  }

  void _showCopyPicker(BuildContext context) {
    final others = allDays.where((d) => d != day).toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayPickerSheet(
        title: 'Copy from which day?',
        icon: Icons.copy_all_outlined,
        days: others,
        primary: primary,
        onVariant: onVariant,
        onPick: (d) {
          Navigator.pop(ctx);
          onCopyFrom(d);
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear $day?'),
        content: const Text('This removes all classes for this day.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onClearDay();
            },
            child:
                const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Chip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Day Picker Sheet (reused by copy and duplicate)
// ─────────────────────────────────────────────────────────────────────────────

class _DayPickerSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> days;
  final Color primary;
  final Color onVariant;
  final void Function(String) onPick;

  const _DayPickerSheet({
    required this.title,
    required this.icon,
    required this.days,
    required this.primary,
    required this.onVariant,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTextStyles.headlineMd),
              ],
            ),
          ),
          const Divider(height: 1),
          ...days.map((d) => ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  child: Text(d.substring(0, 2),
                      style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                title: Text(d),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 14, color: onVariant),
                onTap: () => onPick(d),
              )),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Slot Card  (edit + duplicate, NO drag handle)
// ─────────────────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final TimetableEntry entry;
  final int index;
  final String day;
  final List<String> allDays;
  final Color primary;
  final Color onSurface;
  final Color onVariant;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final void Function(String targetDay) onDuplicateTo;

  const _SlotCard({
    required super.key,
    required this.entry,
    required this.index,
    required this.day,
    required this.allDays,
    required this.primary,
    required this.onSurface,
    required this.onVariant,
    required this.isDark,
    required this.onDelete,
    required this.onEdit,
    required this.onDuplicateTo,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.startTime,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primary)),
              Text('│',
                  style: TextStyle(color: primary.withValues(alpha: 0.4))),
              Text(entry.endTime,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primary)),
            ],
          ),
        ),
        title: Text(entry.subject,
            style: AppTextStyles.bodyLg.copyWith(
                color: onSurface, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: (entry.room != null || entry.faculty != null)
            ? Text(
                [
                  if (entry.faculty != null) entry.faculty,
                  if (entry.room != null) '📍 ${entry.room}',
                ].join('  '),
                style: AppTextStyles.bodySm.copyWith(color: onVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Duplicate
            IconButton(
              tooltip: 'Copy to another day',
              icon: Icon(Icons.content_copy_outlined,
                  size: 18, color: primary),
              onPressed: () => _showDuplicatePicker(context),
            ),
            // Edit
            IconButton(
              tooltip: 'Edit',
              icon: Icon(Icons.edit_outlined, size: 18, color: onVariant),
              onPressed: onEdit,
            ),
            // Delete
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  void _showDuplicatePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayPickerSheet(
        title: 'Add "${entry.subject}" to…',
        icon: Icons.content_copy_outlined,
        days: allDays.where((d) => d != day).toList(),
        primary: primary,
        onVariant: onVariant,
        onPick: (targetDay) {
          Navigator.pop(ctx);
          onDuplicateTo(targetDay);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyDayPlaceholder extends StatelessWidget {
  final String day;
  final Color primary;
  final Color onVariant;
  final VoidCallback onAdd;

  const _EmptyDayPlaceholder({
    required this.day,
    required this.primary,
    required this.onVariant,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_outlined,
                size: 36, color: primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No classes on $day yet',
              style: AppTextStyles.bodyLg.copyWith(color: onVariant)),
          const SizedBox(height: AppSpacing.xs),
          Text('Tap "Add Slot" below to get started',
              style: AppTextStyles.bodySm
                  .copyWith(color: onVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Add / Edit slot sheet (unified)
// ─────────────────────────────────────────────────────────────────────────────

enum _SheetMode { add, edit }

class _SlotSheet extends ConsumerStatefulWidget {
  final _SheetMode mode;
  final String day;
  final TimetableEntry? existing;
  final Color primary;
  final Color onSurface;
  final Color onVariant;
  final bool isDark;
  /// Called when user confirms. [applyAll] is only meaningful in edit mode.
  final Future<void> Function(TimetableEntry entry, bool applyAll) onSave;

  const _SlotSheet({
    required this.mode,
    required this.day,
    this.existing,
    required this.primary,
    required this.onSurface,
    required this.onVariant,
    required this.isDark,
    required this.onSave,
  });

  @override
  ConsumerState<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends ConsumerState<_SlotSheet> {
  late TextEditingController _subjectCtrl;
  late TextEditingController _facultyCtrl;
  late TextEditingController _roomCtrl;
  final _formKey = GlobalKey<FormState>();
  final _subjectFocus = FocusNode();

  late String _startTime;
  late String _endTime;
  bool _applyAll = false;
  bool _saving = false;
  List<SubjectCombo> _suggestions = [];
  bool _showSuggestions = false;

  bool get _isEdit => widget.mode == _SheetMode.edit;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _subjectCtrl = TextEditingController(text: e?.subject ?? '');
    _facultyCtrl = TextEditingController(text: e?.faculty ?? '');
    _roomCtrl = TextEditingController(text: e?.room ?? '');
    _startTime = e?.startTime ?? '09:00';
    _endTime = e?.endTime ?? '10:00';

    _subjectCtrl.addListener(_onSubjectChanged);
    _subjectFocus.addListener(() {
      if (mounted) {
        setState(() => _showSuggestions = _subjectFocus.hasFocus &&
            _suggestions.isNotEmpty &&
            _subjectCtrl.text.isNotEmpty);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final all = BuilderRecentsService.instance.all;
      if (all.isNotEmpty && mounted) {
        setState(() => _suggestions = all.take(5).toList());
      }
    });
  }

  void _onSubjectChanged() {
    final results =
        BuilderRecentsService.instance.search(_subjectCtrl.text);
    if (mounted) {
      setState(() {
        _suggestions = results.take(5).toList();
        _showSuggestions = _subjectFocus.hasFocus &&
            _suggestions.isNotEmpty &&
            _subjectCtrl.text.isNotEmpty;
      });
    }
  }

  void _applySuggestion(SubjectCombo combo) {
    _subjectCtrl.text = combo.subject;
    _facultyCtrl.text = combo.faculty ?? '';
    _roomCtrl.text = combo.room ?? '';
    setState(() => _showSuggestions = false);
    FocusScope.of(context).nextFocus();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endTime.compareTo(_startTime) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End time must be after start time')),
      );
      return;
    }
    setState(() => _saving = true);

    final entry = TimetableEntry(
      id: widget.existing?.id,
      subject: _subjectCtrl.text.trim(),
      day: widget.day,
      startTime: _startTime,
      endTime: _endTime,
      faculty: _facultyCtrl.text.trim().isEmpty
          ? null
          : _facultyCtrl.text.trim(),
      room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
      confidence: 1.0,
    );

    await widget.onSave(entry, _applyAll);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _subjectCtrl.removeListener(_onSubjectChanged);
    _subjectCtrl.dispose();
    _facultyCtrl.dispose();
    _roomCtrl.dispose();
    _subjectFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final primary = widget.primary;
    final onSurface = widget.onSurface;
    final onVariant = widget.onVariant;

    // Count other occurrences (for "apply to all" hint)
    final schedule = ref.read(editedTimetableProvider);
    final originalSubject = widget.existing?.subject ?? '';
    final otherOccurrences = _isEdit
        ? schedule.values
            .expand((e) => e)
            .where((e) =>
                e.subject == originalSubject && e.id != widget.existing?.id)
            .length
        : 0;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: onVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(widget.day,
                          style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_isEdit ? 'Edit Class Slot' : 'Add Class Slot',
                        style: AppTextStyles.headlineMd
                            .copyWith(color: onSurface)),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Quick time presets
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  children: _kQuickSlots.map((slot) {
                    final active =
                        _startTime == slot.$1 && _endTime == slot.$2;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _startTime = slot.$1;
                        _endTime = slot.$2;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? primary
                              : primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: active
                                ? primary
                                : primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text('${slot.$1}–${slot.$2}',
                            style: TextStyle(
                                color: active ? Colors.white : primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Time pickers
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                        child: _TimeTile(
                            label: 'Start',
                            time: _startTime,
                            onPicked: (t) =>
                                setState(() => _startTime = t),
                            isDark: widget.isDark,
                            primary: primary)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Icon(Icons.arrow_forward,
                          color: onVariant, size: 18),
                    ),
                    Expanded(
                        child: _TimeTile(
                            label: 'End',
                            time: _endTime,
                            onPicked: (t) =>
                                setState(() => _endTime = t),
                            isDark: widget.isDark,
                            primary: primary)),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Form fields
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject + autocomplete
                      TextFormField(
                        controller: _subjectCtrl,
                        focusNode: _subjectFocus,
                        autofocus: !_isEdit,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Subject name *',
                          prefixIcon:
                              const Icon(Icons.menu_book_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: _subjectCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _subjectCtrl.clear();
                                    _facultyCtrl.clear();
                                    _roomCtrl.clear();
                                  })
                              : null,
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Required' : null,
                      ),

                      // Suggestion dropdown
                      if (_showSuggestions && _suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? AppColors.darkSurface
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            border: Border.all(
                                color: primary.withValues(alpha: 0.25)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            children: _suggestions.map((combo) {
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.history,
                                      size: 16, color: primary),
                                ),
                                title: Text(combo.subject,
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: onSurface,
                                        fontWeight: FontWeight.w600)),
                                subtitle: combo.faculty != null
                                    ? Text(
                                        [
                                          combo.faculty,
                                          if (combo.room != null)
                                            combo.room,
                                        ].join(' · '),
                                        style: AppTextStyles.bodySm
                                            .copyWith(color: onVariant))
                                    : null,
                                onTap: () => _applySuggestion(combo),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _facultyCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Faculty (optional)',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _roomCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Room / Lab (optional)',
                          prefixIcon: Icon(Icons.room_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      // ── "Apply to all days" (edit mode only) ──────────
                      if (_isEdit && otherOccurrences > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                                color: primary.withValues(alpha: 0.2)),
                          ),
                          child: CheckboxListTile(
                            value: _applyAll,
                            activeColor: primary,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            title: Text(
                              'Apply changes to all days',
                              style: AppTextStyles.bodyMd.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600),
                            ),
                            onChanged: (v) =>
                                setState(() => _applyAll = v ?? false),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Save button
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Icon(_isEdit
                            ? Icons.check
                            : Icons.add_circle_outline),
                    label: Text(_isEdit ? 'Save Changes' : 'Add to Timetable'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Inline time tile
// ─────────────────────────────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final void Function(String) onPicked;
  final bool isDark;
  final Color primary;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onPicked,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: () async {
        final parts = time.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts[1]) ?? 0),
        );
        if (picked != null) {
          onPicked(
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: onVariant),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: onVariant)),
                Text(time,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
