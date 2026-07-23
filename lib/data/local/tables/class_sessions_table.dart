import 'package:drift/drift.dart';
import 'semesters_table.dart';
import 'subjects_table.dart';
import 'timetable_entries_table.dart';

/// Table: class_sessions
///
/// FK behaviour (per LOCAL_SCHEMA_DESIGN.md):
///   subject_id          → subjects.id          ON DELETE CASCADE
///   semester_id         → semesters.id          ON DELETE RESTRICT  (OQ-2)
///   timetable_entry_id  → timetable_entries.id  ON DELETE SET NULL
///
/// Override fields (overrideSubjectId/Name/StartTime/EndTime) are NOT present;
/// overrides live exclusively in daily_schedule_overrides (Table 4).
@TableIndex(name: 'idx_cs_date', columns: {#date})
@TableIndex(name: 'idx_cs_semester_id', columns: {#semesterId})
@TableIndex(name: 'idx_cs_subject_date', columns: {#subjectId, #date})
@TableIndex(name: 'idx_cs_date_status', columns: {#date, #status})
@TableIndex(name: 'idx_cs_timetable_entry_id', columns: {#timetableEntryId})
class ClassSessions extends Table {
  /// UUID. May be pre-generated at session expansion time for stability.
  TextColumn get id => text()();

  /// FK → subjects.id, ON DELETE CASCADE.
  TextColumn get subjectId =>
      text().references(Subjects, #id, onDelete: KeyAction.cascade)();

  /// FK → semesters.id, ON DELETE RESTRICT (OQ-2).
  TextColumn get semesterId =>
      text().references(Semesters, #id, onDelete: KeyAction.restrict)();

  /// FK → timetable_entries.id, ON DELETE SET NULL.
  /// NULL for extra periods added outside the timetable.
  TextColumn get timetableEntryId =>
      text().nullable().references(TimetableEntries, #id,
          onDelete: KeyAction.setNull)();

  /// Date — Unix timestamp (ms), normalized to midnight UTC.
  IntColumn get date => integer()();

  /// "HH:MM" from timetable entry (base time, before any override).
  TextColumn get startTime => text()();

  /// "HH:MM" from timetable entry (base time, before any override).
  TextColumn get endTime => text()();

  /// Faculty copied from timetable entry at expansion time.
  TextColumn get faculty => text().nullable()();

  /// Room copied from timetable entry at expansion time.
  TextColumn get room => text().nullable()();

  /// Enum string: present / absent / late / cancelled / notMarked.
  TextColumn get status =>
      text().withDefault(const Constant('notMarked'))();

  /// BOOLEAN (0/1). True when this session was cancelled for the day.
  IntColumn get isCancelled => integer().withDefault(const Constant(0))();

  /// BOOLEAN (0/1). True when added outside the timetable pattern.
  IntColumn get isExtraPeriod => integer().withDefault(const Constant(0))();

  /// Creation timestamp — Unix timestamp (ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
