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
// Watches today's sessions + preferences + subjects + attendance goal.
// Auto-reschedules whenever any of these change.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<void> notificationSchedulerWatcher(Ref ref) async {
  // Watch all data sources — any change triggers a full reschedule
  final sessionsAsync = ref.watch(todaySessionsStreamProvider);
  final prefs = ref.watch(notificationPreferencesProvider);
  final subjectsAsync = ref.watch(subjectsNotifierProvider);
  final attendanceGoal = ref.watch(attendanceGoalProvider);
  final alertRepo = ref.watch(notificationPreferencesRepositoryProvider);

  final sessions = sessionsAsync.valueOrNull ?? [];
  final subjects = subjectsAsync.valueOrNull ?? [];

  if (!prefs.notificationsEnabled) {
    await NotificationScheduler.instance.rescheduleAll(
      todaySessions: [],
      prefs: prefs,
      subjects: subjects,
      attendanceGoal: attendanceGoal,
      alertRepo: alertRepo,
    );
    return;
  }

  await NotificationScheduler.instance.rescheduleAll(
    todaySessions: sessions,
    prefs: prefs,
    subjects: subjects,
    attendanceGoal: attendanceGoal,
    alertRepo: alertRepo,
  );
}
