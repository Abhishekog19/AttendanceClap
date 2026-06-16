import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../datasources/firestore_datasource.dart';
import '../models/attendance_log_model.dart';
import '../models/class_session_model.dart';
import '../models/daily_schedule_override_model.dart';
import '../models/semester_model.dart';
import '../models/timetable_entry_model.dart';

part 'timetable_repository.g.dart';

@riverpod
TimetableRepository timetableRepository(Ref ref) {
  return TimetableRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    datasource: ref.watch(firestoreDatasourceProvider),
  );
}

class TimetableRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreDatasource _ds;
  final _uuid = const Uuid();

  TimetableRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirestoreDatasource datasource,
  })  : _firestore = firestore,
        _auth = auth,
        _ds = datasource;

  String get _uid => _auth.currentUser!.uid;

  // ── Helpers ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _entriesCol =>
      _firestore.collection('users').doc(_uid).collection('timetable_entries');

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('users').doc(_uid).collection('class_sessions');

  CollectionReference<Map<String, dynamic>> get _semestersCol =>
      _firestore.collection('users').doc(_uid).collection('semesters');

  // ── Active Timetable Guard ────────────────────────────────────────────────

  /// Returns true if the user already has timetable entries saved.
  Future<bool> hasActiveTimetable() => _ds.hasActiveTimetable(_uid);

  /// Deletes ALL timetable-related data for the current user.
  /// Used before uploading a replacement timetable.
  /// Clears: timetable_entries, class_sessions, subjects, attendance_logs, semesters.
  Future<void> deleteAllUserData() => _ds.deleteAllTimetableData(_uid);

  // ── Watch all saved timetable entries (real-time) ─────────────────────────

  Stream<List<TimetableEntry>> watchTimetableEntries() {
    return _entriesCol
        .orderBy('day')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TimetableEntry.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── Save raw timetable entries (bulk — used by OCR pipeline) ─────────────

  Future<void> saveTimetable(List<TimetableEntry> entries) async {
    final batch = _firestore.batch();

    // Clear existing
    final existing = await _entriesCol.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Write new
    for (final entry in entries) {
      final ref = _entriesCol.doc(_uuid.v4());
      batch.set(ref, entry.toMap());
    }

    await batch.commit();
  }

  // ── Single entry CRUD (manual timetable management) ───────────────────────

  /// Adds a single entry. Returns the new Firestore document ID.
  Future<String> addTimetableEntry(TimetableEntry entry) async {
    final ref = _entriesCol.doc(_uuid.v4());
    await ref.set(entry.toMap());
    return ref.id;
  }

  /// Replaces an existing entry in-place.
  Future<void> updateTimetableEntry(String id, TimetableEntry entry) async {
    await _entriesCol.doc(id).set(entry.toMap());
  }

  /// Deletes a single entry and optionally cascades to future sessions.
  Future<void> deleteTimetableEntry(
    String id, {
    String? subjectName,
    String? day,
    String? startTime,
    bool deleteFutureSessions = false,
  }) async {
    // Delete the entry doc
    await _entriesCol.doc(id).delete();

    // Cascade to future notMarked sessions
    if (deleteFutureSessions &&
        subjectName != null &&
        day != null &&
        startTime != null) {
      await _deleteFutureSessionsForEntry(
          subjectName: subjectName, day: day, startTime: startTime);
    }
  }

  /// Returns the count of upcoming notMarked sessions that match an entry,
  /// so the UI can warn the user before deletion.
  Future<int> countFutureSessionsForEntry({
    required String subjectName,
    required String day,
    required String startTime,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final weekday = _weekdayNumber(day);

    final snap = await _sessionsCol
        .where('subjectName', isEqualTo: subjectName)
        .where('startTime', isEqualTo: startTime)
        .where('status', isEqualTo: 'notMarked')
        .where('date', isGreaterThanOrEqualTo: now)
        .get();

    return snap.docs.where((d) {
      final date = (d.data()['date'] as Timestamp).toDate();
      return date.weekday == weekday;
    }).length;
  }

  // ── Active Semester ───────────────────────────────────────────────────────

  /// Fetches the most recently created semester, or null if none exists.
  Future<Semester?> getActiveSemester() async {
    final snap = await _semestersCol
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    try {
      return Semester.fromMap(snap.docs.first.data());
    } catch (_) {
      return null;
    }
  }

  // ── Auto-create subjects from timetable ───────────────────────────────────

  Future<Map<String, String>> createSubjectsFromTimetable(
    List<TimetableEntry> entries,
  ) async {
    final subjectNames = entries.map((e) => e.subject).toSet();
    final subjectIdMap = <String, String>{}; // name → id

    final col =
        _firestore.collection('users').doc(_uid).collection('subjects');

    // Fetch existing subjects to avoid duplication
    final existing = await col.get();
    final existingNames = <String, String>{};
    for (final doc in existing.docs) {
      final name = doc.data()['name'] as String?;
      if (name != null) existingNames[name.toLowerCase()] = doc.id;
    }

    final batch = _firestore.batch();

    for (final name in subjectNames) {
      final key = name.toLowerCase();
      if (existingNames.containsKey(key)) {
        subjectIdMap[name] = existingNames[key]!;
      } else {
        final id = _uuid.v4();
        subjectIdMap[name] = id;
        batch.set(col.doc(id), {
          'id': id,
          'uid': _uid,
          'name': name,
          'faculty':
              entries.firstWhere((e) => e.subject == name).faculty,
          'targetAttendance': 75.0,
          'attendedClasses': 0,
          'totalClasses': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    return subjectIdMap;
  }

  // ── Save semester ─────────────────────────────────────────────────────────

  Future<void> saveSemester(Semester semester) async {
    await _semestersCol.doc(semester.id).set(semester.toMap());
  }

  // ── Generate & save class sessions ───────────────────────────────────────

  Future<int> saveClassSessions({
    required List<TimetableEntry> entries,
    required Semester semester,
    required Map<String, String> subjectIdMap,
    void Function(double progress)? onProgress,
  }) async {
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];

    final sessions = <ClassSession>[];

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final weekday = i + 1; // DateTime.monday = 1
      final dayEntries = entries.where((e) => e.day == day).toList();

      if (dayEntries.isEmpty) continue;

      final dates = semester.getDatesForWeekday(weekday);

      for (final date in dates) {
        for (final entry in dayEntries) {
          sessions.add(ClassSession(
            id: _uuid.v4(),
            subjectId: subjectIdMap[entry.subject] ?? '',
            subjectName: entry.subject,
            date: date,
            startTime: entry.startTime,
            endTime: entry.endTime,
            faculty: entry.faculty,
            room: entry.room,
            status: AttendanceStatus.notMarked,
            uid: _uid,
          ));
        }
      }
    }

    // Batch-write in chunks of 500 (Firestore limit)
    const chunkSize = 500;

    for (int i = 0; i < sessions.length; i += chunkSize) {
      final chunk = sessions.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final session in chunk) {
        batch.set(_sessionsCol.doc(session.id), session.toMap());
      }
      await batch.commit();
      onProgress?.call((i + chunk.length) / sessions.length);
    }

    return sessions.length;
  }

  // ── Delete all class sessions (used before re-generating) ────────────────

  /// Wipes the entire class_sessions collection for this user.
  /// Call this before calling [saveClassSessions] on a re-generate to
  /// prevent duplicate sessions.
  Future<void> deleteAllSessions() async {
    const batchSize = 500;
    QuerySnapshot<Map<String, dynamic>> snap;
    do {
      snap = await _sessionsCol.limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == batchSize);
  }

  /// Generates sessions for a single entry from [fromDate] to semester end.
  /// Used when manually adding a class to an active semester.
  Future<int> addSessionsForEntry({
    required TimetableEntry entry,
    required String subjectId,
    required Semester semester,
    DateTime? fromDate,
  }) async {
    final start = fromDate ?? semester.startDate;
    final limitedSemester = Semester(
      id: semester.id,
      uid: semester.uid,
      startDate: start.isAfter(semester.startDate) ? start : semester.startDate,
      endDate: semester.endDate,
      holidays: semester.holidays,
      createdAt: semester.createdAt,
    );

    final weekday = _weekdayNumber(entry.day);
    final dates = limitedSemester.getDatesForWeekday(weekday);

    if (dates.isEmpty) return 0;

    final sessions = dates
        .map((date) => ClassSession(
              id: _uuid.v4(),
              subjectId: subjectId,
              subjectName: entry.subject,
              date: date,
              startTime: entry.startTime,
              endTime: entry.endTime,
              faculty: entry.faculty,
              room: entry.room,
              status: AttendanceStatus.notMarked,
              uid: _uid,
            ))
        .toList();

    const chunkSize = 500;
    for (int i = 0; i < sessions.length; i += chunkSize) {
      final chunk = sessions.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final session in chunk) {
        batch.set(_sessionsCol.doc(session.id), session.toMap());
      }
      await batch.commit();
    }

    return sessions.length;
  }

  // ── Stream class sessions for today ───────────────────────────────────────

  Stream<List<ClassSession>> todaySessionsStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _sessionsCol
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassSession.fromMap(d.data())).toList());
  }

  /// Upcoming sessions for a specific subject (from today onwards), max 10.
  /// Filters and sorts client-side to avoid requiring a composite Firestore index.
  Stream<List<ClassSession>> upcomingSessionsForSubject(String subjectId) {
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return _sessionsCol
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) {
      final all = snap.docs
          .map((d) => ClassSession.fromMap(d.data()))
          .toList();
      final upcoming = all
          .where((s) => !s.date.isBefore(startOfToday))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return upcoming.take(10).toList();
    });
  }

  // ── Mark attendance on a session (CORRECT VERSION) ────────────────────────

  /// Marks attendance for a session. Handles:
  /// 1. Creating a new log + updating subject counters (first mark)
  /// 2. Updating existing log + applying counter delta (re-mark)
  /// 3. Duplicate prevention (only one log per session)
  ///
  /// [session] must have the correct display subject (override-aware).
  Future<void> markSessionAttendance({
    required ClassSession session,
    required AttendanceStatus status,
  }) async {
    // Step 1: Check for existing log for this session
    final existingLog = await _ds.getLogForSession(_uid, session.id);

    if (existingLog == null) {
      // First time marking this session → create new log + bump counters
      final newLog = AttendanceLogModel(
        id: _uuid.v4(),
        subjectId: session.displaySubjectId,
        subjectName: session.displaySubjectName,
        status: status,
        date: session.date,
        startTime: session.displayStartTime,
        endTime: session.displayEndTime,
        sessionId: session.id,
      );
      await _ds.logAttendance(_uid, newLog);
    } else {
      // Already marked → update with delta correction
      final oldStatus = existingLog.status;
      final updatedLog = existingLog.copyWith(
        status: status,
        // Update subject if overridden
        subjectId: session.displaySubjectId,
        subjectName: session.displaySubjectName,
      );
      await _ds.updateAttendanceLog(_uid, updatedLog, oldStatus);
    }

    // Step 2: Update the session document's status field
    await _sessionsCol.doc(session.id).update({'status': status.name});
  }

  /// Marks multiple sessions absent in batch. Used by "Mark Remaining Absent"
  /// and "Mark Full Day Absent" features.
  Future<void> markMultipleSessionsAbsent(List<ClassSession> sessions) async {
    for (final session in sessions) {
      // Skip already-marked and cancelled sessions
      if (session.status != AttendanceStatus.notMarked) continue;
      if (session.isCancelled) continue;
      await markSessionAttendance(
        session: session,
        status: AttendanceStatus.absent,
      );
    }
  }

  // ── Legacy: Update session status only (for backward compat) ─────────────

  Future<void> markAttendance(
    String sessionId,
    AttendanceStatus status,
  ) async {
    await _sessionsCol
        .doc(sessionId)
        .update({'status': status.name});
  }

  // ── Daily Overrides ───────────────────────────────────────────────────────

  Future<void> saveDailyOverride(DailyScheduleOverride override) =>
      _ds.saveDailyOverride(_uid, override);

  Future<List<DailyScheduleOverride>> getDailyOverridesForDate(
          DateTime date) =>
      _ds.getDailyOverridesForDate(_uid, date);

  Stream<List<DailyScheduleOverride>> watchDailyOverridesForDate(
          DateTime date) =>
      _ds.watchDailyOverridesForDate(_uid, date);

  Future<void> deleteDailyOverride(
          String overrideId, DateTime date) =>
      _ds.deleteDailyOverride(_uid, overrideId, date);

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _deleteFutureSessionsForEntry({
    required String subjectName,
    required String day,
    required String startTime,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final weekday = _weekdayNumber(day);

    final snap = await _sessionsCol
        .where('subjectName', isEqualTo: subjectName)
        .where('startTime', isEqualTo: startTime)
        .where('status', isEqualTo: 'notMarked')
        .where('date', isGreaterThanOrEqualTo: now)
        .get();

    final toDelete = snap.docs.where((d) {
      final date = (d.data()['date'] as Timestamp).toDate();
      return date.weekday == weekday;
    }).toList();

    if (toDelete.isEmpty) return;

    const chunkSize = 500;
    for (int i = 0; i < toDelete.length; i += chunkSize) {
      final chunk = toDelete.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final d in chunk) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  static int _weekdayNumber(String day) {
    const map = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return map[day] ?? 1;
  }
}
