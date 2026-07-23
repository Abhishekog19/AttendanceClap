import 'package:drift/drift.dart';
import 'class_sessions_table.dart';
import 'subjects_table.dart';

/// Table: daily_schedule_overrides
///
/// FK behaviour (per LOCAL_SCHEMA_DESIGN.md):
///   session_id      → class_sessions.id  ON DELETE CASCADE
///   new_subject_id  → subjects.id         ON DELETE SET NULL
///
/// Unique constraint on session_id enforces at most one override per session.
/// The date path component from the Firestore two-level subcollection is
/// flattened into the `date` column.
@TableIndex(name: 'idx_dso_session_id', columns: {#sessionId})
@TableIndex(name: 'idx_dso_date', columns: {#date})
class DailyScheduleOverrides extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// FK → class_sessions.id, ON DELETE CASCADE.
  TextColumn get sessionId =>
      text().references(ClassSessions, #id, onDelete: KeyAction.cascade)();

  /// Date — Unix timestamp (ms), midnight UTC. Must match the session's date.
  IntColumn get date => integer()();

  /// Enum string: changeSubject / reschedule / cancel / addExtra.
  TextColumn get overrideType => text()();

  /// FK → subjects.id, ON DELETE SET NULL.
  /// Set when override_type = changeSubject.
  TextColumn get newSubjectId =>
      text().nullable().references(Subjects, #id, onDelete: KeyAction.setNull)();

  /// "HH:MM". Set when override_type = reschedule.
  TextColumn get newStartTime => text().nullable()();

  /// "HH:MM". Set when override_type = reschedule.
  TextColumn get newEndTime => text().nullable()();

  /// BOOLEAN. True when override_type = cancel.
  IntColumn get isCancelled => integer().withDefault(const Constant(0))();

  /// BOOLEAN. True when override_type = addExtra.
  IntColumn get isExtraPeriod => integer().withDefault(const Constant(0))();

  /// Creation timestamp — Unix timestamp (ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  /// Enforce at most one override per session.
  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionId},
      ];
}
