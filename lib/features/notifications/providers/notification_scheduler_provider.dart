import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../features/subjects/providers/subjects_provider.dart';
import '../../../features/timetable/providers/manual_timetable_provider.dart';
import '../../../features/timetable/providers/timetable_provider.dart';
import '../repositories/app_notification_repository.dart';
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
// BUNK PLANNER TOMORROW FILTER:
//   Watches `timetableEntriesStreamProvider` to compute tomorrow's subject IDs.
//   Only subjects with safeBunks > 0 AND a lecture tomorrow are notified.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<void> notificationSchedulerWatcher(Ref ref) async {
  // Watch the merged + override-aware schedule for today
  final pageData = ref.watch(schedulePageDataProvider);
  final prefs = ref.watch(notificationPreferencesProvider);
  final subjectsAsync = ref.watch(subjectsNotifierProvider);
  final attendanceGoal = ref.watch(attendanceGoalProvider);
  final alertRepo = ref.watch(notificationPreferencesRepositoryProvider);
  final notifRepo = ref.watch(appNotificationRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  // Compute tomorrow's subject IDs from timetable entries
  final allEntries =
      ref.watch(timetableEntriesStreamProvider).valueOrNull ?? [];
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final tomorrowDayName = _weekdayName(tomorrow.weekday);
  final tomorrowSubjectIds = allEntries
      .where((e) =>
          e.day.toLowerCase() == tomorrowDayName.toLowerCase() &&
          e.subjectId != null)
      .map((e) => e.subjectId!)
      .toSet();

  // Reconstruct a flat, ordered session list from the bucketed SchedulePageData.
  final mergedSessions = [
    if (pageData.currentClass != null) pageData.currentClass!,
    ...pageData.upcoming,
    ...pageData.actionRequired,
    ...pageData.completedToday,
  ];

  final subjects = subjectsAsync.valueOrNull ?? [];
  final currentUserId = currentUser?.uid ?? '';

  await NotificationScheduler.instance.rescheduleAll(
    todaySessions: mergedSessions,
    prefs: prefs,
    subjects: subjects,
    attendanceGoal: attendanceGoal,
    alertRepo: alertRepo,
    notificationRepo: notifRepo,
    currentUserId: currentUserId,
    tomorrowSubjectIds: tomorrowSubjectIds,
  );
}

/// Converts DateTime.weekday (1=Monday … 7=Sunday) to a day name string
/// matching the TimetableEntry.day field format ("Monday", "Tuesday", etc.).
String _weekdayName(int weekday) => const [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][weekday];
