// ignore: unused_import  // TimeOfDay is used transitively by prefs fields
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../data/models/class_session_model.dart';
import '../../../data/models/subject_model.dart';
import '../models/notification_preferences_model.dart';
import '../models/app_notification_model.dart';
import '../repositories/app_notification_repository.dart';
import '../repositories/notification_preferences_repository.dart';
import '../services/notification_channels.dart';
import '../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationScheduler
//
// Coordinates scheduling / cancellation of all notification types.
// Stateless — all methods are pure functions over their inputs.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationScheduler {
  NotificationScheduler._();

  static final NotificationScheduler instance = NotificationScheduler._();

  final _svc = NotificationService.instance;

  // ── Public entry points ───────────────────────────────────────────────────

  /// Call after login, timetable changes, and on app start.
  Future<void> rescheduleAll({
    required List<ClassSession> todaySessions,
    required NotificationPreferences prefs,
    required List<SubjectModel> subjects,
    required double attendanceGoal, // from UserModel.attendanceGoal
    required NotificationPreferencesRepository alertRepo,
    AppNotificationRepository? notificationRepo,
  }) async {
    if (!prefs.notificationsEnabled) {
      await _svc.cancelAll();
      return;
    }

    await scheduleClassReminders(
        sessions: todaySessions, prefs: prefs);
    await scheduleAttendanceReminders(
        sessions: todaySessions, prefs: prefs);
    await scheduleSafeBunkPlanner(
        sessions: todaySessions,
        subjects: subjects,
        attendanceGoal: attendanceGoal,
        prefs: prefs);
    await scheduleDailySummary(
        sessions: todaySessions,
        subjects: subjects,
        prefs: prefs);
    await checkDailyAttendanceWarning(
        sessions: todaySessions,
        subjects: subjects,
        attendanceGoal: attendanceGoal,
        prefs: prefs,
        repo: alertRepo,
        notificationRepo: notificationRepo);
  }

  // ── Type 1: Class Reminders ───────────────────────────────────────────────

  Future<void> scheduleClassReminders({
    required List<ClassSession> sessions,
    required NotificationPreferences prefs,
  }) async {
    if (!prefs.classRemindersEnabled) return;

    final now = DateTime.now();
    final dateKey = _dateKey(now);

    // Sort sessions by start time
    final sorted = List<ClassSession>.from(sessions)
      ..sort((a, b) => _parseMinutes(a.displayStartTime)
          .compareTo(_parseMinutes(b.displayStartTime)));

    final unmarked = sorted
        .where((s) => !s.isCancelled && s.status == AttendanceStatus.notMarked)
        .toList();

    if (unmarked.isEmpty) return;

    // Determine which sessions qualify for a reminder
    final toRemind = <ClassSession>[];

    if (prefs.onlyFirstClassReminder) {
      // Only schedule the first class of the day
      final first = unmarked.firstOrNull;
      if (first != null) toRemind.add(first);
    } else {
      for (int i = 0; i < unmarked.length; i++) {
        if (i == 0) {
          // Always include first
          toRemind.add(unmarked[i]);
        } else if (prefs.gapClassRemindersEnabled) {
          // Include if gap from previous session is >= gapMinutes
          final prevEnd =
              _parseMinutes(unmarked[i - 1].displayEndTime);
          final currStart =
              _parseMinutes(unmarked[i].displayStartTime);
          if (currStart - prevEnd >= prefs.gapMinutes) {
            toRemind.add(unmarked[i]);
          }
        }
      }
    }

    for (final session in toRemind) {
      final startMin = _parseMinutes(session.displayStartTime);
      final reminderMin = startMin - prefs.reminderMinutes;
      final reminderTime = _todayAtMinutes(reminderMin, now);

      // Skip if already in the past
      if (reminderTime.isBefore(now)) continue;

      // Skip quiet hours
      if (prefs.isQuietHour(reminderTime)) continue;

      final isFirst = session == unmarked.first;
      final id = stableNotificationId('reminder_${session.id}_$dateKey') + 10000;

      // N5 FIX: Use consistent title+body pairs for first vs non-first class.
      // Before: both used the same body text; first-class title was misleading.
      final title = isFirst
          ? '📚 First class today'
          : '📚 ${session.displaySubjectName}';
      final body = isFirst
          ? '${session.displaySubjectName} starts in ${prefs.reminderMinutes} min'
          : 'Starts in ${prefs.reminderMinutes} min';

      await _svc.scheduleOnce(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
        channelId: NotificationChannels.classReminders,
        channelName: 'Class Reminders',
        payload: '${session.id}|${session.displaySubjectId}|$dateKey',
        actions: [
          const AndroidNotificationAction(
            'action_absent_today',
            '❌ Absent Today',
            cancelNotification: true,
          ),
        ],
      );
    }
  }

  // ── Type 2: Attendance Marking Reminders ──────────────────────────────────

  Future<void> scheduleAttendanceReminders({
    required List<ClassSession> sessions,
    required NotificationPreferences prefs,
  }) async {
    if (!prefs.attendanceRemindersEnabled) return;

    final now = DateTime.now();
    final dateKey = _dateKey(now);

    for (final session in sessions) {
      if (session.isCancelled) continue;
      if (session.status != AttendanceStatus.notMarked) continue;

      final endMin = _parseMinutes(session.displayEndTime);
      final fireMin = endMin + prefs.attendanceDelayMinutes;
      final fireTime = _todayAtMinutes(fireMin, now);

      // Skip already past
      if (fireTime.isBefore(now)) continue;
      // Skip quiet hours
      if (prefs.isQuietHour(fireTime)) continue;

      final id =
          stableNotificationId('attendance_${session.id}_$dateKey') + 20000;

      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_present',
          '✅ Present',
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'action_absent',
          '❌ Absent',
          cancelNotification: true,
        ),
        if (prefs.absentRestOfDayEnabled)
          const AndroidNotificationAction(
            'action_absent_rest_of_day',
            '🏠 Absent Rest of Day',
            cancelNotification: true,
          ),
      ];

      await _svc.scheduleOnce(
        id: id,
        title: '📝 Mark attendance — ${session.displaySubjectName}',
        body: 'Class ended. Did you attend?',
        scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
        channelId: NotificationChannels.attendanceActions,
        channelName: 'Attendance Actions',
        payload: '${session.id}|${session.displaySubjectId}|$dateKey',
        actions: actions,
      );
    }
  }

  // ── Type 3: Daily Aggregated Attendance Warning ───────────────────────────
  //
  // Generates AT MOST ONE warning per day, combining all below-threshold
  // subjects into a single notification. Fires 2h after the last session ends.
  // Subjects with 0% attendance (totalClasses == 0) are excluded.

  Future<void> checkDailyAttendanceWarning({
    required List<ClassSession> sessions,
    required List<SubjectModel> subjects,
    required double attendanceGoal,
    required NotificationPreferences prefs,
    required NotificationPreferencesRepository repo,
    AppNotificationRepository? notificationRepo,
  }) async {
    if (!prefs.lowAttendanceAlertsEnabled) return;

    // Dedup: only fire once per day
    final alreadyFiredToday = await repo.hasWarningFiredToday();
    if (alreadyFiredToday) {
      // ignore: avoid_print
      print('[NotificationScheduler] Daily warning already fired today — skipping.');
      return;
    }

    // Filter subjects: must have classes AND be below threshold
    final lowSubjects = subjects.where((s) {
      if (s.totalClasses == 0) return false; // Skip 0% (no data)
      return s.attendancePercentage < attendanceGoal;
    }).toList();

    if (lowSubjects.isEmpty) return;

    // Build aggregated message
    final lines = lowSubjects.map((s) {
      final classesNeeded = _classesNeededToRecover(
        attended: s.attendedClasses,
        total: s.totalClasses,
        target: attendanceGoal / 100,
      );
      return '• ${s.name} → Attend next $classesNeeded class${classesNeeded == 1 ? '' : 'es'}';
    }).join('\n');

    final title = '📊 Attendance Alert';
    final body = 'The following subjects are below your target:\n\n$lines';

    // Determine fire time: 2h after last session ends today
    final now = DateTime.now();
    DateTime fireTime;

    if (sessions.isNotEmpty) {
      // Find the latest end time among today's non-cancelled sessions
      final latestEndMinutes = sessions
          .where((s) => !s.isCancelled)
          .map((s) => _parseMinutes(s.displayEndTime))
          .fold(0, (max, v) => v > max ? v : max);

      final lastSessionEnd = _todayAtMinutes(latestEndMinutes, now);
      // Schedule 2h after last session, but no earlier than 5 minutes from now
      fireTime = lastSessionEnd.add(const Duration(hours: 2));
      if (fireTime.isBefore(now.add(const Duration(minutes: 5)))) {
        fireTime = now.add(const Duration(minutes: 5));
      }
    } else {
      // No sessions today — fire in 5 minutes as a fallback
      fireTime = now.add(const Duration(minutes: 5));
    }

    // Skip quiet hours
    if (prefs.isQuietHour(fireTime)) {
      // ignore: avoid_print
      print('[NotificationScheduler] Warning suppressed — quiet hours.');
      return;
    }

    // Stable notification ID for today (avoids duplicates on system tray)
    final dateKey = _dateKey(now);
    final notifId = stableNotificationId('daily_warning_$dateKey') + 50000;

    await _svc.scheduleOnce(
      id: notifId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
      channelId: NotificationChannels.attendanceAlerts,
      channelName: 'Attendance Alerts',
      bigText: true,
    );

    // N1 FIX: Record the dedup flag BEFORE writing the notification.
    // Previously the flag was set AFTER the write, so two concurrent scheduler
    // calls could both pass the hasWarningFiredToday() check before either set
    // the flag — resulting in duplicate Firestore notification documents.
    // Setting it first ensures idempotency: if a second call runs before the
    // first finishes, it will see the flag already set and skip.
    await repo.recordDailyWarningFired();

    // Record in Firestore notification center (if repo provided)
    if (notificationRepo != null) {
      final centerId = 'attendanceWarning_$dateKey';
      final alreadyStored = await notificationRepo.notificationExists(centerId);
      if (!alreadyStored) {
        await notificationRepo.addNotification(AppNotificationModel(
          id: centerId,
          title: title,
          message: body,
          type: AppNotificationType.attendanceWarning,
          createdAt: DateTime.now(),
          isRead: false,
        ));
      }
    }

    // ignore: avoid_print
    print('[NotificationScheduler] Daily warning scheduled for $fireTime — ${lowSubjects.length} subjects.');
  }

  // ── Type 4: Safe Bunk Planner ─────────────────────────────────────────────

  Future<void> scheduleSafeBunkPlanner({
    required List<ClassSession> sessions,
    required List<SubjectModel> subjects,
    required double attendanceGoal,
    required NotificationPreferences prefs,
  }) async {
    if (!prefs.safeBunkPlannerEnabled) return;

    // Cancel previous planner notification
    await _svc.cancelNotification(NotificationChannels.plannerNotificationId);

    // Build safe-bunk map from subject data
    final safeBunksPerSubject = <String, int>{};
    final riskSubjects = <String>[];

    for (final subject in subjects) {
      final bunks = _safeBunkCount(
        attended: subject.attendedClasses,
        total: subject.totalClasses,
        target: attendanceGoal / 100,
      );
      safeBunksPerSubject[subject.name] = bunks;
      if (bunks == 0 && prefs.includeRiskSubjects) {
        riskSubjects.add(subject.name);
      }
    }

    final hasBunks = safeBunksPerSubject.values.any((v) => v > 0);

    final title = hasBunks
        ? '🎉 Safe Bunks Available Tomorrow'
        : '⚠️ No safe bunks available tomorrow';

    String body;
    if (!hasBunks) {
      body = 'Stay on track — attend all classes tomorrow.';
    } else {
      final entries = safeBunksPerSubject.entries
          .where((e) => prefs.includeSafeBunks || e.value == 0)
          .map((e) => e.value == 0
              ? '${e.key} → No safe bunk'
              : '${e.key} → ${e.value} safe bunk${e.value > 1 ? 's' : ''}')
          .join('\n');
      body = entries.isNotEmpty ? entries : 'Check app for details';
    }

    await _svc.scheduleDaily(
      id: NotificationChannels.plannerNotificationId,
      title: title,
      body: body,
      time: prefs.plannerTime,
      channelId: NotificationChannels.planningInsights,
      channelName: 'Planning & Insights',
      bigText: true,
    );
  }

  // ── Type 5: Daily Summary ─────────────────────────────────────────────────

  Future<void> scheduleDailySummary({
    required List<ClassSession> sessions,
    required List<SubjectModel> subjects,
    required NotificationPreferences prefs,
  }) async {
    if (!prefs.dailySummaryEnabled) {
      await _svc.cancelNotification(NotificationChannels.summaryNotificationId);
      return;
    }

    // Calculate today's stats
    final attended =
        sessions.where((s) => s.status == AttendanceStatus.present).length;
    final missed =
        sessions.where((s) => s.status == AttendanceStatus.absent).length;
    final total = subjects.fold<int>(0, (s, sub) => s + sub.totalClasses);
    final totalAttended =
        subjects.fold<int>(0, (s, sub) => s + sub.attendedClasses);
    final overall = total == 0 ? 0.0 : (totalAttended / total) * 100;

    final bodyLines = <String>[];
    if (prefs.includeClassesAttended) bodyLines.add('✅ Attended: $attended');
    if (prefs.includeClassesMissed) bodyLines.add('❌ Missed: $missed');
    if (prefs.includeOverallAttendance) {
      bodyLines.add('Overall: ${overall.toStringAsFixed(1)}%');
    }

    await _svc.scheduleDaily(
      id: NotificationChannels.summaryNotificationId,
      title: "Today's Attendance Summary",
      body: bodyLines.join('   '),
      time: prefs.summaryTime,
      channelId: NotificationChannels.planningInsights,
      channelName: 'Planning & Insights',
      bigText: true,
    );
  }

  // ── Cancel today's reminders ──────────────────────────────────────────────

  Future<void> cancelTodayReminders(List<ClassSession> sessions) async {
    final dateKey = _dateKey(DateTime.now());
    for (final session in sessions) {
      await _svc.cancelNotification(
          stableNotificationId('reminder_${session.id}_$dateKey') + 10000);
      await _svc.cancelNotification(
          stableNotificationId('attendance_${session.id}_$dateKey') + 20000);
    }
  }

  // ── Safe bunk calculation ─────────────────────────────────────────────────

  /// Returns how many more classes can be missed while staying above [target].
  static int _safeBunkCount({
    required int attended,
    required int total,
    required double target, // 0..1
  }) {
    if (total == 0) return 0;
    // attended / (total + bunks) >= target
    // => bunks <= attended/target - total
    final maxBunks = (attended / target) - total;
    return maxBunks < 0 ? 0 : maxBunks.floor();
  }

  /// Returns how many consecutive classes are needed to recover to [target].
  static int _classesNeededToRecover({
    required int attended,
    required int total,
    required double target, // 0..1
  }) {
    // (attended + n) / (total + n) >= target
    // => n(1 - target) >= target * total - attended
    final diff = target * total - attended;
    if (diff <= 0) return 0;
    final needed = (diff / (1 - target)).ceil();
    return needed;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _parseMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static DateTime _todayAtMinutes(int minutes, DateTime base) {
    return DateTime(
        base.year, base.month, base.day, minutes ~/ 60, minutes % 60);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
