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
  /// Collections updated:
  ///   • class_sessions   → subjectName
  ///   • attendance_logs  → subjectName
  ///   • timetable_entries → subject (the display name field)
  ///   • daily_overrides  → newSubjectName (collection group query)
  Future<void> propagateRename(
    String uid,
    String subjectId,
    String newName,
  ) async {
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

    // 3. timetable_entries — update subject (display name) for entries with this subjectId
    await _batchSetField(
      query: userDoc
          .collection('timetable_entries')
          .where('subjectId', isEqualTo: subjectId),
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
  /// Strategy:
  ///   • class_sessions  → HARD DELETE (sessions have no independent value)
  ///   • attendance_logs → SOFT ARCHIVE (isArchived: true) — preserves history
  ///   • timetable_entries → HARD DELETE (blueprint entries for deleted subject)
  ///   • daily_overrides  → HARD DELETE (overrides reference deleted subject)
  ///   • notification_alert_state → HARD DELETE (per-subject doc)
  Future<void> cascadeDelete(String uid, String subjectId) async {
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

    // 3. Hard delete timetable_entries for this subject
    await _batchDeleteDocs(
      query: userDoc
          .collection('timetable_entries')
          .where('subjectId', isEqualTo: subjectId),
    );

    // 4. Hard delete daily_overrides referencing this subject (collection group)
    await _batchDeleteCollectionGroup(
      collectionGroupName: 'sessions',
      uid: uid,
      subjectIdField: 'newSubjectId',
      subjectId: subjectId,
    );

    // 5. Delete the notification alert state document for this subject
    try {
      await userDoc
          .collection('notification_alert_state')
          .doc(subjectId)
          .delete();
    } catch (_) {
      // Silently ignore if it doesn't exist
    }
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
    } catch (_) {
      // Collection group queries require a Firestore index.
      // If the index isn't yet created, this fails silently — the rename
      // still succeeds on the primary collections. Document the index needed:
      // Collection group: sessions | Fields: uid ASC, newSubjectId ASC
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
    } catch (_) {
      // Index not created yet — fails silently. See index note above.
    }
  }
}
