import 'package:drift/drift.dart';

/// Table: subjects
///
/// Root entity — no FK dependencies. The canonical subject name lives here
/// and is joined at query time; denormalized subjectName columns in sessions
/// and logs have been removed (see LOCAL_SCHEMA_DESIGN.md § What Is NOT
/// Carried Over). attendancePercentage is computed, not stored.
@TableIndex(name: 'idx_subjects_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_subjects_name', columns: {#name})
class Subjects extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Full subject name, e.g. "Data Structures".
  TextColumn get name => text()();

  /// Running count of attended classes (present + late).
  IntColumn get attendedClasses => integer().withDefault(const Constant(0))();

  /// Running count of all classes held (excludes cancelled).
  IntColumn get totalClasses => integer().withDefault(const Constant(0))();

  /// Optional faculty/professor name.
  TextColumn get faculty => text().nullable()();

  /// Per-subject attendance target override.
  /// NULL means use AppSettings.attendance_goal.
  RealColumn get attendanceTarget => real().nullable()();

  /// Hex color string e.g. "#E57373".
  /// NULL means use auto-assigned from palette.
  TextColumn get colorHex => text().nullable()();

  /// Short display name e.g. "DS".
  /// NULL means auto-derive from name at read time.
  TextColumn get shortName => text().nullable()();

  /// Creation timestamp — Unix timestamp (ms).
  IntColumn get createdAt => integer()();

  /// Last-modified timestamp — Unix timestamp (ms).
  /// Must be updated on every write.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
