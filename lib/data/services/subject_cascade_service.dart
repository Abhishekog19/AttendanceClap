import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SubjectCascadeService
//
// Handles subject rename propagation and delete cascade across all dependent
// Firestore collections. This is the ONLY place that should perform cross-
// collection writes when a subject changes identity.
//
// Architecture contract:
//   • subjectId  = the relationship key (never changes, even on rename)
//   • subject.name = display value (can be renamed; this service propagates it)
//
// Called by: SubjectRepository.updateSubject() + SubjectRepository.deleteSubject()
// ─────────────────────────────────────────────────────────────────────────────

class SubjectCascadeService {
  final FirebaseFirestore _db;

  SubjectCascadeService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ── Rename Propagation ────────────────────────────────────────────────────

  /// Propagates a subject name change to every dependent collection.
  /// Must be called AFTER the subjects/{subjectId} document has been updated.
  ///
  /// [oldName] is required so legacy timetable entries (created before the
  /// subjectId field was added) can be matched by their stored subject name.
  ///
  /// Collections updated:
  ///   • class_sessions    → subjectName (by subjectId)
  ///   • attendance_logs   → subjectName (by subjectId)
  ///   • timetable_entries → subject by subjectId (new entries)
  ///                       → subject by old name (legacy entries without subjectId)
  ///   • daily_overrides   → newSubjectName (collection group query)
  Future<void> propagateRename(
    String uid,
    String subjectId, {
    required String oldName,
    required String newName,
  }) async {
    final userDoc = _db.collection('users').doc(uid);

    // 1. class_sessions — update subjectName for all sessions
    await _batchSetField(
      query: userDoc
          .collection('class_sessions')
          .where('subjectId', isEqualTo: subjectId),
      field: 'subjectName',
      value: newName,
    );

    // 2. attendance_logs — update subjectName for all logs
    await _batchSetField(
      query: userDoc
          .collection('attendance_logs')
          .where('subjectId', isEqualTo: subjectId),
      field: 'subjectName',
      value: newName,
    );

    // 3a. timetable_entries — update entries WITH subjectId (new entries)
    await _batchSetField(
      query: userDoc
          .collection('timetable_entries')
          .where('subjectId', isEqualTo: subjectId),
      field: 'subject',
      value: newName,
    );

    // 3b. timetable_entries — update LEGACY entries matched by old subject name
    //     (entries created before the subjectId field was added)
    await _batchSetField(
      query: userDoc
          .collection('timetable_entries')
          .where('subject', isEqualTo: oldName),
      field: 'subject',
      value: newName,
    );

    // 4. daily_overrides — use collection group to find overrides across all date docs
    await _batchSetFieldCollectionGroup(
      collectionGroupName: 'sessions',
      uid: uid,
      subjectIdField: 'newSubjectId',
      subjectId: subjectId,
      field: 'newSubjectName',
      value: newName,
    );
  }

  // ── Delete Cascade ────────────────────────────────────────────────────────

  /// Cascades a subject deletion to all dependent collections.
  /// Must be called BEFORE the subjects/{subjectId} document is deleted.
  ///
  /// [subjectName] should be the current subject name, used to match legacy
  /// timetable entries that lack the subjectId field.
  ///
  /// Strategy:
  ///   • class_sessions    → HARD DELETE (sessions have no independent value)
  ///   • attendance_logs   → SOFT ARCHIVE (isArchived: true) — preserves history
  ///   • timetable_entries → HARD DELETE (by subjectId for new + by name for legacy)
  ///   • daily_overrides   → HARD DELETE (overrides reference deleted subject)
  ///   • notification_alert_state → HARD DELETE (per-subject doc)
  Future<void> cascadeDelete(String uid, String subjectId,
      {String? subjectName}) async {
    final userDoc = _db.collection('users').doc(uid);

    // 1. Hard delete all class_sessions for this subject
    await _batchDeleteDocs(
      query: userDoc
          .collection('class_sessions')
          .where('subjectId', isEqualTo: subjectId),
    );

    // 2. Soft-archive attendance_logs (preserves historical data)
    await _batchSetField(
      query: userDoc
          .collection('attendance_logs')
          .where('subjectId', isEqualTo: subjectId),
      field: 'isArchived',
      value: true,
    );

    // 3a. Hard delete timetable_entries WITH subjectId (new entries)
    await _batchDeleteDocs(
      query: userDoc
          .collection('timetable_entries')
          .where('subjectId', isEqualTo: subjectId),
    );

    // 3b. Hard delete LEGACY timetable_entries matched by subject name
    if (subjectName != null) {
      await _batchDeleteDocs(
        query: userDoc
            .collection('timetable_entries')
            .where('subject', isEqualTo: subjectName),
      );
    }

    // 4. Hard delete daily_overrides referencing this subject (collection group)
    await _batchDeleteCollectionGroup(
      collectionGroupName: 'sessions',
      uid: uid,
      subjectIdField: 'newSubjectId',
      subjectId: subjectId,
    );

    // 5. Delete the notification alert state document for this subject.
    //    DocumentReference.delete() silently succeeds for non-existent docs —
    //    no try-catch needed.
    await userDoc
        .collection('notification_alert_state')
        .doc(subjectId)
        .delete();
  }

