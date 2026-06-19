// ignore: unused_import  // TimeOfDay is used transitively by prefs fields
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../data/models/class_session_model.dart';
import '../../../data/models/subject_model.dart';
import '../models/app_notification_model.dart';
import '../models/notification_preferences_model.dart';
import '../repositories/app_notification_repository.dart';
import '../repositories/notification_preferences_repository.dart';
import '../services/notification_channels.dart';
import '../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationScheduler
//
// Coordinates scheduling / cancellation of all notification types.
// Stateless — all methods are pure functions over their inputs.
//
// Persistent types (Firestore notification center):
//   attendanceDanger    — checkDailyAttendanceAlerts()
//   criticalAttendance  — checkDailyAttendanceAlerts()
//   nightlyBunkPlanner  — scheduleSafeBunkPlanner()
//
// Device-only types (system tray only, NOT stored):
//   classReminders      — scheduleClassReminders()
//   attendanceActions   — scheduleAttendanceReminders()
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
    required String currentUserId,
    Set<String> tomorrowSubjectIds = const {},
  }) async {
    if (!prefs.notificationsEnabled) {
      await _svc.cancelAll();
      return;
    }

    await scheduleClassReminders(sessions: todaySessions, prefs: prefs);
    await scheduleAttendanceReminders(sessions: todaySessions, prefs: prefs);
    await scheduleSafeBunkPlanner(
      sessions: todaySessions,
      subjects: subjects,
      attendanceGoal: attendanceGoal,
      prefs: prefs,
      tomorrowSubjectIds: tomorrowSubjectIds,
      currentUserId: currentUserId,
      notificationRepo: notificationRepo,
    );
    // Daily Summary was removed — cancel any stale device notification.
    await _svc.cancelNotification(NotificationChannels.summaryNotificationId);
    await checkDailyAttendanceAlerts(
      sessions: todaySessions,
      subjects: subjects,
      attendanceGoal: attendanceGoal,
      prefs: prefs,
      repo: alertRepo,
      notificationRepo: notificationRepo,
      currentUserId: currentUserId,
    );
  }

  // ── Type 1: Class Reminders (device-only) ────────────────────────────────

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
      final first = unmarked.firstOrNull;
      if (first != null) toRemind.add(first);
    } else {
      for (int i = 0; i < unmarked.length; i++) {
        if (i == 0) {
          toRemind.add(unmarked[i]);
        } else if (prefs.gapClassRemindersEnabled) {
          final prevEnd = _parseMinutes(unmarked[i - 1].displayEndTime);
          final currStart = _parseMinutes(unmarked[i].displayStartTime);
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

      if (reminderTime.isBefore(now)) continue;
      if (prefs.isQuietHour(reminderTime)) continue;

      final isFirst = session == unmarked.first;
      final id = stableNotificationId('reminder_${session.id}_$dateKey') + 10000;

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

  // ── Type 2: Attendance Marking Reminders (device-only) ───────────────────

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

      if (fireTime.isBefore(now)) continue;
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

  // ── Type 3: Daily Attendance Alerts (Firestore + device) ─────────────────
  //
  // Generates AT MOST ONE danger warning per day AND AT MOST ONE critical
  // warning per day. Both are stored in the notification center.
  // Danger:   attendance < attendanceGoal
  // Critical: attendance < prefs.criticalThreshold (configurable, e.g. 65%)

  Future<void> checkDailyAttendanceAlerts({
    required List<ClassSession> sessions,
    required List<SubjectModel> subjects,
    required double attendanceGoal,
    required NotificationPreferences prefs,
    required NotificationPreferencesRepository repo,
    AppNotificationRepository? notificationRepo,
    required String currentUserId,
  }) async {
    final now = DateTime.now();
    final dateKey = _dateKey(now);

    // ── Danger warning (below attendanceGoal) ───────────────────────────────

    if (prefs.lowAttendanceAlertsEnabled) {
      final alreadyFiredToday = await repo.hasWarningFiredToday();
      if (!alreadyFiredToday) {
        final lowSubjects = subjects.where((s) {
          if (s.totalClasses == 0) return false;
          return s.attendancePercentage < attendanceGoal;
        }).toList();

        if (lowSubjects.isNotEmpty) {
          final lines = lowSubjects.map((s) {
            final classesNeeded = _classesNeededToRecover(
              attended: s.attendedClasses,
              total: s.totalClasses,
              target: attendanceGoal / 100,
            );
            return '• ${s.name} → Attend next $classesNeeded class${classesNeeded == 1 ? '' : 'es'}';
          }).join('\n');

          const title = '📊 Attendance Alert';
          final body =
              'The following subjects are below your target:\n\n$lines';

          DateTime fireTime = _computeFireTime(sessions, now);
          if (!prefs.isQuietHour(fireTime)) {
            final dangerNotifId =
                stableNotificationId('daily_danger_$dateKey') + 50000;

            await _svc.scheduleOnce(
              id: dangerNotifId,
              title: title,
              body: body,
              scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
              channelId: NotificationChannels.attendanceAlerts,
              channelName: 'Attendance Alerts',
              bigText: true,
            );

            // Record dedup flag BEFORE Firestore write to prevent race condition
            await repo.recordDailyWarningFired();

            if (notificationRepo != null && currentUserId.isNotEmpty) {
              final centerId = 'attendanceDanger_$dateKey';
              final alreadyStored =
                  await notificationRepo.notificationExists(centerId);
              if (!alreadyStored) {
                await notificationRepo.addNotification(AppNotificationModel(
                  id: centerId,
                  userId: currentUserId,
                  title: title,
                  message: body,
                  type: AppNotificationType.attendanceDanger,
                  priority: NotificationPriority.high,
                  createdAt: now,
                  isRead: false,
                ));
              }
            }

            // ignore: avoid_print
            print('[NotificationScheduler] Danger warning scheduled for $fireTime — ${lowSubjects.length} subjects.');
          }
        }
      }
    }

    // ── Critical attendance alert (below criticalThreshold) ─────────────────

    if (prefs.criticalAttendanceEnabled) {
      final alreadyCriticalFiredToday = await repo.hasCriticalFiredToday();
      if (alreadyCriticalFiredToday) {
        // ignore: avoid_print
        print('[NotificationScheduler] Critical alert already fired today — skipping.');
      } else {

        final criticalSubjects = subjects.where((s) {
          if (s.totalClasses == 0) return false;
          return s.attendancePercentage < prefs.criticalThreshold;
        }).toList();

        if (criticalSubjects.isNotEmpty) {
          final criticalLines = criticalSubjects.map((s) {
            return '• ${s.name} → ${s.attendancePercentage.toStringAsFixed(1)}%';
          }).join('\n');

          const criticalTitle = '🚨 Critical Attendance Alert';
          final criticalBody =
              'These subjects are critically low — immediate action required:\n\n$criticalLines';

          // Critical fires immediately (5 min from now) — too urgent to wait
          final criticalFireTime = now.add(const Duration(minutes: 5));

          if (!prefs.isQuietHour(criticalFireTime)) {
            final criticalNotifId =
                stableNotificationId('daily_critical_$dateKey') + 60000;

            await _svc.scheduleOnce(
              id: criticalNotifId,
              title: criticalTitle,
              body: criticalBody,
              scheduledDate: tz.TZDateTime.from(criticalFireTime, tz.local),
              channelId: NotificationChannels.attendanceAlerts,
              channelName: 'Attendance Alerts',
              bigText: true,
            );

            // Record dedup flag before Firestore write
            await repo.recordDailyCriticalFired();

            if (notificationRepo != null && currentUserId.isNotEmpty) {
              final centerId = 'criticalAttendance_$dateKey';
              final alreadyStored =
                  await notificationRepo.notificationExists(centerId);
              if (!alreadyStored) {
                await notificationRepo.addNotification(AppNotificationModel(
                  id: centerId,
                  userId: currentUserId,
                  title: criticalTitle,
                  message: criticalBody,
                  type: AppNotificationType.criticalAttendance,
                  priority: NotificationPriority.critical,
                  createdAt: now,
                  isRead: false,
                ));
              }
            }

            // ignore: avoid_print
            print('[NotificationScheduler] Critical alert scheduled — ${criticalSubjects.length} subjects.');
          }
        }
      }
    }
  }

  // ── Type 4: Nightly Bunk Planner (device + Firestore) ────────────────────
  //
  // Generates a consolidated nightly summary of subjects that are safe to bunk
  // TOMORROW. Only subjects with safeBunks > 0 AND that have a lecture
  // scheduled tomorrow are included. Fires at prefs.plannerTime (daily repeat).

  Future<void> scheduleSafeBunkPlanner({
    required List<ClassSession> sessions,
    required List<SubjectModel> subjects,
    required double attendanceGoal,
    required NotificationPreferences prefs,
    Set<String> tomorrowSubjectIds = const {},
    String currentUserId = '',
    AppNotificationRepository? notificationRepo,
  }) async {
    if (!prefs.safeBunkPlannerEnabled) return;

    // Cancel previous planner notification
    await _svc.cancelNotification(NotificationChannels.plannerNotificationId);

    final now = DateTime.now();
    final dateKey = _dateKey(now);

    // Build the eligible safe-bunk list.
    // Subject qualifies only if BOTH:
    //   1. safeBunks > 0 (has buffer left)
    //   2. subject.id ∈ tomorrowSubjectIds (has a lecture scheduled tomorrow)
    // NOTE: if tomorrowSubjectIds is empty (no lectures tomorrow / no timetable),
    // then NO subjects qualify — which is the correct, intended behaviour.
    final eligible = <SubjectModel>[];
    for (final subject in subjects) {
      final bunks = _safeBunkCount(
        attended: subject.attendedClasses,
        total: subject.totalClasses,
        target: attendanceGoal / 100,
      );
      final hasTomorrowLecture = tomorrowSubjectIds.contains(subject.id);
      if (bunks > 0 && hasTomorrowLecture) {
        eligible.add(subject);
      }
    }

    final String title;
    final String body;

    if (eligible.isEmpty) {
      title = "Tomorrow's Classes";
      body = 'No safe bunks available tomorrow. Attend all scheduled lectures.';
    } else {
      title = "Tomorrow's Bunk Opportunities 🎉";
      final lines = eligible.map((s) => '• ${s.name}').join('\n');
      body = 'You can safely skip:\n$lines\n\nAttend all other lectures.';
    }

    // Schedule daily repeating device notification
    await _svc.scheduleDaily(
      id: NotificationChannels.plannerNotificationId,
      title: title,
      body: body,
      time: prefs.plannerTime,
      channelId: NotificationChannels.planningInsights,
      channelName: 'Planning & Insights',
      bigText: true,
    );

    // Write to Firestore notification center (persistent history)
    if (notificationRepo != null && currentUserId.isNotEmpty) {
      final centerId = 'nightlyBunkPlanner_$dateKey';
      final alreadyStored = await notificationRepo.notificationExists(centerId);
      if (!alreadyStored) {
        await notificationRepo.addNotification(AppNotificationModel(
          id: centerId,
          userId: currentUserId,
          title: title,
          message: body,
          type: AppNotificationType.nightlyBunkPlanner,
          priority: NotificationPriority.low,
          createdAt: now,
          isRead: false,
        ));
        // ignore: avoid_print
        print('[NotificationScheduler] Bunk planner stored in notification center — ${eligible.length} eligible subjects.');
      }
    }
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

  // ── Fire time helper ──────────────────────────────────────────────────────

  /// Computes the notification fire time: 2h after the last session ends.
  /// Falls back to 5 minutes from now if there are no active sessions today.
  static DateTime _computeFireTime(
      List<ClassSession> sessions, DateTime now) {
    // Filter to non-cancelled sessions first so that a day where every class
    // is cancelled doesn't accidentally fold over an empty iterable and return
    // a 0-minute baseline, which would yield an incorrect fire time.
    final activeSessions = sessions.where((s) => !s.isCancelled).toList();
    if (activeSessions.isNotEmpty) {
      final latestEndMinutes = activeSessions
          .map((s) => _parseMinutes(s.displayEndTime))
          .fold(0, (max, v) => v > max ? v : max);

      final lastSessionEnd = _todayAtMinutes(latestEndMinutes, now);
      final fireTime = lastSessionEnd.add(const Duration(hours: 2));
      if (fireTime.isBefore(now.add(const Duration(minutes: 5)))) {
        return now.add(const Duration(minutes: 5));
      }
      return fireTime;
    }
    return now.add(const Duration(minutes: 5));
  }

  // ── Safe bunk calculation ─────────────────────────────────────────────────

  /// Returns how many more classes can be missed while staying above [target].
  static int _safeBunkCount({
    required int attended,
    required int total,
    required double target, // 0..1
  }) {
    if (total == 0) return 0;
    final maxBunks = (attended / target) - total;
    return maxBunks < 0 ? 0 : maxBunks.floor();
  }

  /// Returns how many consecutive classes are needed to recover to [target].
  static int _classesNeededToRecover({
    required int attended,
    required int total,
    required double target, // 0..1
  }) {
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
