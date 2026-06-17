import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'historical_sync_service.g.dart';

@riverpod
HistoricalSyncService historicalSyncService(Ref ref) {
  return HistoricalSyncService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HistoricalSyncService
//
// When a user sets up a timetable mid-semester, all past sessions are already
// created in class_sessions as 'notMarked', but the subject totalClasses
// counter starts at 0 (incremented only when attendance is actively logged).
//
// This service fixes that by:
//   1. Counting all class_sessions where date < today (past sessions)
//   2. Grouping the count by subjectId
//   3. Batch-updating subjects/{id}.totalClasses for each subject
//
// Guard: The semester document is stamped with historicalSyncDone=true so
//        this only runs once per timetable setup, not on every app launch.
//
// Safety:
//   - Does NOT touch attendedClasses (no fake presences)
//   - Does NOT create attendance_logs (sessions stay as notMarked)
//   - Is idempotent if the flag is cleared and re-run
//   - Skips if semester already has historicalSyncDone=true
// ─────────────────────────────────────────────────────────────────────────────

class HistoricalSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HistoricalSyncService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ─────────────────────────────────────────────────────────────────────────

  /// Syncs historical class session counts into subject.totalClasses.
  ///
  /// [semesterId] is used to stamp the guard flag so re-generation
  /// doesn't double-count. Pass the semester.id that was just saved.
  ///
  /// Only runs if [semesterStartDate] is in the past (at least 1 day ago).
  Future<void> syncHistoricalConductedCounts({
    required String semesterId,
    required DateTime semesterStartDate,
  }) async {
    if (_uid.isEmpty) {
      _log('Skipped — no user logged in.');
      return;
    }

    // Guard: only runs for mid-semester setups where past sessions exist
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (!semesterStartDate.isBefore(startOfToday)) {
      _log('Skipped — semester starts today or in the future. No past sessions.');
      return;
    }

    // Guard: check if sync was already done for this semester
    final semesterDoc = _firestore
        .collection('users')
        .doc(_uid)
        .collection('semesters')
        .doc(semesterId);

    final semSnap = await semesterDoc.get();
    if (semSnap.data()?['historicalSyncDone'] == true) {
      _log('Skipped — already synced (historicalSyncDone=true).');
      return;
    }

    _log('Starting historical sync for semester $semesterId...');

    // Step 1: Fetch all sessions with date < today
    final sessionsCol =
        _firestore.collection('users').doc(_uid).collection('class_sessions');

    final snap = await sessionsCol
        .where('date', isLessThan: Timestamp.fromDate(startOfToday))
        .get();

    if (snap.docs.isEmpty) {
      _log('No historical sessions found. Stamping guard flag.');
      await semesterDoc.update({'historicalSyncDone': true});
      return;
    }

    // Step 2: Count sessions per subjectId
    final countBySubject = <String, int>{};
    for (final doc in snap.docs) {
      final subjectId = doc.data()['subjectId'] as String?;
      if (subjectId == null || subjectId.isEmpty) continue;
      countBySubject[subjectId] = (countBySubject[subjectId] ?? 0) + 1;
    }

    _log('Historical session counts: $countBySubject');

    if (countBySubject.isEmpty) {
      await semesterDoc.update({'historicalSyncDone': true});
      return;
    }

    // Step 3: Batch-update subject.totalClasses
    // Using WriteBatch; chunk into groups of 400 to stay under Firestore limit.
    final subjectsCol =
        _firestore.collection('users').doc(_uid).collection('subjects');

    const chunkSize = 400;
    final entries = countBySubject.entries.toList();

    for (int i = 0; i < entries.length; i += chunkSize) {
      final chunk = entries.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();

      for (final entry in chunk) {
        batch.update(subjectsCol.doc(entry.key), {
          'totalClasses': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _log('Updated ${chunk.length} subjects (chunk ${i ~/ chunkSize + 1}).');
    }

    // Step 4: Stamp guard flag on semester doc
    await semesterDoc.update({
      'historicalSyncDone': true,
      'historicalSyncAt': FieldValue.serverTimestamp(),
      'historicalSessionCount': snap.docs.length,
    });

    _log('Historical sync complete. '
        '${snap.docs.length} sessions → ${countBySubject.length} subjects updated.');
  }

  void _log(String msg) {
    // ignore: avoid_print
    print('[HistoricalSyncService] $msg');
  }
}
