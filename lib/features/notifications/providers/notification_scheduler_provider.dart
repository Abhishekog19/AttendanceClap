import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/profile/providers/profile_provider.dart';
import '../../../features/subjects/providers/subjects_provider.dart';
import '../../../features/timetable/providers/timetable_provider.dart';
import '../repositories/notification_preferences_repository.dart';
import '../scheduler/notification_scheduler.dart';
import 'notification_preferences_provider.dart';

part 'notification_scheduler_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Watches today's OVERRIDE-AWARE schedule + preferences + subjects + goal.
// Auto-reschedules whenever ANY of these change.
//
// TASK 5/6 FIX:
//   Previously watched `todaySessionsStreamProvider` (raw, no overrides).
//   Now watches `schedulePageDataProvider` which already applies daily overrides
//   via _applyOverrides(). If a class is cancelled or rescheduled via an override,
//   the scheduler will see the corrected merged list — not the raw timetable.
//
// This also means: adding/removing overrides automatically triggers reschedule,
// so phantom notifications for cancelled classes are cleaned up immediately.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<void> notificationSchedulerWatcher(Ref ref) async {
  // Watch the merged + override-aware schedule (SchedulePageData is computed
  // synchronously from todaySessionsStreamProvider + todayOverridesStreamProvider).
  final pageData = ref.watch(schedulePageDataProvider);
  final prefs = ref.watch(notificationPreferencesProvider);
  final subjectsAsync = ref.watch(subjectsNotifierProvider);
  final attendanceGoal = ref.watch(attendanceGoalProvider);
  final alertRepo = ref.watch(notificationPreferencesRepositoryProvider);

  // Reconstruct a flat, ordered session list from the bucketed SchedulePageData.
  // This is the same merged list the Schedule screen renders.
  final mergedSessions = [
    if (pageData.currentClass != null) pageData.currentClass!,
    ...pageData.upcoming,
    ...pageData.actionRequired,
    ...pageData.completedToday,
  ];

  final subjects = subjectsAsync.valueOrNull ?? [];

  await NotificationScheduler.instance.rescheduleAll(
    todaySessions: mergedSessions,
    prefs: prefs,
    subjects: subjects,
    attendanceGoal: attendanceGoal,
    alertRepo: alertRepo,
  );
}
