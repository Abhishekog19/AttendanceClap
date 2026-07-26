import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/class_session_model.dart';
import '../../../data/models/daily_schedule_override_model.dart';
import '../../../data/repositories/local_attendance_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/timetable_provider.dart';

class EditTodayScheduleSheet extends ConsumerStatefulWidget {
  final List<ClassSession> sessions;

  const EditTodayScheduleSheet({super.key, required this.sessions});

  @override
  ConsumerState<EditTodayScheduleSheet> createState() =>
      _EditTodayScheduleSheetState();
}

class _EditTodayScheduleSheetState
    extends ConsumerState<EditTodayScheduleSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;


    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Today\'s Schedule',
                    style: AppTextStyles.headlineMd.copyWith(color: onSurface),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.close, color: onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Changes apply to today only and do not affect your semester timetable.',
                style: AppTextStyles.bodySm
                    .copyWith(color: onSurfaceVariant),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ...widget.sessions.map((session) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.md),
                        child: _SessionEditTile(
                          session: session,
                          isDark: isDark,
                          onChangeSubject: () => _showChangeSubjectDialog(
                              context, session),
                          onReschedule: () =>
                              _showRescheduleDialog(context, session),
                          onCancel: () => _cancelSession(session),
                          onRestore: () => _restoreSession(session),
                        ),
                      )),
                  // Add Extra Period button
                  // Add Extra Period — DISABLED until Phase 5 implements
                  // the anchoring class_sessions row for addExtra overrides.
                  // TODO(Phase 5): re-enable and call _showAddExtraDialog.
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Extra Period (Coming Soon)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelSession(ClassSession session) async {
    final override = DailyScheduleOverride(
      id: const Uuid().v4(),
      sessionId: session.id,
      uid: session.uid,
      date: session.date,
      type: OverrideType.cancel,
      isCancelled: true,
      createdAt: DateTime.now(),
    );
    await ref.read(scheduleNotifierProvider.notifier).saveOverride(override);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${session.displaySubjectName} marked as cancelled'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restoreSession(ClassSession session) async {
    // Delete the cancel override for this session
    final overrides = await ref
        .read(localAttendanceRepositoryProvider)
        .getDailyOverridesForDate(session.date);

    final cancelOverride = overrides.where(
      (o) => o.sessionId == session.id && o.type == OverrideType.cancel,
    ).firstOrNull;

    if (cancelOverride != null) {
      await ref
          .read(scheduleNotifierProvider.notifier)
          .deleteOverride(cancelOverride.id, session.date);
    }
  }

  Future<void> _showChangeSubjectDialog(
      BuildContext context, ClassSession session) async {
    final subjects = ref.read(subjectsStreamProvider).valueOrNull ?? [];
    if (subjects.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;

    String? selectedId;
    String? selectedName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: bg,
          title: const Text('Change Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the subject that will be taught instead of '
                '"${session.displaySubjectName}" today.',
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: AppSpacing.md),
              ...subjects.map(
                (s) => RadioListTile<String>(
                  title: Text(s.name),
                  value: s.id,
                  // ignore: deprecated_member_use
                  groupValue: selectedId,
                  dense: true,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setS(() {
                    selectedId = v;
                    selectedName = s.name;
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: selectedId == null
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const Text('Apply')),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        selectedId != null &&
        selectedName != null &&
        mounted) {
      final override = DailyScheduleOverride(
        id: const Uuid().v4(),
        sessionId: session.id,
        uid: session.uid,
        date: session.date,
        type: OverrideType.changeSubject,
        newSubjectId: selectedId,
        newSubjectName: selectedName,
        createdAt: DateTime.now(),
      );
      await ref.read(scheduleNotifierProvider.notifier).saveOverride(override);
      if (mounted) {
        ScaffoldMessenger.of(context) // ignore: use_build_context_synchronously
            .showSnackBar(
          SnackBar(
            content: Text('Subject changed to $selectedName for today'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRescheduleDialog(
      BuildContext context, ClassSession session) async {
    TimeOfDay startTime = _parseTimeOfDay(session.displayStartTime);
    TimeOfDay endTime = _parseTimeOfDay(session.displayEndTime);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Reschedule Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adjust the time slot for "${session.displaySubjectName}" today.',
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: startTime,
                            );
                            if (t != null) setS(() => startTime = t);
                          },
                          child: Text(_formatTimeOfDay(startTime)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: endTime,
                            );
                            if (t != null) setS(() => endTime = t);
                          },
                          child: Text(_formatTimeOfDay(endTime)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Apply')),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final override = DailyScheduleOverride(
        id: const Uuid().v4(),
        sessionId: session.id,
        uid: session.uid,
        date: session.date,
        type: OverrideType.reschedule,
        newStartTime: _formatTimeOfDay(startTime),
        newEndTime: _formatTimeOfDay(endTime),
        createdAt: DateTime.now(),
      );
      await ref.read(scheduleNotifierProvider.notifier).saveOverride(override);
      if (mounted) {
        ScaffoldMessenger.of(context) // ignore: use_build_context_synchronously
            .showSnackBar(
          SnackBar(
            content: Text(
                '${session.displaySubjectName} rescheduled to '
                '${_formatTimeOfDay(startTime)}–${_formatTimeOfDay(endTime)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  TimeOfDay _parseTimeOfDay(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
//  Session Edit Tile
// ─────────────────────────────────────────────────────────────────────────────

class _SessionEditTile extends StatelessWidget {
  final ClassSession session;
  final bool isDark;
  final VoidCallback onChangeSubject;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback onRestore;

  const _SessionEditTile({
    required this.session,
    required this.isDark,
    required this.onChangeSubject,
    required this.onReschedule,
    required this.onCancel,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerLowest;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final isCancelled = session.isCancelled;
    final isOverridden = session.overrideSubjectName != null ||
        session.overrideStartTime != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isCancelled
              ? AppColors.error.withValues(alpha: 0.3)
              : isOverridden
                  ? primary.withValues(alpha: 0.3)
                  : onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayStartTime,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isCancelled
                        ? onSurfaceVariant
                        : onSurface,
                    fontWeight: FontWeight.bold,
                    decoration: isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                Text(
                  session.displayEndTime,
                  style: AppTextStyles.bodySm
                      .copyWith(color: onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: onSurfaceVariant.withValues(alpha: 0.2),
            margin:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displaySubjectName,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: isCancelled
                        ? onSurfaceVariant
                        : onSurface,
                    fontWeight: FontWeight.w600,
                    decoration: isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isOverridden && !isCancelled)
                  Text(
                    'Modified',
                    style: AppTextStyles.bodySm
                        .copyWith(color: primary, fontSize: 10),
                  ),
                if (isCancelled)
                  Text(
                    'Cancelled',
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.error, fontSize: 10),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: onSurfaceVariant, size: 20),
            onSelected: (v) {
              switch (v) {
                case 'change_subject':
                  onChangeSubject();
                case 'reschedule':
                  onReschedule();
                case 'cancel':
                  onCancel();
                case 'restore':
                  onRestore();
              }
            },
            itemBuilder: (_) => [
              if (!isCancelled) ...[
                PopupMenuItem(
                  value: 'change_subject',
                  child: Row(children: [
                    Icon(Icons.swap_horiz, size: 16, color: primary),
                    const SizedBox(width: 8),
                    const Text('Change Subject'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'reschedule',
                  child: Row(children: [
                    Icon(Icons.schedule, size: 16, color: primary),
                    const SizedBox(width: 8),
                    const Text('Reschedule Time'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(children: [
                    Icon(Icons.block,
                        size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Cancel Period',
                        style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ] else
                PopupMenuItem(
                  value: 'restore',
                  child: Row(children: [
                    Icon(Icons.restore, size: 16, color: primary),
                    const SizedBox(width: 8),
                    const Text('Restore Period'),
                  ]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
