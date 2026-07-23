/// All attendance mutations MUST go through this repository.
/// Do not call AttendanceDao directly from providers or UI.
///
/// This file is the SINGLE place that owns attendance business logic:
///   - Counter deltas (which statuses count toward attended / total)
///   - Transaction boundaries for multi-table atomicity
///   - Hard-delete vs soft-archive decision for logs
///   - Joining class_sessions + subjects + attendance_logs for UI streams
///
/// Counting rule (verified from firestore_datasource.dart):
///   present / late → attended +1, total +1
///   absent         → total +1 only (attended unchanged)
///   cancelled      → no counter change (neither attended nor total)
///
/// is_archived decision:
///   Hard-delete + counter reversal is used for ordinary user-facing log
///   deletion (matches Firestore's deleteAttendanceLog behaviour).
///   Soft-archive (is_archived = 1) is ONLY used when a parent SUBJECT is
///   deleted, to preserve historical logs without violating the RESTRICT FK.
///   See AttendanceDao.archiveLogsForSubject().

library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/daos/attendance_dao.dart';
import '../local/daos/subjects_dao.dart';
import '../local/session_generator.dart';

// ── SubjectStats ──────────────────────────────────────────────────────────────

/// Snapshot of a subject's attendance counts — the shape consumed by
/// [LocalPredictorAdapter] and the dashboard.
class SubjectStats {
  final String subjectId;
  final String name;
  final int attendedClasses;
  final int totalClasses;

  /// Per-subject target; null means use the global goal.
  final double? attendanceTarget;
  final String? colorHex;
  final String? shortName;

  const SubjectStats({
    required this.subjectId,
    required this.name,
    required this.attendedClasses,
    required this.totalClasses,
    this.attendanceTarget,
    this.colorHex,
    this.shortName,
  });

  double get percentage =>
      totalClasses == 0 ? 0.0 : (attendedClasses / totalClasses) * 100;
}

// ── TodaySessionRow ───────────────────────────────────────────────────────────

/// A single row from the today-sessions stream, joining class_sessions,
/// subjects, and attendance_logs (if marked).
class TodaySessionRow {
  final ClassSession session;
  final Subject subject;

  /// Null when the session has not yet been marked.
  final AttendanceLog? log;

  const TodaySessionRow({
    required this.session,
    required this.subject,
    this.log,
  });
}

// ── LocalAttendanceRepository ─────────────────────────────────────────────────

class LocalAttendanceRepository {
  final AppDatabase _db;
  late final AttendanceDao _attendanceDao;
  late final SubjectsDao _subjectsDao;
  late final SessionGenerator _generator;
  static const _uuid = Uuid();

  LocalAttendanceRepository(this._db) {
    _attendanceDao = AttendanceDao(_db);
    _subjectsDao = SubjectsDao(_db);
    _generator = SessionGenerator(_db);
  }

  // ── Session generation ────────────────────────────────────────────────────

  /// Generates class_sessions for [semesterId]. Idempotent.
  Future<int> generateSessionsForSemester(String semesterId) =>
      _generator.generateSessionsForSemester(semesterId);

  // ── Counter delta helper ──────────────────────────────────────────────────

  /// Signed counter delta for a status transition.
  ///
  /// Counting rule (from firestore_datasource.dart::_counterDelta):
  ///   present / late  → attended ±1, total ±1
  ///   absent          → total ±1 only
  ///   cancelled       → no effect
  static ({int attended, int total}) _delta({
    required String oldStatus,
    required String newStatus,
  }) {
    int attended = 0;
    int total = 0;

    // Remove old status effect.
    switch (oldStatus) {
      case 'present':
      case 'late':
        attended -= 1;
        total -= 1;
      case 'absent':
        total -= 1;
      // 'cancelled' / 'notMarked': no effect on counters.
    }

    // Apply new status effect.
    switch (newStatus) {
      case 'present':
      case 'late':
        attended += 1;
        total += 1;
      case 'absent':
        total += 1;
      // 'cancelled' / 'notMarked': no effect.
    }

    return (attended: attended, total: total);
  }

  // ── markAttendance ────────────────────────────────────────────────────────

  /// Marks [sessionId] with [status] (present / absent / late / cancelled).
  ///
  /// - If no log exists → inserts log + bumps counters (atomic transaction).
  /// - If log already exists → delegates to [editAttendance] for delta
  ///   correction (avoids double-counting).
  Future<void> markAttendance({
    required String sessionId,
    required String status,
    required String semesterId,
  }) async {
    final session = await (_db.select(_db.classSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();
    if (session == null) return;

    final existing = await _attendanceDao.getLogForSession(sessionId);
    if (existing != null) {
      await editAttendance(logId: existing.id, newStatus: status);
      return;
    }

    await _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final logId = _uuid.v4();

      await _attendanceDao.insertLog(AttendanceLogsCompanion.insert(
        id: logId,
        subjectId: session.subjectId,
        semesterId: semesterId,
        sessionId: Value(sessionId),
        status: status,
        date: session.date,
        startTime: Value(session.startTime),
        endTime: Value(session.endTime),
        createdAt: now,
      ));

      await _attendanceDao.updateSessionStatus(sessionId, status);

      final d = _delta(oldStatus: 'notMarked', newStatus: status);
      await _subjectsDao.applyCounterDelta(
        subjectId: session.subjectId,
        attendedDelta: d.attended,
        totalDelta: d.total,
      );
    });
  }

