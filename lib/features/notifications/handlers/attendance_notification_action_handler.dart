import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../data/models/attendance_log_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AttendanceNotificationActionHandler
//
// Handles all notification action button taps (Present / Absent / Absent Rest
// of Day / Absent Today). Designed to be called from a background isolate
// (flutter_local_notifications callback dispatcher) — no Riverpod, no
// BuildContext, pure Firebase SDK calls only.
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceNotificationActionHandler {
  AttendanceNotificationActionHandler._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser?.uid ?? '';

  // ── Dispatch from notification action ID ──────────────────────────────────

  /// Called by the background notification dispatcher.
  /// [payload] format: "action|sessionId|subjectId|dateKey"
  /// where dateKey = "YYYY-MM-DD"
  static Future<void> dispatch(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload ?? '';
    final parts = payload.split('|');

    if (parts.length < 3) return;

    final sessionId = parts[0];
    final subjectId = parts[1];
    final dateKey = parts.length >= 3 ? parts[2] : '';

    switch (actionId) {
      case 'action_present':
        await handlePresent(sessionId: sessionId, subjectId: subjectId);
      case 'action_absent':
        await handleAbsent(sessionId: sessionId, subjectId: subjectId);
      case 'action_absent_rest_of_day':
        await handleAbsentRestOfDay(
            sessionId: sessionId,
            subjectId: subjectId,
            dateKey: dateKey);
      case 'action_absent_today':
        await handleAbsentToday(dateKey: dateKey);
      default:
        // Notification body tapped — no action needed beyond app open
        break;
    }
  }

  // ── Mark Present ──────────────────────────────────────────────────────────

  static Future<void> handlePresent({
    required String sessionId,
    required String subjectId,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    await _markSession(
      uid: uid,
      sessionId: sessionId,
      subjectId: subjectId,
      newStatus: AttendanceStatus.present,
    );
  }

  // ── Mark Absent ───────────────────────────────────────────────────────────

  static Future<void> handleAbsent({
    required String sessionId,
    required String subjectId,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    await _markSession(
      uid: uid,
      sessionId: sessionId,
      subjectId: subjectId,
      newStatus: AttendanceStatus.absent,
    );
  }

  // ── Mark Absent Rest of Day ───────────────────────────────────────────────

  static Future<void> handleAbsentRestOfDay({
    required String sessionId,
    required String subjectId,
    required String dateKey, // "YYYY-MM-DD"
  }) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    // 1. Mark current session absent
    await _markSession(
      uid: uid,
      sessionId: sessionId,
      subjectId: subjectId,
      newStatus: AttendanceStatus.absent,
    );

    // 2. Get current session's end time to find "remaining" sessions
    final currentSession = await _firestore
        .collection('users')
        .doc(uid)
        .collection('class_sessions')
        .doc(sessionId)
        .get();

    String? currentEndTime;
    if (currentSession.exists) {
      currentEndTime = (currentSession.data()?['overrideEndTime'] as String?) ??
          (currentSession.data()?['endTime'] as String?);
    }

    // 3. Find all unmarked sessions for today after current session
    final date = _parseDateKey(dateKey);
    if (date == null) return;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('class_sessions')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'notMarked')
        .get();

    final remaining = snap.docs.where((doc) {
      final data = doc.data();
      final id = data['id'] as String? ?? doc.id;
      if (id == sessionId) return false; // already marked
      if (currentEndTime == null) return true;
      // Only sessions starting at or after current session's end time
      final startTime =
          (data['overrideStartTime'] as String?) ??
              (data['startTime'] as String? ?? '00:00');
      return _compareTime(startTime, currentEndTime) >= 0;
    }).toList();

    for (final doc in remaining) {
      final data = doc.data();
      final sId = data['id'] as String? ?? doc.id;
      final sSubjectId = (data['overrideSubjectId'] as String?) ??
          (data['subjectId'] as String? ?? '');
      await _markSession(
        uid: uid,
        sessionId: sId,
        subjectId: sSubjectId,
        newStatus: AttendanceStatus.absent,
        sessionData: data,
      );
    }
  }

  // ── Mark Absent Today (all remaining) ────────────────────────────────────

  static Future<void> handleAbsentToday({required String dateKey}) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    final date = _parseDateKey(dateKey);
    if (date == null) return;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('class_sessions')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'notMarked')
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final sessionId = data['id'] as String? ?? doc.id;
      final subjectId = (data['overrideSubjectId'] as String?) ??
          (data['subjectId'] as String? ?? '');
      final isCancelled = data['isCancelled'] as bool? ?? false;
      if (isCancelled) continue;
      await _markSession(
        uid: uid,
        sessionId: sessionId,
        subjectId: subjectId,
        newStatus: AttendanceStatus.absent,
        sessionData: data,
      );
    }
  }

  // ── Core mark helper ──────────────────────────────────────────────────────

  static Future<void> _markSession({
    required String uid,
    required String sessionId,
    required String subjectId,
    required AttendanceStatus newStatus,
    Map<String, dynamic>? sessionData,
  }) async {
    final logsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance_logs');

    final subjectRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('subjects')
        .doc(subjectId);

    final sessionsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('class_sessions')
        .doc(sessionId);

    // Check for existing log
    final existingSnap = await logsRef
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();

    await _firestore.runTransaction((txn) async {
      // Get session doc data if not provided
      Map<String, dynamic> sData = sessionData ?? {};
      if (sData.isEmpty) {
        final sDoc = await txn.get(sessionsRef);
        sData = sDoc.data() ?? {};
      }

      final subjectName =
          (sData['overrideSubjectName'] as String?) ??
              (sData['subjectName'] as String? ?? '');
      final startTime =
          (sData['overrideStartTime'] as String?) ??
              (sData['startTime'] as String? ?? '00:00');
      final endTime =
          (sData['overrideEndTime'] as String?) ??
              (sData['endTime'] as String? ?? '00:00');
      final date = (sData['date'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (existingSnap.docs.isEmpty) {
        // First time marking → create log + bump counters
        final logId = _generateId();
        final logRef = logsRef.doc(logId);

        txn.set(logRef, {
          'id': logId,
          'subjectId': subjectId,
          'subjectName': subjectName,
          'status': newStatus.name,
          'date': Timestamp.fromDate(date),
          'startTime': startTime,
          'endTime': endTime,
          'sessionId': sessionId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Counter update
        if (newStatus == AttendanceStatus.present ||
            newStatus == AttendanceStatus.late) {
          txn.update(subjectRef, {
            'attendedClasses': FieldValue.increment(1),
            'totalClasses': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (newStatus == AttendanceStatus.absent) {
          txn.update(subjectRef, {
            'totalClasses': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Re-marking → apply delta
        final existingDoc = existingSnap.docs.first;
        final oldStatusStr = existingDoc.data()['status'] as String? ?? '';
        final oldStatus = AttendanceStatus.values.firstWhere(
          (s) => s.name == oldStatusStr,
          orElse: () => AttendanceStatus.notMarked,
        );

        if (oldStatus == newStatus) return; // no-op

        txn.update(logsRef.doc(existingDoc.id), {
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final delta = _delta(oldStatus, newStatus);
        final Map<String, dynamic> counterUpdate = {
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (delta['attended'] != 0) {
          counterUpdate['attendedClasses'] =
              FieldValue.increment(delta['attended']!);
        }
        if (delta['total'] != 0) {
          counterUpdate['totalClasses'] =
              FieldValue.increment(delta['total']!);
        }
        if (counterUpdate.length > 1) txn.update(subjectRef, counterUpdate);
      }

      // Update session status
      txn.update(sessionsRef, {'status': newStatus.name});
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, int> _delta(
      AttendanceStatus oldS, AttendanceStatus newS) {
    int attended = 0, total = 0;
    if (oldS == AttendanceStatus.present || oldS == AttendanceStatus.late) {
      attended--;
      total--;
    } else if (oldS == AttendanceStatus.absent) {
      total--;
    }
    if (newS == AttendanceStatus.present || newS == AttendanceStatus.late) {
      attended++;
      total++;
    } else if (newS == AttendanceStatus.absent) {
      total++;
    }
    return {'attended': attended, 'total': total};
  }

  static DateTime? _parseDateKey(String key) {
    // "YYYY-MM-DD"
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }

  static int _compareTime(String a, String b) {
    // "HH:MM"
    int mins(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    return mins(a).compareTo(mins(b));
  }

  static String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = now.hashCode.abs();
    return '$now$rnd';
  }
}
