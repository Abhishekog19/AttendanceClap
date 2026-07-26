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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/daos/attendance_dao.dart';
import '../local/daos/daily_overrides_dao.dart';
import '../local/daos/subjects_dao.dart';
import '../local/session_generator.dart';
import '../../core/router/app_lifecycle_state.dart' show appDatabaseProvider;
// Firestore model types — used ONLY for adapter methods that feed existing UI
// providers. Remove once screens are rewritten to Drift types.
import '../models/class_session_model.dart' as fs;
import '../models/daily_schedule_override_model.dart' as fs;
import '../models/semester_model.dart' as fs;
import '../models/timetable_entry_model.dart' as fs;
import '../models/attendance_log_model.dart' as fs;


part 'local_attendance_repository.g.dart';

// ── Riverpod provider ─────────────────────────────────────────────────────────

/// Application-scoped [LocalAttendanceRepository] instance.
///
/// [keepAlive: true] — the repository owns the DAOs and session generator;
/// disposing it would leave callers holding stale references.
@Riverpod(keepAlive: true)
LocalAttendanceRepository localAttendanceRepository(Ref ref) {
  return LocalAttendanceRepository(ref.watch(appDatabaseProvider));
}

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
  late final DailyOverridesDao _overridesDao;
  late final SessionGenerator _generator;
  static const _uuid = Uuid();

  LocalAttendanceRepository(this._db) {
    _attendanceDao = AttendanceDao(_db);
    _subjectsDao = SubjectsDao(_db);
    _overridesDao = DailyOverridesDao(_db);
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

  // ── watchAllSubjects ──────────────────────────────────────────────────────

  /// Streams all subjects (ordered by name), emitting a new list whenever any
  /// subject row changes. This is the primary live-data source for the
  /// dashboard and subjects feature screens.
  Stream<List<Subject>> watchAllSubjects() => _subjectsDao.watchAllSubjects();

  // ── watchLogsForSubject ───────────────────────────────────────────────────

  /// Streams non-archived attendance logs for [subjectId], most-recent first.
  /// Used by subject detail and analytics screens.
  Stream<List<AttendanceLog>> watchLogsForSubject(String subjectId) =>
      _attendanceDao.watchLogsForSubject(subjectId);

  // ── watchUpcomingSessionsForSubject ───────────────────────────────────────

  /// Streams class sessions for [subjectId] that are scheduled on or after
  /// today and have not yet been marked, ordered by date then start_time.
  Stream<List<ClassSession>> watchUpcomingSessionsForSubject(
      String subjectId) {
    final nowMidnight = DateTime.utc(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)
        .millisecondsSinceEpoch;
    return (_db.select(_db.classSessions)
          ..where((s) =>
              s.subjectId.equals(subjectId) &
              s.date.isBiggerOrEqualValue(nowMidnight) &
              s.status.equals('notMarked'))
          ..orderBy([
            (s) => OrderingTerm.asc(s.date),
            (s) => OrderingTerm.asc(s.startTime),
          ]))
        .watch();
  }

  // ── Subject CRUD ──────────────────────────────────────────────────────────

  /// Inserts a new subject. Assigns a color from the rotating palette and
  /// auto-generates a shortName if not supplied.
  Future<String> addSubject({
    required String name,
    int attendedClasses = 0,
    int totalClasses = 0,
    String? faculty,
    String? colorHex,
    String? shortName,
  }) async {
    final existing = await _subjectsDao.getAllSubjects();
    final usedColors =
        existing.where((s) => s.colorHex != null).map((s) => s.colorHex!).toList();

    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.subjects).insert(SubjectsCompanion.insert(
          id: id,
          name: name,
          attendedClasses: Value(attendedClasses),
          totalClasses: Value(totalClasses),
          faculty: Value(faculty),
          attendanceTarget: const Value(null),
          colorHex: Value(colorHex ?? _nextColor(usedColors)),
          shortName: Value(shortName ?? _autoShortName(name)),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  /// Updates an existing subject row. No rename propagation needed —
  /// local DB joins by subject_id, not by name.
  Future<void> updateSubject(Subject subject) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.subjects)
          ..where((s) => s.id.equals(subject.id)))
        .write(SubjectsCompanion(
          name: Value(subject.name),
          faculty: Value(subject.faculty),
          attendanceTarget: Value(subject.attendanceTarget),
          colorHex: Value(subject.colorHex),
          shortName: Value(subject.shortName),
          updatedAt: Value(now),
        ));
  }

  /// Deletes a subject. All dependent rows are removed automatically:
  ///   timetable_entries  → ON DELETE CASCADE
  ///   class_sessions     → ON DELETE CASCADE
  ///   attendance_logs    → ON DELETE CASCADE
  /// (RESTRICT FK on semester_id is on semesters, not subjects.)
  Future<void> deleteSubject(String subjectId) async {
    await (_db.delete(_db.subjects)
          ..where((s) => s.id.equals(subjectId)))
        .go();
  }

  // ── Timetable entry reads (used by predictor + timetable provider) ─────────

  /// Streams all timetable entries, ordered by day_of_week then start_time.
  Stream<List<TimetableEntry>> watchTimetableEntries() {
    return (_db.select(_db.timetableEntries)
          ..orderBy([
            (e) => OrderingTerm.asc(e.dayOfWeek),
            (e) => OrderingTerm.asc(e.startTime),
          ]))
        .watch();
  }

  // ── Semester reads (used by predictor + timetable provider) ───────────────

  /// Returns the active semester as defined by [AppSettings.activeSemesterId],
  /// or null when none is set.
  Future<Semester?> getActiveSemester() async {
    final settings = await (_db.select(_db.appSettings)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    final semId = settings?.activeSemesterId;
    if (semId == null || semId.isEmpty) return null;
    return (_db.select(_db.semesters)
          ..where((s) => s.id.equals(semId)))
        .getSingleOrNull();
  }

  // ── Active semester — Firestore model shape (for timetable + predictor) ──────

  /// Returns the active [fs.Semester] (Firestore model shape) so that
  /// existing predictor/timetable providers need no changes.
  /// Holidays are loaded from the [SemesterHolidays] join table.
  Future<fs.Semester?> getActiveSemesterModel() async {
    final drift = await getActiveSemester();
    if (drift == null) return null;
    return _driftSemesterToModel(drift);
  }

  Future<fs.Semester> _driftSemesterToModel(Semester s) async {
    final holidayRows = await (_db.select(_db.semesterHolidays)
          ..where((h) => h.semesterId.equals(s.id)))
        .get();
    final holidays = holidayRows
        .map((h) => DateTime.fromMillisecondsSinceEpoch(h.holidayDate))
        .toList();
    return fs.Semester(
      id: s.id,
      uid: '',
      startDate: DateTime.fromMillisecondsSinceEpoch(s.startDate),
      endDate: DateTime.fromMillisecondsSinceEpoch(s.endDate),
      holidays: holidays,
      createdAt: DateTime.fromMillisecondsSinceEpoch(s.createdAt),
      semesterName: s.name,
    );
  }

  // ── Timetable entries — Firestore model shape (for predictor) ──────────────

  static const _weekdayNames = [
    '', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// Streams timetable entries mapped to the Firestore [fs.TimetableEntry]
  /// model shape (dayOfWeek int → "Monday" string, subjectId→subject name
  /// resolved via subjects join).
  Stream<List<fs.TimetableEntry>> watchTimetableEntryModels() {
    return (_db.select(_db.timetableEntries)
          ..orderBy([
            (e) => OrderingTerm.asc(e.dayOfWeek),
            (e) => OrderingTerm.asc(e.startTime),
          ]))
        .watch()
        .asyncMap((entries) async {
          final result = <fs.TimetableEntry>[];
          for (final e in entries) {
            final subject = await _subjectsDao.getSubjectById(e.subjectId);
            result.add(fs.TimetableEntry(
              id: e.id,
              subjectId: e.subjectId,
              subject: subject?.name ?? '',
              day: _weekdayNames[e.dayOfWeek.clamp(1, 7)],
              startTime: e.startTime,
              endTime: e.endTime,
              faculty: e.faculty,
              room: e.room,
              confidence: e.confidence,
            ));
          }
          return result;
        });
  }

  // ── Override write path ──────────────────────────────────────────────

  /// Saves a daily schedule override and applies any counter effects.
  ///
  /// ## Cancel — counter and log policy
  ///
  /// A cancelled session must not count against attendance. Counter effects:
  ///   - Session had a log (present/late): attendedDelta=-1, totalDelta=-1
  ///   - Session had a log (absent):       totalDelta=-1
  ///   - Session not yet marked:           totalDelta=-1
  ///
  /// **The log's status is NOT modified.** The override's presence alone signals
  /// "this session is cancelled" via the override-JOIN in watchTodaySessionModels.
  /// Leaving the log untouched means the original status (present/absent) is
  /// recoverable exactly on uncancel — no data loss.
  ///
  /// class_sessions.status is also NOT changed; the override drives isCancelled
  /// in the read path so changing the session row is both redundant and harmful.
  ///
  /// ## reschedule / changeSubject: no counter effect.
  ///
  /// ## addExtra: not supported — Phase 5.
  ///
  /// UNIQUE(session_id) on the overrides table: a second call for the same
  /// session replaces the first (idempotent upsert).
  Future<void> saveOverride(fs.DailyScheduleOverride override) async {
    final midnight = DateTime.utc(
      override.date.year,
      override.date.month,
      override.date.day,
    ).millisecondsSinceEpoch;

    final companion = DailyScheduleOverridesCompanion(
      id: Value(override.id),
      sessionId: Value(override.sessionId),
      date: Value(midnight),
      overrideType: Value(override.type.name),
      newSubjectId: Value(override.newSubjectId),
      newStartTime: Value(override.newStartTime),
      newEndTime: Value(override.newEndTime),
      isCancelled: Value(override.isCancelled ? 1 : 0),
      isExtraPeriod: Value(override.isExtraPeriod ? 1 : 0),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    if (override.type == fs.OverrideType.cancel) {
      await _db.transaction(() async {
        final existingLog =
            await _attendanceDao.getLogForSession(override.sessionId);

        if (existingLog != null) {
          // Reverse the log's counter contribution. Log status is LEFT INTACT.
          final d =
              _delta(oldStatus: existingLog.status, newStatus: 'cancelled');
          if (d.attended != 0 || d.total != 0) {
            await _subjectsDao.applyCounterDelta(
              subjectId: existingLog.subjectId,
              attendedDelta: d.attended,
              totalDelta: d.total,
            );
          }
        } else {
          // Session not yet marked — remove it from the total.
          final session = await (_db.select(_db.classSessions)
                ..where((s) => s.id.equals(override.sessionId))
                ..limit(1))
              .getSingleOrNull();
          if (session != null && session.status == 'notMarked') {
            await _subjectsDao.applyCounterDelta(
              subjectId: session.subjectId,
              attendedDelta: 0,
              totalDelta: -1,
            );
          }
        }

        // Do NOT call updateSessionStatus or updateLogStatus.
        // The override row's presence drives isCancelled in the read path.
        await _overridesDao.insertOrReplace(companion);
      });
    } else {
      // reschedule / changeSubject: write override row only, no counter effect.
      await _overridesDao.insertOrReplace(companion);
    }
  }

  /// Deletes a daily schedule override and reverses its counter effects.
  ///
  /// ## Cancel uncancel — symmetric counter restore
  ///
  /// Because saveOverride(cancel) does NOT modify the log's status, the log
  /// still holds the user's original marking (present / absent / none).
  /// deleteOverride reads that original status and applies the exact inverse
  /// delta, restoring counters to where they were before the cancel.
  ///
  ///   Log has 'present'/'late' : attendedDelta=+1, totalDelta=+1
  ///   Log has 'absent'         : totalDelta=+1
  ///   No log (was notMarked)   : totalDelta=+1
  ///
  /// class_sessions.status is also NOT changed; removing the override row
  /// makes isCancelled = false in the read path automatically.
  ///
  /// reschedule / changeSubject: no counter changes.
  Future<void> deleteOverride(String overrideId, DateTime date) async {
    final ov = await (_db.select(_db.dailyScheduleOverrides)
          ..where((o) => o.id.equals(overrideId))
          ..limit(1))
        .getSingleOrNull();
    if (ov == null) return;

    if (ov.overrideType == 'cancel') {
      await _db.transaction(() async {
        final existingLog = await _attendanceDao.getLogForSession(ov.sessionId);

        if (existingLog != null) {
          // Log's status is intact (saveOverride never changed it).
          // Restore its counter contribution: cancelled → original status.
          final d =
              _delta(oldStatus: 'cancelled', newStatus: existingLog.status);
          if (d.attended != 0 || d.total != 0) {
            await _subjectsDao.applyCounterDelta(
              subjectId: existingLog.subjectId,
              attendedDelta: d.attended,
              totalDelta: d.total,
            );
          }
        } else {
          // Session had no log when cancelled (totalDelta was -1 at cancel time).
          // Restore the total by looking up the session's subjectId.
          final session = await (_db.select(_db.classSessions)
                ..where((s) => s.id.equals(ov.sessionId))
                ..limit(1))
              .getSingleOrNull();
          if (session != null) {
            await _subjectsDao.applyCounterDelta(
              subjectId: session.subjectId,
              attendedDelta: 0,
              totalDelta: 1,
            );
          }
        }

        // Do NOT call updateSessionStatus or updateLogStatus.
        // Deleting the override row makes isCancelled = false in the read path.
        await _overridesDao.deleteById(overrideId);
      });
    } else {
      // reschedule / changeSubject: delete override row only.
      await _overridesDao.deleteById(overrideId);
    }
  }

  /// Returns all overrides for [date] — used by [_restoreSession] in
  /// [edit_today_schedule_sheet.dart] to find the cancel override to delete.
  Future<List<fs.DailyScheduleOverride>> getDailyOverridesForDate(
      DateTime date) async {
    final midnight =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch;
    final rows = await _overridesDao.getOverridesForDate(midnight);
    return rows
        .map((o) => fs.DailyScheduleOverride(
              id: o.id,
              sessionId: o.sessionId,
              uid: '',
              date: DateTime.fromMillisecondsSinceEpoch(o.date),
              type: _parseOverrideType(o.overrideType),
              newSubjectId: o.newSubjectId,
              newStartTime: o.newStartTime,
              newEndTime: o.newEndTime,
              isCancelled: o.isCancelled == 1,
              isExtraPeriod: o.isExtraPeriod == 1,
              createdAt: DateTime.fromMillisecondsSinceEpoch(o.createdAt),
            ))
        .toList();
  }

  // ── Today sessions — Firestore model shape (for timetable provider) ────────

  /// Streams today's class sessions mapped to the Firestore [fs.ClassSession]
  /// model shape WITH daily overrides already applied.
  ///
  /// Override logic is folded into this JOIN so that [session.displayStartTime]
  /// and [session.displayEndTime] are override-aware by the time they reach
  /// the provider — no separate override stream or _applyOverrides step needed.
  ///
  /// Override types handled:
  ///   cancel        → isCancelled = true
  ///   reschedule    → overrideStartTime / overrideEndTime populated
  ///   changeSubject → overrideSubjectId / overrideSubjectName populated
  ///   addExtra      → synthetic ClassSession appended at end of list
  Stream<List<fs.ClassSession>> watchTodaySessionModels({
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
      final result = <fs.ClassSession>[];

      // Pre-fetch all overrides for today in one query.
      final allOverrides = await (_db.select(_db.dailyScheduleOverrides)
            ..where((o) => o.date.equals(midnight)))
          .get();

      final overrideBySession = <String, DailyScheduleOverride>{};
      final extraOverrides = <DailyScheduleOverride>[];
      for (final o in allOverrides) {
        if (o.overrideType == 'addExtra') {
          extraOverrides.add(o);
        } else {
          overrideBySession[o.sessionId] = o;
        }
      }

      for (final s in sessions) {
        final subject = await _subjectsDao.getSubjectById(s.subjectId);
        if (subject == null) continue;

        final ov = overrideBySession[s.id];
        String? overrideSubjectId;
        String? overrideSubjectName;
        String? overrideStartTime;
        String? overrideEndTime;
        bool isCancelled = s.isCancelled == 1;

        if (ov != null) {
          isCancelled = ov.overrideType == 'cancel';
          overrideStartTime = ov.newStartTime;
          overrideEndTime = ov.newEndTime;
          overrideSubjectId = ov.newSubjectId;
          if (overrideSubjectId != null) {
            final overrideSub =
                await _subjectsDao.getSubjectById(overrideSubjectId);
            overrideSubjectName = overrideSub?.name;
          }
        }

        result.add(fs.ClassSession(
          id: s.id,
          subjectId: s.subjectId,
          subjectName: subject.name,
          date: DateTime.fromMillisecondsSinceEpoch(s.date),
          startTime: s.startTime,
          endTime: s.endTime,
          faculty: s.faculty,
          room: s.room,
          status: _parseStatus(s.status),
          uid: '',
          isCancelled: isCancelled,
          isExtraPeriod: s.isExtraPeriod == 1,
          overrideSubjectId: overrideSubjectId,
          overrideSubjectName: overrideSubjectName,
          overrideStartTime: overrideStartTime,
          overrideEndTime: overrideEndTime,
        ));
      }

      // Synthesize extra-period sessions from addExtra overrides.
      for (final extra in extraOverrides) {
        if (extra.newSubjectId == null || extra.newStartTime == null) continue;
        final extraSub =
            await _subjectsDao.getSubjectById(extra.newSubjectId!);
        result.add(fs.ClassSession(
          id: extra.id,
          subjectId: extra.newSubjectId!,
          subjectName: extraSub?.name ?? 'Extra Period',
          date: DateTime.fromMillisecondsSinceEpoch(midnight),
          startTime: extra.newStartTime!,
          endTime: extra.newEndTime ?? extra.newStartTime!,
          status: fs.AttendanceStatus.notMarked,
          uid: '',
          isExtraPeriod: true,
        ));
      }

      return result;
    });
  }

  static fs.AttendanceStatus _parseStatus(String s) => switch (s) {
        'present' => fs.AttendanceStatus.present,
        'absent' => fs.AttendanceStatus.absent,
        'late' => fs.AttendanceStatus.late,
        'cancelled' => fs.AttendanceStatus.cancelled,
        _ => fs.AttendanceStatus.notMarked,
      };

  // ── Daily overrides — Firestore model shape (for timetable provider) ────────

  /// Streams daily schedule overrides for [date] mapped to the Firestore
  /// [fs.DailyScheduleOverride] model shape.
  Stream<List<fs.DailyScheduleOverride>> watchDailyOverrideModels(
      DateTime date) {
    final midnight =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch;
    return (_db.select(_db.dailyScheduleOverrides)
          ..where((o) => o.date.equals(midnight)))
        .watch()
        .map((rows) => rows
            .map((o) => fs.DailyScheduleOverride(
                  id: o.id,
                  sessionId: o.sessionId,
                  uid: '',
                  date: DateTime.fromMillisecondsSinceEpoch(o.date),
                  type: _parseOverrideType(o.overrideType),
                  newSubjectId: o.newSubjectId,
                  newStartTime: o.newStartTime,
                  newEndTime: o.newEndTime,
                  isCancelled: o.isCancelled == 1,
                  isExtraPeriod: o.isExtraPeriod == 1,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(o.createdAt),
                ))
            .toList());
  }

  static fs.OverrideType _parseOverrideType(String s) => switch (s) {
        'cancel' => fs.OverrideType.cancel,
        'reschedule' => fs.OverrideType.reschedule,
        'changeSubject' => fs.OverrideType.changeSubject,
        _ => fs.OverrideType.addExtra,
      };

  // ── All attendance logs — Firestore model shape (for analytics provider) ──────

  /// Streams ALL attendance logs across all subjects, mapped to the Firestore
  /// [fs.AttendanceLogModel] shape so that [analytics_provider.dart] and
  /// [attendance_history_provider.dart] can switch data sources with a
  /// single line change — no logic change needed in those providers.
  Stream<List<fs.AttendanceLogModel>> watchAllLogsAsModels() {
    return (_db.select(_db.attendanceLogs)
          ..where((l) => l.isArchived.equals(0))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .watch()
        .map((rows) => rows
            .map((l) => fs.AttendanceLogModel(
                  id: l.id,
                  subjectId: l.subjectId,
                  sessionId: l.sessionId,
                  date: DateTime.fromMillisecondsSinceEpoch(l.date),
                  status: _parseStatus(l.status),
                ))
            .toList());
  }

  // ── Log edit/delete — Firestore repo interface (for attendance_history_provider) ─

  /// Updates an existing log's status. Matches [AttendanceRepository.updateLog] API.
  /// Delegates to [editAttendance] which owns the counter delta logic.
  Future<void> updateLog(
    fs.AttendanceLogModel log,
    fs.AttendanceStatus oldStatus,
  ) =>
      editAttendance(logId: log.id, newStatus: log.status.name);

  /// Hard-deletes a log and reverses its counter. Matches [AttendanceRepository.deleteLog] API.
  /// Delegates to [deleteAttendance] which owns the counter delta logic.
  Future<void> deleteLog(fs.AttendanceLogModel log) =>
      deleteAttendance(log.id);

  // ── Mark attendance from ScheduleNotifier (Firestore model input) ───────────

  /// Marks attendance for a session identified by the Firestore
  /// [fs.ClassSession] model. Fetches the active semester id from
  /// [AppSettings] so callers don't need to thread it through.
  Future<void> markSessionAttendance({
    required fs.ClassSession session,
    required fs.AttendanceStatus status,
  }) async {
    final activeSemester = await getActiveSemester();
    if (activeSemester == null) return;
    await markAttendance(
      sessionId: session.id,
      status: status.name,
      semesterId: activeSemester.id,
    );
  }

  /// Marks a list of sessions absent. Skips already-marked and cancelled ones.
  Future<void> markMultipleSessionsAbsent(
      List<fs.ClassSession> sessions) async {
    final activeSemester = await getActiveSemester();
    if (activeSemester == null) return;
    for (final s in sessions) {
      if (s.status != fs.AttendanceStatus.notMarked || s.isCancelled) continue;
      await markAttendance(
        sessionId: s.id,
        status: 'absent',
        semesterId: activeSemester.id,
      );
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static SubjectStats _toStats(Subject s) => SubjectStats(
        subjectId: s.id,
        name: s.name,
        attendedClasses: s.attendedClasses,
        totalClasses: s.totalClasses,
        attendanceTarget: s.attendanceTarget,
        colorHex: s.colorHex,
        shortName: s.shortName,
      );

  static const _palette = [
    '#EF5350', '#EC407A', '#AB47BC', '#7E57C2', '#42A5F5',
    '#26C6DA', '#26A69A', '#66BB6A', '#D4E157', '#FFA726',
  ];

  static String _nextColor(List<String> used) {
    for (final c in _palette) {
      if (!used.contains(c)) return c;
    }
    return _palette[used.length % _palette.length];
  }

  static String _autoShortName(String name) {
    final trimmed = name.trim();
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return trimmed.substring(0, trimmed.length.clamp(0, 3)).toUpperCase();
    }
    return words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

}
