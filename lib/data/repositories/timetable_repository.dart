import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/class_session_model.dart';
import '../models/semester_model.dart';
import '../models/timetable_entry_model.dart';

part 'timetable_repository.g.dart';

@riverpod
TimetableRepository timetableRepository(Ref ref) {
  return TimetableRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
}

class TimetableRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  TimetableRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid => _auth.currentUser!.uid;

  // ── Save raw timetable entries ────────────────────────────────────────────

  Future<void> saveTimetable(List<TimetableEntry> entries) async {
    final batch = _firestore.batch();
    final col = _firestore
        .collection('users')
        .doc(_uid)
        .collection('timetable_entries');

    // Clear existing
    final existing = await col.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Write new
    for (final entry in entries) {
      final ref = col.doc(_uuid.v4());
      batch.set(ref, entry.toMap());
    }

    await batch.commit();
  }

  // ── Auto-create subjects from timetable ───────────────────────────────────

  Future<Map<String, String>> createSubjectsFromTimetable(
    List<TimetableEntry> entries,
  ) async {
    final subjectNames = entries.map((e) => e.subject).toSet();
    final subjectIdMap = <String, String>{}; // name → id

    final col = _firestore.collection('users').doc(_uid).collection('subjects');

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
          'faculty': entries.firstWhere((e) => e.subject == name).faculty,
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
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('semesters')
        .doc(semester.id)
        .set(semester.toMap());
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
    final col = _firestore
        .collection('users')
        .doc(_uid)
        .collection('class_sessions');

    for (int i = 0; i < sessions.length; i += chunkSize) {
      final chunk = sessions.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final session in chunk) {
        batch.set(col.doc(session.id), session.toMap());
      }
      await batch.commit();
      onProgress?.call((i + chunk.length) / sessions.length);
    }

    return sessions.length;
  }

  // ── Stream class sessions for today ───────────────────────────────────────

  Stream<List<ClassSession>> todaySessionsStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('class_sessions')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassSession.fromMap(d.data())).toList());
  }

  // ── Update attendance on a session ───────────────────────────────────────

  Future<void> markAttendance(
    String sessionId,
    AttendanceStatus status,
  ) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('class_sessions')
        .doc(sessionId)
        .update({'status': status.name});
  }
}
