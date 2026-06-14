import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasources/firestore_datasource.dart';
import '../models/attendance_log_model.dart';

part 'attendance_repository.g.dart';

@riverpod
AttendanceRepository attendanceRepository(Ref ref) {
  return AttendanceRepository(
    datasource: ref.watch(firestoreDatasourceProvider),
    auth: FirebaseAuth.instance,
  );
}

/// High-level attendance log operations.
/// Wraps [FirestoreDatasource] so screens only see clean domain APIs.
class AttendanceRepository {
  final FirestoreDatasource _ds;
  final FirebaseAuth _auth;

  AttendanceRepository({
    required FirestoreDatasource datasource,
    required FirebaseAuth auth,
  })  : _ds = datasource,
        _auth = auth;

  String get _uid => _auth.currentUser!.uid;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Real-time stream of ALL logs for the current user, most-recent first.
  Stream<List<AttendanceLogModel>> watchAllLogs() =>
      _ds.watchAttendanceLogs(_uid);

  /// Real-time stream of logs for a specific subject.
  Stream<List<AttendanceLogModel>> watchLogsForSubject(String subjectId) =>
      _ds.watchLogsForSubject(_uid, subjectId);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Update a log's status and keep subject counters consistent.
  /// [oldStatus] is the status before the edit.
  Future<void> updateLog(
    AttendanceLogModel log,
    AttendanceStatus oldStatus,
  ) =>
      _ds.updateAttendanceLog(_uid, log, oldStatus);

  /// Delete a log and reverse its contribution to subject counters.
  Future<void> deleteLog(AttendanceLogModel log) =>
      _ds.deleteAttendanceLog(_uid, log);
}
