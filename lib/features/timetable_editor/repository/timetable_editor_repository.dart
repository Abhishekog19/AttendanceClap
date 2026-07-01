/// Timetable Editor Repository
///
/// Handles all Firestore CRUD for the new timetable editor schema:
///   /users/{uid}/timetable/config          ← defaultSchedule + daySchedules
///   /users/{uid}/timetable/subjects/{id}   ← TimetableSubject docs
///   /users/{uid}/timetable/lectures/{id}   ← LectureBlock docs
///
/// All write methods fire-and-forget the Firestore call (don't await in UI path).
/// The caller (TimetableEditorNotifier) updates local state first for instant UI.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/auth_repository.dart';
import '../models/timetable_editor_models.dart';

part 'timetable_editor_repository.g.dart';

@riverpod
TimetableEditorRepository timetableEditorRepository(Ref ref) {
  // Rebuild when auth user changes so stale UID is never used.
  ref.watch(currentUserProvider);
  return TimetableEditorRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
}

class TimetableEditorRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  TimetableEditorRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid => _auth.currentUser!.uid;

  // ── Collection / Document references ────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> get _configDoc => _firestore
      .collection('users')
      .doc(_uid)
      .collection('timetable')
      .doc('config');

  CollectionReference<Map<String, dynamic>> get _subjectsCol => _firestore
      .collection('users')
      .doc(_uid)
      .collection('timetable')
      .doc('config')
      .collection('subjects');

  CollectionReference<Map<String, dynamic>> get _lecturesCol => _firestore
      .collection('users')
      .doc(_uid)
      .collection('timetable')
      .doc('config')
      .collection('lectures');

  // ── Config (schedule) ────────────────────────────────────────────────────────

  /// Stream of the config doc — delivers defaultSchedule + daySchedules.
  Stream<Map<String, dynamic>> watchConfig() {
    return _configDoc.snapshots().map((snap) => snap.data() ?? {});
  }

  /// Overwrites the defaultSchedule in the config doc.
  Future<void> saveDefaultSchedule(List<PeriodSlot> slots) {
    return _configDoc.set(
      {'defaultSchedule': slots.map((s) => s.toMap()).toList()},
      SetOptions(merge: true),
    );
  }

  /// Overwrites a single day's custom schedule in the config doc.
  Future<void> saveDaySchedule(String day, DaySchedule schedule) {
    return _configDoc.set(
      {'daySchedules': {day: schedule.toMap()}},
      SetOptions(merge: true),
    );
  }

  /// Clears a day's custom schedule (reverts to global).
  Future<void> clearDaySchedule(String day) {
    return _configDoc.update({
      'daySchedules.$day': FieldValue.delete(),
    });
  }

  // ── Subjects ─────────────────────────────────────────────────────────────────

  /// Real-time stream of all timetable subjects.
  Stream<List<TimetableSubject>> watchSubjects() {
    return _subjectsCol.snapshots().map((snap) => snap.docs
        .map((d) => TimetableSubject.fromMap(d.id, d.data()))
        .toList());
  }

  /// Adds a new subject. Returns the generated doc ID.
  Future<String> addSubject(TimetableSubject subject) async {
    final id = subject.id.isEmpty ? _uuid.v4() : subject.id;
    await _subjectsCol.doc(id).set(subject.toMap());
    return id;
  }

  /// Updates an existing subject.
  Future<void> updateSubject(TimetableSubject subject) {
    return _subjectsCol.doc(subject.id).set(subject.toMap());
  }

  /// Deletes a subject by ID.
  Future<void> deleteSubject(String id) {
    return _subjectsCol.doc(id).delete();
  }

  // ── Lectures ─────────────────────────────────────────────────────────────────

  /// Real-time stream of all lectures.
  Stream<List<LectureBlock>> watchLectures() {
    return _lecturesCol.snapshots().map((snap) => snap.docs
        .map((d) => LectureBlock.fromMap(d.id, d.data()))
        .toList());
  }

  /// Adds a new lecture. Returns the generated doc ID.
  Future<String> addLecture(LectureBlock lecture) async {
    final id = lecture.id.isEmpty ? _uuid.v4() : lecture.id;
    await _lecturesCol.doc(id).set(lecture.toMap());
    return id;
  }

  /// Updates an existing lecture.
  Future<void> updateLecture(LectureBlock lecture) {
    return _lecturesCol.doc(lecture.id).set(lecture.toMap());
  }

  /// Deletes a lecture by ID.
  Future<void> deleteLecture(String id) {
    return _lecturesCol.doc(id).delete();
  }

  /// Batch-adds multiple lectures (used for day-copy operations).
  Future<void> addLectures(List<LectureBlock> lectures) async {
    if (lectures.isEmpty) return;
    const chunkSize = 500;
    for (int i = 0; i < lectures.length; i += chunkSize) {
      final chunk = lectures.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final l in chunk) {
        final id = l.id.isEmpty ? _uuid.v4() : l.id;
        batch.set(_lecturesCol.doc(id), l.toMap());
      }
      await batch.commit();
    }
  }

  /// Batch-deletes multiple lectures by ID.
  Future<void> deleteLectures(List<String> ids) async {
    if (ids.isEmpty) return;
    const chunkSize = 500;
    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final id in chunk) {
        batch.delete(_lecturesCol.doc(id));
      }
      await batch.commit();
    }
  }

  /// Generates a fresh UUID — useful for pre-assigning IDs before writes.
  String newId() => _uuid.v4();
}
