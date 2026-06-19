import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationPreferences – all user-configurable notification settings.
// Synced to Firestore at users/{uid}/notification_settings/prefs.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationPreferences {
  // ── General ──────────────────────────────────────────────────────────────────
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool badgeCount;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;

  // ── Class Reminders ───────────────────────────────────────────────────────────
  final bool classRemindersEnabled;
  final int reminderMinutes; // 5 / 10 / 15 / 30
  final bool onlyFirstClassReminder;
  final bool gapClassRemindersEnabled;
  final int gapMinutes; // 30 / 45 / 60

  // ── Attendance Actions ────────────────────────────────────────────────────────
  final bool attendanceRemindersEnabled;
  final int attendanceDelayMinutes; // 0 / 5 / 10
  final bool absentRestOfDayEnabled;
  final int autoDismissMinutes; // 0=never / 60 / -1=end of day

  // ── Attendance Alerts ─────────────────────────────────────────────────────────
  final bool lowAttendanceAlertsEnabled;
  final bool recoverySuggestionsEnabled;

  // ── Critical Attendance ───────────────────────────────────────────────────────
  final bool criticalAttendanceEnabled; // separate threshold alert
  final double criticalThreshold;       // e.g. 65.0 — configurable by user

  // ── Safe Bunk Planner ─────────────────────────────────────────────────────────
  final bool safeBunkPlannerEnabled;
  final TimeOfDay plannerTime;
  final bool includeSafeBunks;
  final bool plannerIncludeRecoverySuggestions;
  final bool includeRiskSubjects;

  // ── Daily Summary ─────────────────────────────────────────────────────────────
  final bool dailySummaryEnabled;
  final TimeOfDay summaryTime;
  final bool includeClassesAttended;
  final bool includeClassesMissed;
  final bool includeSubjectBreakdown;
  final bool includeOverallAttendance;

  const NotificationPreferences({
    // General
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.badgeCount = true,
    this.quietHoursStart,
    this.quietHoursEnd,

    // Class Reminders
    this.classRemindersEnabled = true,
    this.reminderMinutes = 15,
    this.onlyFirstClassReminder = false,
    this.gapClassRemindersEnabled = true,
    this.gapMinutes = 30,

    // Attendance Actions
    this.attendanceRemindersEnabled = true,
    this.attendanceDelayMinutes = 5,
    this.absentRestOfDayEnabled = true,
    this.autoDismissMinutes = 0,

    // Attendance Alerts
    this.lowAttendanceAlertsEnabled = true,
    this.recoverySuggestionsEnabled = true,

    // Critical Attendance
    this.criticalAttendanceEnabled = true,
    this.criticalThreshold = 65.0,

    // Safe Bunk Planner
    this.safeBunkPlannerEnabled = true,
    this.plannerTime = const TimeOfDay(hour: 22, minute: 0),
    this.includeSafeBunks = true,
    this.plannerIncludeRecoverySuggestions = true,
    this.includeRiskSubjects = true,

    // Daily Summary
    this.dailySummaryEnabled = false,
    this.summaryTime = const TimeOfDay(hour: 21, minute: 0),
    this.includeClassesAttended = true,
    this.includeClassesMissed = true,
    this.includeSubjectBreakdown = true,
    this.includeOverallAttendance = true,
  });

  // ── Defaults factory ─────────────────────────────────────────────────────────

  factory NotificationPreferences.defaults() => const NotificationPreferences();

  // ── Quiet hours check ─────────────────────────────────────────────────────────

  bool isQuietHour(DateTime now) {
    if (quietHoursStart == null || quietHoursEnd == null) return false;
    final nowMin = now.hour * 60 + now.minute;
    final startMin = quietHoursStart!.hour * 60 + quietHoursStart!.minute;
    final endMin = quietHoursEnd!.hour * 60 + quietHoursEnd!.minute;
    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin < endMin;
    } else {
      // Overnight quiet hours (e.g. 23:00 – 07:00)
      return nowMin >= startMin || nowMin < endMin;
    }
  }

  // ── Serialisation ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'notificationsEnabled': notificationsEnabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'badgeCount': badgeCount,
        'quietHoursStartHour': quietHoursStart?.hour,
        'quietHoursStartMinute': quietHoursStart?.minute,
        'quietHoursEndHour': quietHoursEnd?.hour,
        'quietHoursEndMinute': quietHoursEnd?.minute,
        'classRemindersEnabled': classRemindersEnabled,
        'reminderMinutes': reminderMinutes,
        'onlyFirstClassReminder': onlyFirstClassReminder,
        'gapClassRemindersEnabled': gapClassRemindersEnabled,
        'gapMinutes': gapMinutes,
        'attendanceRemindersEnabled': attendanceRemindersEnabled,
        'attendanceDelayMinutes': attendanceDelayMinutes,
        'absentRestOfDayEnabled': absentRestOfDayEnabled,
        'autoDismissMinutes': autoDismissMinutes,
        'lowAttendanceAlertsEnabled': lowAttendanceAlertsEnabled,
        'recoverySuggestionsEnabled': recoverySuggestionsEnabled,
        'criticalAttendanceEnabled': criticalAttendanceEnabled,
        'criticalThreshold': criticalThreshold,
        'safeBunkPlannerEnabled': safeBunkPlannerEnabled,
        'plannerTimeHour': plannerTime.hour,
        'plannerTimeMinute': plannerTime.minute,
        'includeSafeBunks': includeSafeBunks,
        'plannerIncludeRecoverySuggestions': plannerIncludeRecoverySuggestions,
        'includeRiskSubjects': includeRiskSubjects,
        'dailySummaryEnabled': dailySummaryEnabled,
        'summaryTimeHour': summaryTime.hour,
        'summaryTimeMinute': summaryTime.minute,
        'includeClassesAttended': includeClassesAttended,
        'includeClassesMissed': includeClassesMissed,
        'includeSubjectBreakdown': includeSubjectBreakdown,
        'includeOverallAttendance': includeOverallAttendance,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory NotificationPreferences.fromFirestore(Map<String, dynamic> m) {
    TimeOfDay? tod(String hKey, String mKey) {
      final h = m[hKey] as int?;
      final min = m[mKey] as int?;
      if (h == null || min == null) return null;
      return TimeOfDay(hour: h, minute: min);
    }

    int i(String k, int def) => (m[k] as num?)?.toInt() ?? def;
    bool b(String k, bool def) => m[k] as bool? ?? def;

    return NotificationPreferences(
      notificationsEnabled: b('notificationsEnabled', true),
      soundEnabled: b('soundEnabled', true),
      vibrationEnabled: b('vibrationEnabled', true),
      badgeCount: b('badgeCount', true),
      quietHoursStart: tod('quietHoursStartHour', 'quietHoursStartMinute'),
      quietHoursEnd: tod('quietHoursEndHour', 'quietHoursEndMinute'),
      classRemindersEnabled: b('classRemindersEnabled', true),
      reminderMinutes: i('reminderMinutes', 15),
      onlyFirstClassReminder: b('onlyFirstClassReminder', false),
      gapClassRemindersEnabled: b('gapClassRemindersEnabled', true),
      gapMinutes: i('gapMinutes', 30),
      attendanceRemindersEnabled: b('attendanceRemindersEnabled', true),
      attendanceDelayMinutes: i('attendanceDelayMinutes', 5),
      absentRestOfDayEnabled: b('absentRestOfDayEnabled', true),
      autoDismissMinutes: i('autoDismissMinutes', 0),
      lowAttendanceAlertsEnabled: b('lowAttendanceAlertsEnabled', true),
      recoverySuggestionsEnabled: b('recoverySuggestionsEnabled', true),
      criticalAttendanceEnabled: b('criticalAttendanceEnabled', true),
      criticalThreshold: (m['criticalThreshold'] as num?)?.toDouble() ?? 65.0,
      safeBunkPlannerEnabled: b('safeBunkPlannerEnabled', true),
      plannerTime: TimeOfDay(
        hour: i('plannerTimeHour', 22),
        minute: i('plannerTimeMinute', 0),
      ),
      includeSafeBunks: b('includeSafeBunks', true),
      plannerIncludeRecoverySuggestions:
          b('plannerIncludeRecoverySuggestions', true),
      includeRiskSubjects: b('includeRiskSubjects', true),
      dailySummaryEnabled: b('dailySummaryEnabled', false),
      summaryTime: TimeOfDay(
        hour: i('summaryTimeHour', 21),
        minute: i('summaryTimeMinute', 0),
      ),
      includeClassesAttended: b('includeClassesAttended', true),
      includeClassesMissed: b('includeClassesMissed', true),
      includeSubjectBreakdown: b('includeSubjectBreakdown', true),
      includeOverallAttendance: b('includeOverallAttendance', true),
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? badgeCount,
    Object? quietHoursStart = _sentinel,
    Object? quietHoursEnd = _sentinel,
    bool? classRemindersEnabled,
    int? reminderMinutes,
    bool? onlyFirstClassReminder,
    bool? gapClassRemindersEnabled,
    int? gapMinutes,
    bool? attendanceRemindersEnabled,
    int? attendanceDelayMinutes,
    bool? absentRestOfDayEnabled,
    int? autoDismissMinutes,
    bool? lowAttendanceAlertsEnabled,
    bool? recoverySuggestionsEnabled,
    bool? criticalAttendanceEnabled,
    double? criticalThreshold,
    bool? safeBunkPlannerEnabled,
    TimeOfDay? plannerTime,
    bool? includeSafeBunks,
    bool? plannerIncludeRecoverySuggestions,
    bool? includeRiskSubjects,
    bool? dailySummaryEnabled,
    TimeOfDay? summaryTime,
    bool? includeClassesAttended,
    bool? includeClassesMissed,
    bool? includeSubjectBreakdown,
    bool? includeOverallAttendance,
  }) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      badgeCount: badgeCount ?? this.badgeCount,
      quietHoursStart: quietHoursStart == _sentinel
          ? this.quietHoursStart
          : quietHoursStart as TimeOfDay?,
      quietHoursEnd: quietHoursEnd == _sentinel
          ? this.quietHoursEnd
          : quietHoursEnd as TimeOfDay?,
      classRemindersEnabled:
          classRemindersEnabled ?? this.classRemindersEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      onlyFirstClassReminder:
          onlyFirstClassReminder ?? this.onlyFirstClassReminder,
      gapClassRemindersEnabled:
          gapClassRemindersEnabled ?? this.gapClassRemindersEnabled,
      gapMinutes: gapMinutes ?? this.gapMinutes,
      attendanceRemindersEnabled:
          attendanceRemindersEnabled ?? this.attendanceRemindersEnabled,
      attendanceDelayMinutes:
          attendanceDelayMinutes ?? this.attendanceDelayMinutes,
      absentRestOfDayEnabled:
          absentRestOfDayEnabled ?? this.absentRestOfDayEnabled,
      autoDismissMinutes: autoDismissMinutes ?? this.autoDismissMinutes,
      lowAttendanceAlertsEnabled:
          lowAttendanceAlertsEnabled ?? this.lowAttendanceAlertsEnabled,
      recoverySuggestionsEnabled:
          recoverySuggestionsEnabled ?? this.recoverySuggestionsEnabled,
      criticalAttendanceEnabled:
          criticalAttendanceEnabled ?? this.criticalAttendanceEnabled,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      safeBunkPlannerEnabled:
          safeBunkPlannerEnabled ?? this.safeBunkPlannerEnabled,
      plannerTime: plannerTime ?? this.plannerTime,
      includeSafeBunks: includeSafeBunks ?? this.includeSafeBunks,
      plannerIncludeRecoverySuggestions: plannerIncludeRecoverySuggestions ??
          this.plannerIncludeRecoverySuggestions,
      includeRiskSubjects: includeRiskSubjects ?? this.includeRiskSubjects,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      summaryTime: summaryTime ?? this.summaryTime,
      includeClassesAttended:
          includeClassesAttended ?? this.includeClassesAttended,
      includeClassesMissed: includeClassesMissed ?? this.includeClassesMissed,
      includeSubjectBreakdown:
          includeSubjectBreakdown ?? this.includeSubjectBreakdown,
      includeOverallAttendance:
          includeOverallAttendance ?? this.includeOverallAttendance,
    );
  }
}

// Sentinel for nullable copyWith fields
const _sentinel = Object();
