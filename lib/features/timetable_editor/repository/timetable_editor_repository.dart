/// Timetable Editor Repository
///
/// Handles all Firestore CRUD for the timetable editor schema:
///   /users/{uid}/timetable/config          ← grid config (durations, visible hour range)
///   /users/{uid}/timetable/config/lectures/{id}   ← LectureBlock docs
///
/// Subjects are now read from the canonical /users/{uid}/subjects collection
/// (via subjectsStreamProvider) — no separate timetable subjects subcollection.
///
/// All write methods fire-and-forget the Firestore call (don't await in UI path).
/// The caller (TimetableEditorNotifier) updates local state first for instant UI.
library;

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

  CollectionReference<Map<String, dynamic>> get _lecturesCol => _firestore
      .collection('users')
      .doc(_uid)
      .collection('timetable')
      .doc('config')
      .collection('lectures');

  // ── Config (grid settings) ────────────────────────────────────────────────

  /// Stream of the config doc — delivers grid settings.
  Stream<Map<String, dynamic>> watchConfig() {
    return _configDoc.snapshots().map((snap) => snap.data() ?? {});
  }

  /// Saves grid configuration to the config doc.
  Future<void> saveGridConfig({
    int? defaultLectureDurationMinutes,
    int? gridStartHour,
    int? gridEndHour,
  }) {
    final data = <String, dynamic>{};
    if (defaultLectureDurationMinutes != null) {
      data['defaultLectureDurationMinutes'] = defaultLectureDurationMinutes;
    }
    if (gridStartHour != null) data['gridStartHour'] = gridStartHour;
    if (gridEndHour != null) data['gridEndHour'] = gridEndHour;
    if (data.isEmpty) return Future.value();
    return _configDoc.set(data, SetOptions(merge: true));
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

  /// Generates a fresh UUID — useful for pre-assigning IDs before writes.
  String newId() => _uuid.v4();
}
