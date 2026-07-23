import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_notifications_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/attendance_logs_table.dart';
import 'tables/class_sessions_table.dart';
import 'tables/daily_schedule_overrides_table.dart';
import 'tables/notification_dedup_table.dart';
import 'tables/notification_preferences_table.dart';
import 'tables/semester_holidays_table.dart';
import 'tables/semesters_table.dart';
import 'tables/subjects_table.dart';
import 'tables/timetable_entries_table.dart';

part 'database.g.dart';

/// Opens the production SQLite database stored in the app's documents directory.
///
/// This function is used as the [QueryExecutor] provider for [AppDatabase]
/// in production. For tests, use [NativeDatabase.memory()] directly.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'attendance_ai.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// The single source-of-truth local SQLite database for AttendanceAI.
///
/// Tables are registered in FK-dependency order (dependents after dependencies):
///   semesters → semester_holidays
///   subjects
///   timetable_entries (→ subjects, semesters)
///   class_sessions (→ subjects, semesters, timetable_entries)
///   daily_schedule_overrides (→ class_sessions, subjects)
///   attendance_logs (→ subjects, semesters, class_sessions)
///   notification_preferences (no FKs)
///   notification_dedup (no FKs)
///   app_notifications (no FKs)
///   app_settings (→ semesters)
///
/// Schema version: 1 (initial release — Firestore replacement).
/// Migration strategy: onCreate only. Upgrade migrations will be added in
/// future schema versions using MigrationStrategy.onUpgrade.
@DriftDatabase(tables: [
  Semesters,
  SemesterHolidays,
  Subjects,
  TimetableEntries,
  ClassSessions,
  DailyScheduleOverrides,
  AttendanceLogs,
  NotificationPreferences,
  NotificationDedup,
  AppNotifications,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// For testing: accepts a pre-built executor (e.g. NativeDatabase.memory()).
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        /// Enable foreign key enforcement on every connection open.
        /// SQLite disables FK enforcement by default; without this pragma,
        /// CASCADE / RESTRICT / SET NULL behaviours are silently ignored.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        // onUpgrade will be implemented when schema version increments.
        // Do NOT add ad-hoc upgrade logic here without incrementing schemaVersion.
      );
}
