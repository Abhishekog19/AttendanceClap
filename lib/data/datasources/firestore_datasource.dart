import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/subject_model.dart';
import '../models/timetable_model.dart';
import '../models/attendance_log_model.dart';
import '../models/daily_schedule_override_model.dart';
import '../models/user_model.dart';

part 'firestore_datasource.g.dart';

@riverpod
FirestoreDatasource firestoreDatasource(Ref ref) => FirestoreDatasource();

class FirestoreDatasource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Profile ────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _usersRef() => _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersRef().doc(uid);

  Future<void> createUserProfile(UserModel user) async {
    await _userDoc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!, uid);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ─── Subjects ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _subjectsRef(String uid) =>
      _userDoc(uid).collection('subjects');

  Stream<List<SubjectModel>> watchSubjects(String uid) {
    return _subjectsRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubjectModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<List<SubjectModel>> getSubjects(String uid) async {
    final snap = await _subjectsRef(uid).orderBy('createdAt').get();
    return snap.docs
        .map((doc) => SubjectModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> addSubject(String uid, SubjectModel subject) async {
    await _subjectsRef(uid).doc(subject.id).set(subject.toJson());
  }

  Future<void> updateSubject(String uid, SubjectModel subject) async {
    await _subjectsRef(uid).doc(subject.id).update({
      ...subject.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubject(String uid, String subjectId) async {
    await _subjectsRef(uid).doc(subjectId).delete();
  }

  // ─── Timetable ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _timetableRef(String uid) =>
      _userDoc(uid).collection('timetable');

  Stream<List<TimetableModel>> watchTimetable(String uid) {
    return _timetableRef(uid)
        .orderBy('day')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TimetableModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addTimetableEntry(String uid, TimetableModel entry) async {
    await _timetableRef(uid).doc(entry.id).set(entry.toJson());
  }

  Future<void> updateTimetableEntry(String uid, TimetableModel entry) async {
    await _timetableRef(uid).doc(entry.id).update(entry.toJson());
  }

  Future<void> deleteTimetableEntry(String uid, String entryId) async {
    await _timetableRef(uid).doc(entryId).delete();
  }

  // ─── Attendance Logs ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _logsRef(String uid) =>
      _userDoc(uid).collection('attendance_logs');

  /// Stream of all logs, most recent first (capped at 500).
  Stream<List<AttendanceLogModel>> watchAttendanceLogs(String uid) {
    return _logsRef(uid)
        .orderBy('date', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AttendanceLogModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Stream of logs for a single subject, most recent first.
  /// Sorts client-side to avoid requiring a composite (subjectId + date) index.
  Stream<List<AttendanceLogModel>> watchLogsForSubject(
      String uid, String subjectId) {
    return _logsRef(uid)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) {
      final logs = snap.docs
          .map((doc) => AttendanceLogModel.fromJson(doc.data(), doc.id))
          .toList();
      logs.sort((a, b) => b.date.compareTo(a.date)); // most recent first
      return logs;
    });
  }

  /// Returns the existing log for a session, or null if not yet marked.
  Future<AttendanceLogModel?> getLogForSession(
      String uid, String sessionId) async {
    final snap = await _logsRef(uid)
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return AttendanceLogModel.fromJson(doc.data(), doc.id);
  }

  /// Writes a log and atomically bumps the subject counters.
  Future<void> logAttendance(String uid, AttendanceLogModel log) async {
    final batch = _db.batch();
    batch.set(_logsRef(uid).doc(log.id), log.toJson());

    final subjectRef = _subjectsRef(uid).doc(log.subjectId);
    if (log.status == AttendanceStatus.present ||
        log.status == AttendanceStatus.late) {
      batch.update(subjectRef, {
        'attendedClasses': FieldValue.increment(1),
        'totalClasses': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else if (log.status == AttendanceStatus.absent) {
      batch.update(subjectRef, {
        'totalClasses': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    // cancelled: no counter change
    await batch.commit();
  }

  /// Updates an existing log's status, correcting subject counters by delta.
  Future<void> updateAttendanceLog(
    String uid,
    AttendanceLogModel log,
    AttendanceStatus oldStatus,
  ) async {
    final batch = _db.batch();
    batch.set(_logsRef(uid).doc(log.id), log.toJson());

    final subjectRef = _subjectsRef(uid).doc(log.subjectId);
    final delta = _counterDelta(oldStatus: oldStatus, newStatus: log.status);
    if (delta['attendedClasses'] != 0 || delta['totalClasses'] != 0) {
      final update = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (delta['attendedClasses'] != 0) {
        update['attendedClasses'] =
            FieldValue.increment(delta['attendedClasses']!);
      }
      if (delta['totalClasses'] != 0) {
        update['totalClasses'] =
            FieldValue.increment(delta['totalClasses']!);
      }
      batch.update(subjectRef, update);
    }
    await batch.commit();
  }

  /// Deletes a log and reverses the counter changes it originally applied.
  Future<void> deleteAttendanceLog(String uid, AttendanceLogModel log) async {
    final batch = _db.batch();
    batch.delete(_logsRef(uid).doc(log.id));

    final subjectRef = _subjectsRef(uid).doc(log.subjectId);
    // Reverse the effect of the original status
    final delta = _counterDelta(
        oldStatus: log.status, newStatus: AttendanceStatus.cancelled);
    if (delta['attendedClasses'] != 0 || delta['totalClasses'] != 0) {
      final update = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (delta['attendedClasses'] != 0) {
        update['attendedClasses'] =
            FieldValue.increment(delta['attendedClasses']!);
      }
      if (delta['totalClasses'] != 0) {
        update['totalClasses'] =
            FieldValue.increment(delta['totalClasses']!);
      }
      batch.update(subjectRef, update);
    }
    await batch.commit();
  }

  Future<List<AttendanceLogModel>> getLogsForSubject(
      String uid, String subjectId) async {
    final snap = await _logsRef(uid)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    final logs = snap.docs
        .map((doc) => AttendanceLogModel.fromJson(doc.data(), doc.id))
        .toList();
    logs.sort((a, b) => b.date.compareTo(a.date)); // most recent first
    return logs;
  }

  Future<List<AttendanceLogModel>> getLogsInRange(
      String uid, DateTime start, DateTime end) async {
    final snap = await _logsRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .get();
    return snap.docs
        .map((doc) => AttendanceLogModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  // ─── Daily Schedule Overrides ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _dailyOverridesRef(
          String uid, String dateKey) =>
      _userDoc(uid).collection('daily_overrides').doc(dateKey).collection('sessions');

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> saveDailyOverride(
      String uid, DailyScheduleOverride override) async {
    final dateKey = _dateKey(override.date);
    await _dailyOverridesRef(uid, dateKey)
        .doc(override.id)
        .set(override.toMap());
  }

  Future<List<DailyScheduleOverride>> getDailyOverridesForDate(
      String uid, DateTime date) async {
    final dateKey = _dateKey(date);
    final snap = await _dailyOverridesRef(uid, dateKey).get();
    return snap.docs
        .map((doc) => DailyScheduleOverride.fromMap(doc.data()))
        .toList();
  }

  Stream<List<DailyScheduleOverride>> watchDailyOverridesForDate(
      String uid, DateTime date) {
    final dateKey = _dateKey(date);
    return _dailyOverridesRef(uid, dateKey)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DailyScheduleOverride.fromMap(doc.data()))
            .toList());
  }

  Future<void> deleteDailyOverride(
      String uid, String overrideId, DateTime date) async {
    final dateKey = _dateKey(date);
    await _dailyOverridesRef(uid, dateKey).doc(overrideId).delete();
  }

  // ─── Delete All User Data (for timetable replacement) ────────────────────────

  /// Deletes all timetable-related data for a user.
  /// Used when the user wants to replace their active timetable.
  /// Collections cleared: timetable_entries, class_sessions, subjects,
  ///   attendance_logs, semesters.
  Future<void> deleteAllTimetableData(String uid) async {
    final collections = [
      _userDoc(uid).collection('timetable_entries'),
      _userDoc(uid).collection('class_sessions'),
      _userDoc(uid).collection('subjects'),
      _userDoc(uid).collection('attendance_logs'),
      _userDoc(uid).collection('semesters'),
    ];

    for (final col in collections) {
      await _deleteCollection(col);
    }
  }

  Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>> col) async {
    const batchSize = 500;
    QuerySnapshot<Map<String, dynamic>> snap;
    do {
      snap = await col.limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == batchSize);
  }

  /// Returns true if the user has any timetable entries saved.
  Future<bool> hasActiveTimetable(String uid) async {
    final snap = await _userDoc(uid)
        .collection('timetable_entries')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ─── Counter delta helper ─────────────────────────────────────────────────────

  /// Computes the signed counter delta when changing from [oldStatus] → [newStatus].
  static Map<String, int> _counterDelta({
    required AttendanceStatus oldStatus,
    required AttendanceStatus newStatus,
  }) {
    int attended = 0;
    int total = 0;

    // Remove old effect
    if (oldStatus == AttendanceStatus.present ||
        oldStatus == AttendanceStatus.late) {
      attended -= 1;
      total -= 1;
    } else if (oldStatus == AttendanceStatus.absent) {
      total -= 1;
    }

    // Apply new effect
    if (newStatus == AttendanceStatus.present ||
        newStatus == AttendanceStatus.late) {
      attended += 1;
      total += 1;
    } else if (newStatus == AttendanceStatus.absent) {
      total += 1;
    }

    return {'attendedClasses': attended, 'totalClasses': total};
  }
}
