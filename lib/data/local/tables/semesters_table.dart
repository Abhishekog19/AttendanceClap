import 'package:drift/drift.dart';

/// Table: semesters
///
/// Root entity — no FK dependencies. All past semesters are retained
/// permanently (OQ-2). Working days are derived at query time via
/// SELECT DISTINCT day_of_week FROM timetable_entries WHERE semester_id = ?
/// (OQ-4 — working_days column intentionally absent).
class Semesters extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Human-readable label e.g. "Semester 3". NULL is allowed.
  TextColumn get name => text().nullable()();

  /// Start date — Unix timestamp (ms), midnight UTC.
  IntColumn get startDate => integer()();

  /// End date — Unix timestamp (ms), midnight UTC.
  IntColumn get endDate => integer()();

  /// Creation timestamp — Unix timestamp (ms).
  IntColumn get createdAt => integer()();

  /// BOOLEAN (0/1). Only one semester should be active at a time;
  /// managed via app_settings.active_semester_id.
  IntColumn get isActive => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
