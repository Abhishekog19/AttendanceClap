import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../data/models/subject_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/attendance_history_provider.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final logsAsync = ref.watch(attendanceLogsStreamProvider);
    final grouped = ref.watch(groupedLogsProvider);
    final stats = ref.watch(filteredStatsProvider);
    final filter = ref.watch(attendanceFilterNotifierProvider);
    final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Attendance History',
            style: AppTextStyles.headlineMd.copyWith(color: primary)),
        actions: [
          if (filter.isActive)
            IconButton(
              icon: Icon(Icons.filter_alt_off_outlined, color: primary),
              tooltip: 'Clear filters',
              onPressed: () =>
                  ref.read(attendanceFilterNotifierProvider.notifier).clear(),
            ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const _HistorySkeleton(),
        error: (e, st) => _ErrorState(error: e.toString()),
        data: (_) => _HistoryBody(
          isDark: isDark,
          primary: primary,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          grouped: grouped,
          stats: stats,
          filter: filter,
          subjects: subjects,
        ),
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _HistoryBody extends ConsumerWidget {
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Map<String, List<AttendanceLogModel>> grouped;
  final AttendanceStats stats;
  final AttendanceFilter filter;
  final List<SubjectModel> subjects;

  const _HistoryBody({
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.grouped,
    required this.stats,
    required this.filter,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        // ── Stats Strip ──────────────────────────────────────────────────────
        _StatsStrip(stats: stats, isDark: isDark, primary: primary),

        // ── Filter Row ───────────────────────────────────────────────────────
        _FilterRow(
            isDark: isDark, primary: primary, filter: filter, subjects: subjects),

        const Divider(height: 1),

        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: grouped.isEmpty
              ? _EmptyState(filter: filter, isDark: isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
                  itemCount: sortedKeys.length,
                  itemBuilder: (ctx, i) {
                    final dateKey = sortedKeys[i];
                    final logs = grouped[dateKey]!;
                    return _DateGroup(
                      dateKey: dateKey,
                      logs: logs,
                      isDark: isDark,
                      primary: primary,
                      onSurface: onSurface,
                      onSurfaceVariant: onSurfaceVariant,
                      subjects: subjects,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final AttendanceStats stats;
  final bool isDark;
  final Color primary;

  const _StatsStrip(
      {required this.stats, required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLow;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
              label: 'Total',
              value: '${stats.total}',
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
          _StatChip(
              label: 'Present',
              value: '${stats.present}',
              color: AppColors.success),
          _StatChip(
              label: 'Absent',
              value: '${stats.absent}',
              color: AppColors.error),
          _StatChip(
              label: 'Late',
              value: '${stats.late}',
              color: AppColors.warning),
          _StatChip(
              label: 'Rate',
              value: '${stats.percentage.toStringAsFixed(0)}%',
              color: primary),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.headlineMd
                .copyWith(color: color, fontWeight: FontWeight.w700)),
        Text(label,
            style: AppTextStyles.labelCaps.copyWith(
                color: color.withAlpha(180), fontSize: 9)),
      ],
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  final bool isDark;
  final Color primary;
  final AttendanceFilter filter;
  final List<SubjectModel> subjects;

  const _FilterRow({
    required this.isDark,
    required this.primary,
    required this.filter,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(attendanceFilterNotifierProvider.notifier);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Subject dropdown
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: PopupMenuButton<String?>(
              initialValue: filter.subjectId,
              onSelected: notifier.setSubject,
              itemBuilder: (_) => [
                const PopupMenuItem<String?>(
                    value: null, child: Text('All Subjects')),
                ...subjects.map((s) =>
                    PopupMenuItem<String?>(value: s.id, child: Text(s.name))),
              ],
              child: _FilterChip(
                label: filter.subjectId == null
                    ? 'Subject'
                    : subjects
                            .where((s) => s.id == filter.subjectId)
                            .firstOrNull
                            ?.name ??
                        'Subject',
                icon: Icons.menu_book_outlined,
                active: filter.subjectId != null,
                isDark: isDark,
                primary: primary,
              ),
            ),
          ),

          // Status filter
          ...AttendanceStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: GestureDetector(
                  onTap: () => notifier.setStatus(
                      filter.status == s ? null : s),
                  child: _FilterChip(
                    label: _statusLabel(s),
                    icon: _statusIcon(s),
                    active: filter.status == s,
                    isDark: isDark,
                    primary: _statusColor(s),
                  ),
                ),
              )),

          // Date range presets
          ...DateRangePreset.values
              .where((p) => p != DateRangePreset.custom)
              .map((p) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: GestureDetector(
                      onTap: () => notifier.setDateRange(
                          filter.dateRange == p
                              ? DateRangePreset.all
                              : p),
                      child: _FilterChip(
                        label: _presetLabel(p),
                        icon: Icons.calendar_today_outlined,
                        active: filter.dateRange == p,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                  )),

          // Custom date range
          GestureDetector(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (range != null) {
                notifier.setCustomRange(range.start, range.end);
              }
            },
            child: _FilterChip(
              label: filter.dateRange == DateRangePreset.custom &&
                      filter.customStart != null
                  ? '${DateFormat('d MMM').format(filter.customStart!)} – ${DateFormat('d MMM').format(filter.customEnd!)}'
                  : 'Custom',
              icon: Icons.date_range_outlined,
              active: filter.dateRange == DateRangePreset.custom,
              isDark: isDark,
              primary: primary,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.cancelled => 'Cancelled',
      };

  IconData _statusIcon(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => Icons.check_circle_outline,
        AttendanceStatus.absent => Icons.cancel_outlined,
        AttendanceStatus.late => Icons.access_time,
        AttendanceStatus.cancelled => Icons.event_busy_outlined,
      };

  Color _statusColor(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => AppColors.success,
        AttendanceStatus.absent => AppColors.error,
        AttendanceStatus.late => AppColors.warning,
        AttendanceStatus.cancelled => AppColors.outline,
      };

  String _presetLabel(DateRangePreset p) => switch (p) {
        DateRangePreset.today => 'Today',
        DateRangePreset.thisWeek => 'This Week',
        DateRangePreset.thisMonth => 'This Month',
        DateRangePreset.custom => 'Custom',
        DateRangePreset.all => 'All',
      };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isDark;
  final Color primary;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? primary.withAlpha(30)
            : (isDark
                ? AppColors.darkSurfaceContainerHigh
                : AppColors.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: active ? primary : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: active ? primary : AppColors.outline),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: active ? primary : AppColors.outline,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Group ────────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  final String dateKey;
  final List<AttendanceLogModel> logs;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final List<SubjectModel> subjects;

  const _DateGroup({
    required this.dateKey,
    required this.logs,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateKey);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final label = isToday
        ? 'Today'
        : DateFormat('EEEE, d MMMM y').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: isToday
                      ? primary.withAlpha(20)
                      : (isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: isToday
                      ? Border.all(color: primary.withAlpha(60))
                      : null,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isToday ? primary : onSurfaceVariant,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('${logs.length} class${logs.length > 1 ? 'es' : ''}',
                  style:
                      AppTextStyles.labelMd.copyWith(color: onSurfaceVariant)),
            ],
          ),
        ),
        ...logs.map((log) => _LogTile(
              log: log,
              isDark: isDark,
              primary: primary,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
              subjects: subjects,
            )),
      ],
    );
  }
}

// ── Log Tile ──────────────────────────────────────────────────────────────────

class _LogTile extends ConsumerWidget {
  final AttendanceLogModel log;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final List<SubjectModel> subjects;

  const _LogTile({
    required this.log,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;

    final subjectName = log.subjectName ??
        subjects.where((s) => s.id == log.subjectId).firstOrNull?.name ??
        'Unknown Subject';

    final timeLabel = log.startTime != null
        ? '${log.startTime} – ${log.endTime ?? ''}'
        : DateFormat('h:mm a').format(log.date);

    final statusColor = _statusColor(log.status);
    final statusIcon = _statusIcon(log.status);
    final statusLabel = _statusLabel(log.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Subject + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subjectName,
                    style: AppTextStyles.bodyLg
                        .copyWith(color: onSurface, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(timeLabel,
                    style:
                        AppTextStyles.bodySm.copyWith(color: onSurfaceVariant)),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: statusColor.withAlpha(60)),
            ),
            child: Text(statusLabel,
                style: AppTextStyles.labelMd.copyWith(
                    color: statusColor, fontWeight: FontWeight.w600)),
          ),

          // Action menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: onSurfaceVariant, size: 18),
            onSelected: (v) {
              if (v == 'edit') {
                _showEditDialog(context, ref, log, subjects);
              } else if (v == 'delete') {
                _showDeleteDialog(context, ref, log, subjectName);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Status')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref,
      AttendanceLogModel log, List<SubjectModel> subjects) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditLogSheet(log: log),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref,
      AttendanceLogModel log, String subjectName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text(
            'Delete $subjectName attendance on ${DateFormat('d MMM y').format(log.date)}? This will update your subject\'s counter.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(logEditNotifierProvider.notifier).deleteLog(log);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Record deleted'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => AppColors.success,
        AttendanceStatus.absent => AppColors.error,
        AttendanceStatus.late => AppColors.warning,
        AttendanceStatus.cancelled => AppColors.outline,
      };

  IconData _statusIcon(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => Icons.check_circle_rounded,
        AttendanceStatus.absent => Icons.cancel_rounded,
        AttendanceStatus.late => Icons.access_time_filled,
        AttendanceStatus.cancelled => Icons.event_busy_rounded,
      };

  String _statusLabel(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.cancelled => 'Cancelled',
      };
}

// ── Edit Log Bottom Sheet ─────────────────────────────────────────────────────

class _EditLogSheet extends ConsumerWidget {
  final AttendanceLogModel log;
  const _EditLogSheet({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final notifier = ref.read(logEditNotifierProvider.notifier);
    final state = ref.watch(logEditNotifierProvider);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Attendance',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
          const SizedBox(height: AppSpacing.md),
          Text('Select new status:',
              style: AppTextStyles.bodyLg
                  .copyWith(color: AppColors.darkOnSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: AttendanceStatus.values.map((s) {
              final color = _statusColor(s);
              final selected = log.status == s;
              return GestureDetector(
                onTap: () async {
                  if (s == log.status) return;
                  await notifier.updateLog(log.copyWith(status: s), log.status);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Updated to ${s.name}'),
                      backgroundColor: color,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: selected ? color.withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: selected ? color : AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(s), color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(s.name[0].toUpperCase() + s.name.substring(1),
                          style: AppTextStyles.labelMd.copyWith(
                              color: color,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (state.status == LogEditStatus.saving) ...[
            const SizedBox(height: AppSpacing.md),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => AppColors.success,
        AttendanceStatus.absent => AppColors.error,
        AttendanceStatus.late => AppColors.warning,
        AttendanceStatus.cancelled => AppColors.outline,
      };

  IconData _statusIcon(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => Icons.check_circle_rounded,
        AttendanceStatus.absent => Icons.cancel_rounded,
        AttendanceStatus.late => Icons.access_time_filled,
        AttendanceStatus.cancelled => Icons.event_busy_rounded,
      };
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AttendanceFilter filter;
  final bool isDark;
  const _EmptyState({required this.filter, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final title =
        filter.isActive ? 'No results' : 'No attendance records yet';
    final subtitle = filter.isActive
        ? 'Try adjusting your filters'
        : 'Mark attendance from the Timetable tab to see records here';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 64, color: onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: AppTextStyles.headlineMd
                    .copyWith(color: onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                style:
                    AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends ConsumerWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Failed to load history',
                style: AppTextStyles.headlineMd.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSpacing.sm),
            Text(error,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => ref.invalidate(attendanceLogsStreamProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        height: 70,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
