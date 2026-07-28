import 'package:drift/drift.dart';
import 'semesters_table.dart';
import 'subjects_table.dart';

/// Table: timetable_entries
///
/// FK behaviour (per LOCAL_SCHEMA_DESIGN.md):
///   subject_id  → subjects.id    ON DELETE CASCADE   (entries deleted with subject)
///   semester_id → semesters.id   ON DELETE RESTRICT  (OQ-2: semester cannot be
///                                                      deleted while entries exist)
///
/// OQ-4 note: working_days is NOT a column on semesters. Instead, working days
/// are derived at query time:
///   SELECT DISTINCT day_of_week FROM timetable_entries WHERE semester_id = ?
/// The semester_id index supports this query efficiently.
@TableIndex(name: 'idx_te_subject_id', columns: {#subjectId})
@TableIndex(name: 'idx_te_semester_id', columns: {#semesterId})
@TableIndex(name: 'idx_te_day_of_week', columns: {#dayOfWeek})
@TableIndex(name: 'idx_te_day_start', columns: {#dayOfWeek, #startTime})
class TimetableEntries extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// FK → subjects.id, ON DELETE CASCADE.
  TextColumn get subjectId =>
      text().references(Subjects, #id, onDelete: KeyAction.cascade)();

  /// FK → semesters.id, ON DELETE RESTRICT (OQ-2/OQ-4).
  TextColumn get semesterId =>
      text().references(Semesters, #id, onDelete: KeyAction.restrict)();

  /// ISO weekday: 1=Monday … 7=Sunday. Replaces the string "Monday" field.
  IntColumn get dayOfWeek => integer()();

  /// "HH:MM" 24-hour format.
  TextColumn get startTime => text()();

  /// "HH:MM" 24-hour format.
  TextColumn get endTime => text()();

  /// Faculty name — may differ from subject-level faculty.
  TextColumn get faculty => text().nullable()();

  /// Room/location.
  TextColumn get room => text().nullable()();

  /// Entry quality hint (0.0–1.0). Defaults to 1.0 for manually-entered slots.
  RealColumn get confidence => real().withDefault(const Constant(1.0))();

  /// Creation timestamp — Unix timestamp (ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
