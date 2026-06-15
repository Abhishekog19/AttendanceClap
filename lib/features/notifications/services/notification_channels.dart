// ─────────────────────────────────────────────────────────────────────────────
// Notification Channel IDs and definitions.
// Each channel maps to a distinct Android notification category.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  NotificationChannels._();

  // ── Channel IDs ─────────────────────────────────────────────────────────────

  static const String classReminders = 'class_reminders';
  static const String attendanceActions = 'attendance_actions';
  static const String attendanceAlerts = 'attendance_alerts';
  static const String planningInsights = 'planning_insights';

  // ── Notification ID ranges (to avoid collisions) ────────────────────────────
  // Class reminders:      10000 + hash
  // Attendance actions:   20000 + hash
  // Attendance alerts:    30000 + hash
  // Planning (bunk):      40001 (fixed daily)
  // Daily summary:        40002 (fixed daily)

  static const int plannerNotificationId = 40001;
  static const int summaryNotificationId = 40002;

  // ── Android channel definitions ──────────────────────────────────────────────

  static List<AndroidNotificationChannel> get all => [
        AndroidNotificationChannel(
          classReminders,
          'Class Reminders',
          description: 'Reminders for your upcoming classes',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
        AndroidNotificationChannel(
          attendanceActions,
          'Attendance Actions',
          description: 'Mark your attendance without opening the app',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
        AndroidNotificationChannel(
          attendanceAlerts,
          'Attendance Alerts',
          description: 'Warnings when your attendance drops below target',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
        AndroidNotificationChannel(
          planningInsights,
          'Planning & Insights',
          description: 'Safe bunk planner and daily attendance summary',
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
        ),
      ];
}

// ── Notification action IDs ────────────────────────────────────────────────────

class NotificationActions {
  NotificationActions._();

  static const String present = 'action_present';
  static const String absent = 'action_absent';
  static const String absentRestOfDay = 'action_absent_rest_of_day';
  static const String absentToday = 'action_absent_today';
}

// ── Stable notification ID from a string seed ─────────────────────────────────

int stableNotificationId(String seed) => seed.hashCode & 0x7FFFFFFF;