  // ── Private Batch Helpers ─────────────────────────────────────────────────

  /// Fetches all documents from [query] and batch-updates a single [field].
  /// Processes in chunks of 500 to stay within Firestore batch limits.
  Future<void> _batchSetField({
    required Query<Map<String, dynamic>> query,
    required String field,
    required dynamic value,
  }) async {
    const chunkSize = 500;
    QuerySnapshot<Map<String, dynamic>> snap;

    // Paginate using startAfter to handle > 500 docs
    DocumentSnapshot? lastDoc;

    do {
      final pagedQuery = lastDoc != null
          ? query.limit(chunkSize).startAfterDocument(lastDoc)
          : query.limit(chunkSize);

      snap = await pagedQuery.get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {field: value});
      }
      await batch.commit();

      lastDoc = snap.docs.last;
    } while (snap.docs.length == chunkSize);
  }

  /// Hard-deletes all documents matching [query] in chunks of 500.
  Future<void> _batchDeleteDocs({
    required Query<Map<String, dynamic>> query,
  }) async {
    const chunkSize = 500;
    QuerySnapshot<Map<String, dynamic>> snap;

    do {
      snap = await query.limit(chunkSize).get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == chunkSize);
  }

  /// Updates a field on daily_override session docs across all date keys using
  /// a collection group query filtered by uid + subjectIdField.
  Future<void> _batchSetFieldCollectionGroup({
    required String collectionGroupName,
    required String uid,
    required String subjectIdField,
    required String subjectId,
    required String field,
    required dynamic value,
  }) async {
    const chunkSize = 500;
    try {
      final query = _db
          .collectionGroup(collectionGroupName)
          .where('uid', isEqualTo: uid)
          .where(subjectIdField, isEqualTo: subjectId);

      QuerySnapshot<Map<String, dynamic>> snap;
      DocumentSnapshot? lastDoc;

      do {
        final pagedQuery = lastDoc != null
            ? query.limit(chunkSize).startAfterDocument(lastDoc)
            : query.limit(chunkSize);

        snap = await pagedQuery.get();
        if (snap.docs.isEmpty) break;

        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {field: value});
        }
        await batch.commit();
        lastDoc = snap.docs.last;
      } while (snap.docs.length == chunkSize);
    } on FirebaseException catch (e) {
      // Only swallow missing-index errors (failed-precondition).
      // Permission errors, quota issues, and network failures are real failures
      // that must propagate so the caller knows the cascade was incomplete.
      if (e.code == 'failed-precondition') return;
      rethrow;
    }
  }

  /// Deletes daily_override session docs across all date keys using
  /// a collection group query filtered by uid + subjectIdField.
  Future<void> _batchDeleteCollectionGroup({
    required String collectionGroupName,
    required String uid,
    required String subjectIdField,
    required String subjectId,
  }) async {
    const chunkSize = 500;
    try {
      final query = _db
          .collectionGroup(collectionGroupName)
          .where('uid', isEqualTo: uid)
          .where(subjectIdField, isEqualTo: subjectId);

      QuerySnapshot<Map<String, dynamic>> snap;
      do {
        snap = await query.limit(chunkSize).get();
        if (snap.docs.isEmpty) break;

        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } while (snap.docs.length == chunkSize);
    } on FirebaseException catch (e) {
      // Only swallow missing-index errors. All other failures propagate.
      if (e.code == 'failed-precondition') return;
      rethrow;
    }
  }
}