  // ── editAttendance ────────────────────────────────────────────────────────

  /// Changes [logId]'s status to [newStatus] using a signed delta.
  /// Does NOT add on top of existing count — reverses old effect, applies new.
  ///
  /// Transaction: log update + session update + counter correction.
  Future<void> editAttendance({
    required String logId,
    required String newStatus,
  }) async {
    final log = await _attendanceDao.getLogById(logId);
    if (log == null) return;
    if (log.status == newStatus) return; // no-op

    await _db.transaction(() async {
      final oldStatus = log.status;

      await _attendanceDao.updateLogStatus(logId, newStatus);

      if (log.sessionId != null) {
        await _attendanceDao.updateSessionStatus(log.sessionId!, newStatus);
      }

      final d = _delta(oldStatus: oldStatus, newStatus: newStatus);
      await _subjectsDao.applyCounterDelta(
        subjectId: log.subjectId,
        attendedDelta: d.attended,
        totalDelta: d.total,
      );
    });
  }

  // ── deleteAttendance ──────────────────────────────────────────────────────

  /// Hard-deletes [logId] and reverses its counter effect.
  ///
  /// **Decision — hard-delete (not soft-archive):**
  /// Firestore's [FirestoreDatasource.deleteAttendanceLog] hard-deletes the
  /// log and resets the session to 'notMarked'. Soft-archive (is_archived=1)
  /// is reserved ONLY for subject-deletion cascades (see
  /// [AttendanceDao.archiveLogsForSubject]). This implementation matches
  /// the Firestore behaviour exactly — no ambiguity.
  ///
  /// Transaction: counter reversal + log hard-delete + session reset.
  Future<void> deleteAttendance(String logId) async {
    final log = await _attendanceDao.getLogById(logId);
    if (log == null) return;

    await _db.transaction(() async {
      // Reverse counter: treat as moving from oldStatus → cancelled.
      final d = _delta(oldStatus: log.status, newStatus: 'cancelled');
      await _subjectsDao.applyCounterDelta(
        subjectId: log.subjectId,
        attendedDelta: d.attended,
        totalDelta: d.total,
      );

      await (_db.delete(_db.attendanceLogs)
            ..where((l) => l.id.equals(logId)))
          .go();

      if (log.sessionId != null) {
        await _attendanceDao.updateSessionStatus(log.sessionId!, 'notMarked');
      }
    });
  }

  // ── watchTodaySessions ────────────────────────────────────────────────────

  /// Streams today's sessions joined with their subject and any existing log,
  /// scoped to [date] and [activeSemesterId], ordered by start_time.
  Stream<List<TodaySessionRow>> watchTodaySessions({
    required DateTime date,
    required String activeSemesterId,
  }) {
    final midnight =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch;

    final sessionsStream = _attendanceDao.watchSessionsForDate(
      dateMidnightMs: midnight,
      semesterId: activeSemesterId,
    );

    return sessionsStream.asyncMap((sessions) async {
      final rows = <TodaySessionRow>[];
      for (final session in sessions) {
        final subject = await _subjectsDao.getSubjectById(session.subjectId);
        if (subject == null) continue;
        final log = await _attendanceDao.getLogForSession(session.id);
        rows.add(TodaySessionRow(session: session, subject: subject, log: log));
      }
      return rows;
    });
  }

  // ── getSubjectStats / getAllSubjectStats ──────────────────────────────────

  /// Returns the attendance stats for a single subject.
  Future<SubjectStats?> getSubjectStats(String subjectId) async {
    final subject = await _subjectsDao.getSubjectById(subjectId);
    if (subject == null) return null;
    return _toStats(subject);
  }

  /// Returns attendance stats for ALL subjects.
  /// Called by [LocalPredictorAdapter] to build predictor input.
  Future<List<SubjectStats>> getAllSubjectStats() async {
    final subjects = await _subjectsDao.getAllSubjects();
    return subjects.map(_toStats).toList();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static SubjectStats _toStats(Subject s) => SubjectStats(
        subjectId: s.id,
        name: s.name,
        attendedClasses: s.attendedClasses,
        totalClasses: s.totalClasses,
        attendanceTarget: s.attendanceTarget,
        colorHex: s.colorHex,
        shortName: s.shortName,
      );
}
