import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/subject_model.dart';
import '../models/timetable_model.dart';
import '../models/attendance_log_model.dart';
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

  Stream<List<AttendanceLogModel>> watchAttendanceLogs(String uid) {
    return _logsRef(uid)
        .orderBy('date', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AttendanceLogModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> logAttendance(String uid, AttendanceLogModel log) async {
    final batch = _db.batch();
    // Add log
    batch.set(_logsRef(uid).doc(log.id), log.toJson());
    // Update subject counters
    final subjectRef = _subjectsRef(uid).doc(log.subjectId);
    if (log.status == AttendanceStatus.present) {
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
    await batch.commit();
  }

  Future<List<AttendanceLogModel>> getLogsForSubject(
      String uid, String subjectId) async {
    final snap = await _logsRef(uid)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((doc) => AttendanceLogModel.fromJson(doc.data(), doc.id))
        .toList();
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
}
