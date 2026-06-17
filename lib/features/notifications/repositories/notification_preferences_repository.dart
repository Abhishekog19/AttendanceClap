import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/notification_preferences_model.dart';

part 'notification_preferences_repository.g.dart';

@riverpod
NotificationPreferencesRepository notificationPreferencesRepository(Ref ref) {
  return NotificationPreferencesRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository: reads/writes notification preferences from Firestore.
// Path: users/{uid}/notification_settings/prefs
// ─────────────────────────────────────────────────────────────────────────────

class NotificationPreferencesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationPreferencesRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid => _auth.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _prefsDoc => _firestore
      .collection('users')
      .doc(_uid)
      .collection('notification_settings')
      .doc('prefs');

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> savePreferences(NotificationPreferences prefs) async {
    if (_uid.isEmpty) return;
    await _prefsDoc.set(prefs.toFirestore(), SetOptions(merge: true));
  }

  // ── Load (one-shot) ───────────────────────────────────────────────────────

  Future<NotificationPreferences> loadPreferences() async {
    if (_uid.isEmpty) return NotificationPreferences.defaults();
    try {
      final doc = await _prefsDoc.get();
      if (!doc.exists || doc.data() == null) {
        return NotificationPreferences.defaults();
      }
      return NotificationPreferences.fromFirestore(doc.data()!);
    } catch (_) {
      return NotificationPreferences.defaults();
    }
  }

  // ── Watch (real-time stream) ──────────────────────────────────────────────

  Stream<NotificationPreferences> watchPreferences() {
    if (_uid.isEmpty) {
      return Stream.value(NotificationPreferences.defaults());
    }
    return _prefsDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return NotificationPreferences.defaults();
      }
      return NotificationPreferences.fromFirestore(snap.data()!);
    });
  }

  // ── Alert state helpers ───────────────────────────────────────────────────
  // Tracks when a low-attendance alert was last fired per subject,
  // so we don't spam. Resets once attendance recovers above threshold.

  DocumentReference<Map<String, dynamic>> _alertStateDoc(String subjectId) =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('notification_alert_state')
          .doc(subjectId);

  /// Returns true if an alert was already fired and attendance has NOT
  /// recovered since. Prevents repeated low-attendance spam.
  Future<bool> hasUnresolvedAlert(String subjectId) async {
    if (_uid.isEmpty) return false;
    final doc = await _alertStateDoc(subjectId).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    return data['resolvedAt'] == null;
  }

  /// Records that an alert was fired for a subject.
  Future<void> recordAlertFired(String subjectId) async {
    if (_uid.isEmpty) return;
    await _alertStateDoc(subjectId).set({
      'alertFiredAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
  }

  /// Records that attendance has recovered — alert can fire again next time
  /// it drops below threshold.
  Future<void> recordAlertResolved(String subjectId) async {
    if (_uid.isEmpty) return;
    await _alertStateDoc(subjectId).update({
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Daily attendance warning deduplication ────────────────────────────────
  // Prevents the aggregated attendance warning from being fired more than
  // once per day. A Firestore document tracks the last fired date.

  DocumentReference<Map<String, dynamic>> get _dailyWarningDoc => _firestore
      .collection('users')
      .doc(_uid)
      .collection('notification_alert_state')
      .doc('daily_warning');

  /// Returns true if an aggregated attendance warning was already generated
  /// today. Uses a stable date-key to prevent same-day duplicates.
  Future<bool> hasWarningFiredToday() async {
    if (_uid.isEmpty) return false;
    try {
      final doc = await _dailyWarningDoc.get();
      if (!doc.exists) return false;
      final lastFired = doc.data()?['lastFiredDate'] as String?;
      final todayKey = _dateKey(DateTime.now());
      return lastFired == todayKey;
    } catch (_) {
      return false;
    }
  }

  /// Records that today's aggregated warning notification was sent.
  Future<void> recordDailyWarningFired() async {
    if (_uid.isEmpty) return;
    await _dailyWarningDoc.set({
      'lastFiredDate': _dateKey(DateTime.now()),
      'firedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

