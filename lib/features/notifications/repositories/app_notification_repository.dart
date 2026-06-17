import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_notification_model.dart';

part 'app_notification_repository.g.dart';

@riverpod
AppNotificationRepository appNotificationRepository(Ref ref) {
  return AppNotificationRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNotificationRepository
//
// Manages app-generated notifications stored in Firestore.
// Path: users/{uid}/notifications/{notificationId}
//
// All notifications survive:
//   - App restart
//   - Device restart
//   - Logout/login (same uid)
//   - Firebase sync
// ─────────────────────────────────────────────────────────────────────────────

class AppNotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AppNotificationRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> _notificationsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  // ── Stream: real-time ordered list ───────────────────────────────────────

  /// Watch all notifications for the current user, newest first.
  Stream<List<AppNotificationModel>> watchNotifications() {
    if (_uid.isEmpty) return Stream.value([]);
    return _notificationsCol(_uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotificationModel.fromFirestore(d.data()))
            .toList());
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  /// Adds a new notification to Firestore.
  Future<void> addNotification(AppNotificationModel notification) async {
    if (_uid.isEmpty) return;
    await _notificationsCol(_uid)
        .doc(notification.id)
        .set(notification.toFirestore());
  }

  // ── Read state ────────────────────────────────────────────────────────────

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    if (_uid.isEmpty) return;
    await _notificationsCol(_uid).doc(notificationId).update({'isRead': true});
  }

  /// Marks ALL unread notifications as read in a single batch.
  Future<void> markAllAsRead(List<String> unreadIds) async {
    if (_uid.isEmpty || unreadIds.isEmpty) return;

    const chunkSize = 400;
    for (int i = 0; i < unreadIds.length; i += chunkSize) {
      final chunk = unreadIds.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final id in chunk) {
        batch.update(_notificationsCol(_uid).doc(id), {'isRead': true});
      }
      await batch.commit();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Deletes a single notification.
  Future<void> deleteNotification(String notificationId) async {
    if (_uid.isEmpty) return;
    await _notificationsCol(_uid).doc(notificationId).delete();
  }

  // ── Deduplication helpers ─────────────────────────────────────────────────

  /// Check if a notification with the given stable ID already exists.
  /// Used to prevent duplicate notifications for the same day/event.
  Future<bool> notificationExists(String notificationId) async {
    if (_uid.isEmpty) return false;
    final doc = await _notificationsCol(_uid).doc(notificationId).get();
    return doc.exists;
  }
}
