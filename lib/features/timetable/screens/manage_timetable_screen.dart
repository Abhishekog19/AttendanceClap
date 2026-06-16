import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../providers/manual_timetable_provider.dart';

class ManageTimetableScreen extends ConsumerWidget {
  const ManageTimetableScreen({super.key});

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final entriesAsync = ref.watch(timetableEntriesStreamProvider);

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
          'Manage Timetable',
          style: AppTextStyles.headlineMd.copyWith(color: onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Build with suggestions',
            onPressed: () => context.push('/timetable/builder'),
          ),
        ],
        // OCR import button — disabled until OCR feature is ready
        // actions: [
        //   // Import via OCR
        //   IconButton(
        //     icon: const Icon(Icons.document_scanner_outlined),
        //     tooltip: 'Import via OCR',
        //     onPressed: () => context.push('/timetable/upload'),
        //   ),
        // ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await context.push<bool>('/timetable/manual-entry');
          if (result == true) {
            // Entries stream auto-refreshes; no manual action needed
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: entriesAsync.when(
        loading: () => const SubjectCardSkeleton(),
        error: (e, _) => _ErrorBody(message: e.toString()),
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyBody(
              primary: primary,
              onAddManual: () => context.push('/timetable/manual-entry'),
              onBuildWithSuggestions: () => context.push('/timetable/builder'),
              // OCR import — disabled until OCR feature is ready
              // onImport: () => context.push('/timetable/upload'),
            );
          }
          return _GroupedEntryList(
            entries: entries,
            days: _days,
            onEdit: (entry) => context.push(
              '/timetable/manual-entry',
              extra: entry,
            ),
            onDelete: (entry) => _confirmDelete(context, ref, entry),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TimetableEntry entry,
  ) async {
    // Count future sessions
    final notifier = ref.read(manualTimetableNotifierProvider.notifier);
    int futureCount = 0;
    try {
      futureCount = await notifier.countFutureSessions(entry);
    } catch (_) {}

    if (!context.mounted) return;

    bool? deleteSessions = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(
        entry: entry,
        futureSessionCount: futureCount,
        onChanged: (v) => deleteSessions = v,
      ),
    );

    if (confirmed == true && context.mounted) {
      await notifier.deleteEntry(
        entry,
        deleteFutureSessions: deleteSessions ?? false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteSessions == true && futureCount > 0
                  ? 'Class removed along with $futureCount future sessions'
                  : 'Class entry removed',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Grouped Entry List ────────────────────────────────────────────────────────

class _GroupedEntryList extends StatelessWidget {
  final List<TimetableEntry> entries;
  final List<String> days;
  final void Function(TimetableEntry) onEdit;
  final void Function(TimetableEntry) onDelete;

  const _GroupedEntryList({
    required this.entries,
    required this.days,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final grouped = <String, List<TimetableEntry>>{};
    for (final d in days) {
      final dayEntries =
          entries.where((e) => e.day == d).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (dayEntries.isNotEmpty) grouped[d] = dayEntries;
    }

    final orderedDays =
        days.where((d) => grouped.containsKey(d)).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
      itemCount: orderedDays.length,
      itemBuilder: (ctx, di) {
        final day = orderedDays[di];
        final dayEntries = grouped[day]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.lg, bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    day,
                    style: AppTextStyles.headlineMd.copyWith(color: onSurface),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${dayEntries.length} class${dayEntries.length == 1 ? '' : 'es'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...dayEntries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _EntryTile(
                    entry: entry,
                    onEdit: () => onEdit(entry),
                    onDelete: () => onDelete(entry),
                  ),
                )),
          ],
        );
      },
    );
  }
}

// ── Entry Tile (dismissible) ──────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  final TimetableEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryTile({
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
    final primary =
        isDark ? AppColors.darkPrimary : AppColors.primary;

    return Dismissible(
      key: ValueKey(entry.id ?? '${entry.subject}_${entry.day}_${entry.startTime}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // dialog handles actual deletion
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutlineVariant
                    : AppColors.outlineVariant,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Time column
                SizedBox(
                  width: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.startTime,
                        style: AppTextStyles.labelMd.copyWith(
                            color: onSurface, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        entry.endTime,
                        style: AppTextStyles.bodySm
                            .copyWith(color: onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                ),
                // Subject info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.subject,
                        style: AppTextStyles.bodyLg.copyWith(
                            color: onSurface, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.room != null || entry.faculty != null)
                        Text(
                          [
                            if (entry.room != null) entry.room,
                            if (entry.faculty != null) entry.faculty,
                          ].join(' · '),
                          style: AppTextStyles.bodySm
                              .copyWith(color: onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: onSurfaceVariant, size: 18),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 16, color: primary),
                        const SizedBox(width: 8),
                        const Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        const Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
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

// ── Delete Confirmation Dialog ────────────────────────────────────────────────

class _DeleteDialog extends StatefulWidget {
  final TimetableEntry entry;
  final int futureSessionCount;
  final void Function(bool?) onChanged;

  const _DeleteDialog({
    required this.entry,
    required this.futureSessionCount,
    required this.onChanged,
  });

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _deleteSessions = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return AlertDialog(
      title: const Text('Remove Class?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
              children: [
                const TextSpan(text: 'Remove '),
                TextSpan(
                  text: '"${widget.entry.subject}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                    text: ' on ${widget.entry.day} '
                        '(${widget.entry.startTime}–${widget.entry.endTime}) '
                        'from your timetable?'),
              ],
            ),
          ),
          if (widget.futureSessionCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _deleteSessions,
                activeColor: AppColors.error,
                title: Text(
                  'Also delete ${widget.futureSessionCount} upcoming '
                  'session${widget.futureSessionCount == 1 ? '' : 's'} '
                  'that have not been marked yet',
                  style: AppTextStyles.bodySm,
                ),
                onChanged: (v) {
                  setState(() => _deleteSessions = v ?? true);
                  widget.onChanged(v);
                },
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onChanged(_deleteSessions);
            Navigator.pop(context, true);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final Color primary;
  final VoidCallback onAddManual;
  final VoidCallback onBuildWithSuggestions;
  // OCR import callback — disabled until OCR feature is ready
  // final VoidCallback onImport;

  const _EmptyBody({
    required this.primary,
    required this.onAddManual,
    required this.onBuildWithSuggestions,
    // required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No timetable entries yet',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add classes one by one or use the builder for\nsubject & teacher autocomplete suggestions.',
              style: AppTextStyles.bodyLg
                  .copyWith(color: onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBuildWithSuggestions,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Build with Suggestions'),
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
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddManual,
                icon: const Icon(Icons.add),
                label: const Text('Add Class Manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
            // OCR import button — disabled until OCR feature is ready
            // const SizedBox(height: AppSpacing.md),
            // SizedBox(
            //   width: double.infinity,
            //   child: OutlinedButton.icon(
            //     onPressed: onImport,
            //     icon: const Icon(Icons.document_scanner_outlined),
            //     label: const Text('Import from Photo / PDF'),
            //     style: OutlinedButton.styleFrom(
            //       foregroundColor: primary,
            //       side: BorderSide(color: primary),
            //       padding: const EdgeInsets.symmetric(
            //           vertical: AppSpacing.md),
            //       shape: RoundedRectangleBorder(
            //         borderRadius:
            //             BorderRadius.circular(AppSpacing.radiusMd),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

}

// ── Error Body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load timetable',
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTextStyles.bodySm, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
