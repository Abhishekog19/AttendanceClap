import 'package:drift/drift.dart';

import '../database.dart';

/// Data-access object for [AttendanceLogs] and the [ClassSessions] status
/// field.
///
/// **PRIVATE to the local data layer** — do NOT inject this into providers
/// or UI. All attendance mutations must go through [AttendanceRepository],
/// which owns the counter logic and multi-table coordination.
///
/// This DAO contains ONLY reads and writes against the database tables.
/// No business rules, no counter adjustments, no validation belong here.
class AttendanceDao {
  final AppDatabase _db;

  const AttendanceDao(this._db);

  // ── Single log reads ───────────────────────────────────────────────────────

  /// Returns the log for [sessionId], or null if not yet marked.
  Future<AttendanceLog?> getLogForSession(String sessionId) async {
    return (_db.select(_db.attendanceLogs)
          ..where((l) => l.sessionId.equals(sessionId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Returns the log with [logId], or null if not found.
  Future<AttendanceLog?> getLogById(String logId) async {
    return (_db.select(_db.attendanceLogs)
          ..where((l) => l.id.equals(logId)))
        .getSingleOrNull();
  }

  // ── Multi-log reads ────────────────────────────────────────────────────────

  /// Streams all non-archived logs for [subjectId], most recent first.
  Stream<List<AttendanceLog>> watchLogsForSubject(String subjectId) {
    return (_db.select(_db.attendanceLogs)
          ..where(
              (l) => l.subjectId.equals(subjectId) & l.isArchived.equals(0))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .watch();
  }

  // ── Session reads (used by AttendanceRepository.watchTodaySessions) ────────

  /// Streams all [ClassSessions] for [date] (midnight UTC ms) scoped to
  /// [semesterId], ordered by start_time.
  Stream<List<ClassSession>> watchSessionsForDate({
    required int dateMidnightMs,
    required String semesterId,
  }) {
    return (_db.select(_db.classSessions)
          ..where((s) =>
              s.date.equals(dateMidnightMs) &
              s.semesterId.equals(semesterId))
          ..orderBy([(s) => OrderingTerm.asc(s.startTime)]))
        .watch();
  }

  // ── Insert ─────────────────────────────────────────────────────────────────

  /// Inserts a new attendance log row. Caller is responsible for counter
  /// updates (via [SubjectsDao]).
  Future<void> insertLog(AttendanceLogsCompanion log) async {
    await _db.into(_db.attendanceLogs).insert(log);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  /// Replaces the status field of an existing log row.
  Future<void> updateLogStatus(String logId, String newStatus) async {
    await (_db.update(_db.attendanceLogs)
          ..where((l) => l.id.equals(logId)))
        .write(AttendanceLogsCompanion(status: Value(newStatus)));
  }

  /// Updates the status column on a class_session row to stay in sync with
  /// its log. Called alongside every log write.
  Future<void> updateSessionStatus(String sessionId, String status) async {
    await (_db.update(_db.classSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(ClassSessionsCompanion(status: Value(status)));
  }

  // ── Hard delete ────────────────────────────────────────────────────────────

  /// Hard-deletes [logId] and resets the linked session status to 'notMarked'.
  /// Caller is responsible for reversing counter effects (via [SubjectsDao]).
  Future<void> deleteLog(String logId, {String? sessionId}) async {
    await _db.delete(_db.attendanceLogs)
      ..where((l) => l.id.equals(logId));
    if (sessionId != null) {
      await updateSessionStatus(sessionId, 'notMarked');
    }
  }

  // ── Soft archive (subject deletion cascade) ────────────────────────────────

  /// Soft-archives all logs for [subjectId] by setting is_archived = 1.
  /// Used ONLY when a subject is being deleted — preserves the historical
  /// record without violating the RESTRICT FK on subject_id.
  ///
  /// This is NOT used for ordinary user-facing log deletion (use [deleteLog]).
  Future<void> archiveLogsForSubject(String subjectId) async {
    await (_db.update(_db.attendanceLogs)
          ..where((l) => l.subjectId.equals(subjectId)))
        .write(const AttendanceLogsCompanion(isArchived: Value(1)));
  }
}
