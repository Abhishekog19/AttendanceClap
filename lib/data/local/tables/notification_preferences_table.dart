import 'package:drift/drift.dart';

/// Table: notification_preferences
///
/// Singleton table — always contains exactly one row with id = 1.
/// The app always upserts id = 1 rather than inserting a new row.
/// No foreign keys. No indexes (singleton, always accessed by PK).
///
/// TimeOfDay fields are stored as paired *Hour/*Minute INTEGER columns
/// to avoid "HH:MM" parsing overhead — consistent with the existing
/// Firestore model pattern.
///
/// All BOOLEAN fields use INTEGER (0/1) — SQLite has no native BOOLEAN type.
class NotificationPreferences extends Table {
  /// Singleton PK — always 1.
  IntColumn get id => integer()();

  // ── Global toggles ────────────────────────────────────────────────────────

  IntColumn get notificationsEnabled =>
      integer().withDefault(const Constant(1))();
  IntColumn get soundEnabled => integer().withDefault(const Constant(1))();
  IntColumn get vibrationEnabled => integer().withDefault(const Constant(1))();
  IntColumn get badgeCount => integer().withDefault(const Constant(1))();

  // ── Quiet hours (NULL pair = quiet hours disabled) ────────────────────────

  IntColumn get quietHoursStartHour => integer().nullable()();
  IntColumn get quietHoursStartMinute => integer().nullable()();
  IntColumn get quietHoursEndHour => integer().nullable()();
  IntColumn get quietHoursEndMinute => integer().nullable()();

  // ── Class reminders ───────────────────────────────────────────────────────

  IntColumn get classRemindersEnabled =>
      integer().withDefault(const Constant(1))();

  /// Lead time before class: 5 / 10 / 15 / 30 minutes.
  IntColumn get reminderMinutes => integer().withDefault(const Constant(15))();

  /// If 1, only the first class of the day gets a reminder.
  IntColumn get onlyFirstClassReminder =>
      integer().withDefault(const Constant(0))();

  // ── Gap class reminders ───────────────────────────────────────────────────

  IntColumn get gapClassRemindersEnabled =>
      integer().withDefault(const Constant(1))();

  /// Minimum gap (minutes) to trigger a gap reminder: 30 / 45 / 60.
  IntColumn get gapMinutes => integer().withDefault(const Constant(30))();

  // ── Attendance marking reminders ──────────────────────────────────────────

  IntColumn get attendanceRemindersEnabled =>
      integer().withDefault(const Constant(1))();

  /// Minutes after class end to fire marking reminder: 0 / 5 / 10.
  IntColumn get attendanceDelayMinutes =>
      integer().withDefault(const Constant(5))();

  /// Show "Absent rest of day" action button.
  IntColumn get absentRestOfDayEnabled =>
      integer().withDefault(const Constant(1))();

  /// 0 = never; positive = dismiss after N minutes; -1 = end of day.
  IntColumn get autoDismissMinutes =>
      integer().withDefault(const Constant(0))();

  // ── Attendance alert notifications ────────────────────────────────────────

  /// Danger alert (attendance below attendanceGoal).
  IntColumn get lowAttendanceAlertsEnabled =>
      integer().withDefault(const Constant(1))();

  /// Include recovery suggestions in danger alert.
  IntColumn get recoverySuggestionsEnabled =>
      integer().withDefault(const Constant(1))();

  /// Separate alert for attendance below criticalThreshold.
  IntColumn get criticalAttendanceEnabled =>
      integer().withDefault(const Constant(1))();

  /// User-configurable critical threshold (0–100). Default 65.0.
  RealColumn get criticalThreshold =>
      real().withDefault(const Constant(65.0))();

  // ── Nightly safe-bunk planner ─────────────────────────────────────────────

  IntColumn get safeBunkPlannerEnabled =>
      integer().withDefault(const Constant(1))();

  /// Hour for nightly bunk planner notification (0–23).
  IntColumn get plannerTimeHour => integer().withDefault(const Constant(22))();

  /// Minute for nightly bunk planner notification (0–59).
  IntColumn get plannerTimeMinute =>
      integer().withDefault(const Constant(0))();

  /// Include safe-bunk subjects in planner notification.
  IntColumn get includeSafeBunks => integer().withDefault(const Constant(1))();

  IntColumn get plannerIncludeRecoverySuggestions =>
      integer().withDefault(const Constant(1))();

  /// Include at-risk subjects in planner.
  IntColumn get includeRiskSubjects =>
      integer().withDefault(const Constant(1))();

  // ── Daily summary ─────────────────────────────────────────────────────────

  /// Disabled by default.
  IntColumn get dailySummaryEnabled =>
      integer().withDefault(const Constant(0))();

  /// Hour for daily summary (0–23).
  IntColumn get summaryTimeHour => integer().withDefault(const Constant(21))();

  /// Minute for daily summary (0–59).
  IntColumn get summaryTimeMinute =>
      integer().withDefault(const Constant(0))();

  // Summary content toggles.
  IntColumn get includeClassesAttended =>
      integer().withDefault(const Constant(1))();
  IntColumn get includeClassesMissed =>
      integer().withDefault(const Constant(1))();
  IntColumn get includeSubjectBreakdown =>
      integer().withDefault(const Constant(1))();
  IntColumn get includeOverallAttendance =>
      integer().withDefault(const Constant(1))();

  // ── Metadata ──────────────────────────────────────────────────────────────

  /// Last-modified timestamp — Unix timestamp (ms). Client-side clock.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
