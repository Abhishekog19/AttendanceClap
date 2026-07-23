import 'package:drift/drift.dart';
import 'class_sessions_table.dart';
import 'semesters_table.dart';
import 'subjects_table.dart';

/// Table: attendance_logs
///
/// FK behaviour (per LOCAL_SCHEMA_DESIGN.md):
///   subject_id  → subjects.id        ON DELETE RESTRICT
///     (audit data: application must soft-archive with is_archived=1 before
///      the subject can be deleted — prevents silent data loss)
///   semester_id → semesters.id        ON DELETE RESTRICT (OQ-2)
///     (semester cannot be deleted while logs exist — protects historical record)
///   session_id  → class_sessions.id   ON DELETE SET NULL
///     (log survives session deletion; session_id becomes NULL)
///
/// 'notMarked' status is NEVER stored here. Only: present/absent/late/cancelled.
/// is_archived is NOT NULL INTEGER (0/1), never nullable — eliminates the
/// nullable-bool Firestore workaround.
@TableIndex(name: 'idx_al_subject_id', columns: {#subjectId})
@TableIndex(name: 'idx_al_semester_id', columns: {#semesterId})
@TableIndex(name: 'idx_al_date', columns: {#date})
@TableIndex(name: 'idx_al_subject_date', columns: {#subjectId, #date})
@TableIndex(name: 'idx_al_session_id', columns: {#sessionId})
@TableIndex(name: 'idx_al_archived', columns: {#isArchived, #date})
class AttendanceLogs extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// FK → subjects.id, ON DELETE RESTRICT.
  TextColumn get subjectId =>
      text().references(Subjects, #id, onDelete: KeyAction.restrict)();

  /// FK → semesters.id, ON DELETE RESTRICT (OQ-2).
  TextColumn get semesterId =>
      text().references(Semesters, #id, onDelete: KeyAction.restrict)();

  /// FK → class_sessions.id, ON DELETE SET NULL.
  /// NULL for manually entered historical logs.
  TextColumn get sessionId =>
      text().nullable().references(ClassSessions, #id,
          onDelete: KeyAction.setNull)();

  /// Enum string: present / absent / late / cancelled.
  /// NOTE: 'notMarked' is NEVER stored here.
  TextColumn get status => text()();

  /// Date — Unix timestamp (ms), normalized to midnight UTC.
  IntColumn get date => integer()();

  /// "HH:MM"; copied from session at write time. NULL for manual entries.
  TextColumn get startTime => text().nullable()();

  /// "HH:MM"; copied from session at write time. NULL for manual entries.
  TextColumn get endTime => text().nullable()();

  /// BOOLEAN (0/1). 1 = soft-deleted when parent subject is deleted;
  /// log row is preserved for audit.
  IntColumn get isArchived => integer().withDefault(const Constant(0))();

  /// Creation timestamp — Unix timestamp (ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
