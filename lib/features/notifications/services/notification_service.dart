import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../data/models/class_session_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../firebase_options.dart';
import '../handlers/attendance_notification_action_handler.dart';
import 'notification_channels.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level background callback dispatcher (must be top-level / @pragma)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void notificationActionDispatcher(NotificationResponse response) async {
  // Initialise Firebase if the isolate is fresh (terminated app scenario)
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AttendanceNotificationActionHandler.dispatch(response);
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService – singleton, initialised once in main()
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialised) return;

    // Timezone setup
    tz.initializeTimeZones();
    try {
      final locationName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    // Android init settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: notificationActionDispatcher,
      onDidReceiveBackgroundNotificationResponse: notificationActionDispatcher,
    );

    // Create all channels
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (final channel in NotificationChannels.all) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    _initialised = true;
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    // POST_NOTIFICATIONS (Android 13+)
    final notifStatus = await Permission.notification.request();
    if (!notifStatus.isGranted) return false;

    // SCHEDULE_EXACT_ALARM (Android 12+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
    return exactAlarmStatus.isGranted || exactAlarmStatus.isLimited;
  }

  // ── Class Reminder Notification ───────────────────────────────────────────

  Future<void> showClassReminder({
    required ClassSession session,
    required int minutesBefore,
    required bool isFirstClass,
    required String dateKey,
  }) async {
    final isFirst = isFirstClass;
    final title =
        isFirst ? 'First class today' : '📚 ${session.displaySubjectName}';
    final body = isFirst
        ? '${session.displaySubjectName} starts in $minutesBefore minutes.'
        : '${session.displaySubjectName} starts in $minutesBefore minutes.';

    final id = stableNotificationId(
        'reminder_${session.id}_$dateKey') + 10000;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.classReminders,
          'Class Reminders',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            const AndroidNotificationAction(
              'action_absent_today',
              '❌ Absent Today',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: '${session.id}|${session.displaySubjectId}|$dateKey',
    );
  }

  // ── Attendance Marking Notification ───────────────────────────────────────

  Future<void> showAttendanceMarking({
    required ClassSession session,
    required String dateKey,
    required bool includeAbsentRestOfDay,
  }) async {
    final id = stableNotificationId(
        'attendance_${session.id}_$dateKey') + 20000;

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
      if (includeAbsentRestOfDay)
        const AndroidNotificationAction(
          'action_absent_rest_of_day',
          '🏠 Absent Rest of Day',
          cancelNotification: true,
        ),
    ];

    await _plugin.show(
      id,
      'Mark attendance — ${session.displaySubjectName}',
      'Class ended. Did you attend?',
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.attendanceActions,
          'Attendance Actions',
          importance: Importance.high,
          priority: Priority.high,
          actions: actions,
          autoCancel: true,
        ),
      ),
      payload: '${session.id}|${session.displaySubjectId}|$dateKey',
    );
  }

  // ── Low Attendance Alert ───────────────────────────────────────────────────

  Future<void> showLowAttendanceAlert({
    required SubjectModel subject,
    required double currentPercentage,
    required double threshold,
    required int classesNeeded,
    required bool includeRecovery,
  }) async {
    final id = stableNotificationId('alert_${subject.id}') + 30000;

    final body = includeRecovery
        ? 'Attend next $classesNeeded consecutive classes to recover.'
        : 'Current: ${currentPercentage.toStringAsFixed(1)}% (Target: ${threshold.toStringAsFixed(0)}%)';

    await _plugin.show(
      id,
      '⚠️ ${subject.name} attendance low',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.attendanceAlerts,
          'Attendance Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ── Safe Bunk Planner ─────────────────────────────────────────────────────

  Future<void> showSafeBunkPlanner({
    required Map<String, int> safeBunksPerSubject, // subjectName → count
    required List<String> riskSubjects,
  }) async {
    final hasBunks =
        safeBunksPerSubject.values.any((v) => v > 0);

    String title;
    String body;

    if (!hasBunks) {
      title = '⚠️ No safe bunks available tomorrow';
      body = 'Stay on track — attend all classes tomorrow.';
    } else {
      title = '🎉 Safe Bunks Available Tomorrow';
      final lines = safeBunksPerSubject.entries.map((e) {
        if (e.value == 0) return '${e.key} → No safe bunk';
        return '${e.key} → ${e.value} safe bunk${e.value > 1 ? 's' : ''}';
      }).join('\n');
      body = lines;
    }

    await _plugin.show(
      NotificationChannels.plannerNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.planningInsights,
          'Planning & Insights',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  // ── Daily Summary ─────────────────────────────────────────────────────────

  Future<void> showDailySummary({
    required int attended,
    required int missed,
    required double overallPercentage,
  }) async {
    final body =
        '✅ Attended: $attended   ❌ Missed: $missed\nOverall: ${overallPercentage.toStringAsFixed(1)}%';

    await _plugin.show(
      NotificationChannels.summaryNotificationId,
      "Today's Attendance Summary",
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.planningInsights,
          'Planning & Insights',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  // ── Cancel helpers ────────────────────────────────────────────────────────

  Future<void> cancelNotification(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancelClassReminder(String sessionId, String dateKey) =>
      _plugin.cancel(
          stableNotificationId('reminder_${sessionId}_$dateKey') + 10000);

  Future<void> cancelAttendanceReminder(
          String sessionId, String dateKey) =>
      _plugin.cancel(
          stableNotificationId('attendance_${sessionId}_$dateKey') + 20000);

  Future<List<ActiveNotification>> getActiveNotifications() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.getActiveNotifications() ?? [];
  }

  // ── Scheduled notification helpers ────────────────────────────────────────

  /// Schedule a one-time notification at an exact [TZDateTime].
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String channelId,
    required String channelName,
    String? payload,
    List<AndroidNotificationAction> actions = const [],
    bool bigText = false,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          actions: actions,
          styleInformation:
              bigText ? BigTextStyleInformation(body) : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule a daily repeating notification.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String channelId,
    required String channelName,
    String? payload,
    bool bigText = false,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // If time already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          styleInformation:
              bigText ? BigTextStyleInformation(body) : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ── Pending notification lookup ───────────────────────────────────────────

  Future<bool> isPending(int id) async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id == id);
  }
}
