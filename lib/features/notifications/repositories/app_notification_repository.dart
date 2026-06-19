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
// Pagination strategy:
//   • watchLatestPage() — real-time stream of latest [pageSize] notifications.
//     Used for badge count and initial list render.
//   • fetchNextPage() — cursor-based one-shot fetch for "load more".
//   • watchUnreadCount() — lightweight stream counting only unread docs.
//
// All notifications survive:
//   - App restart / device restart
//   - Logout/login (same uid)
//   - Firebase sync
// ─────────────────────────────────────────────────────────────────────────────

class AppNotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const int pageSize = 20;

  AppNotificationRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> _notificationsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  // ── Real-time stream: latest page (for list + badge) ─────────────────────

  /// Streams the latest [pageSize] notifications, newest first.
  /// This is the primary source for the notification center's first page
  /// and triggers real-time badge updates when new notifications arrive.
  Stream<List<AppNotificationModel>> watchLatestPage() {
    if (_uid.isEmpty) return Stream.value([]);
    return _notificationsCol(_uid)
        .orderBy('createdAt', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotificationModel.fromFirestore(d.data()))
            .toList());
  }

  /// Lightweight stream that counts unread notifications without fetching docs.
  /// Capped at 100 to keep reads fast. UI shows "99+" when at/above cap.
  Stream<int> watchUnreadCount() {
    if (_uid.isEmpty) return Stream.value(0);
    return _notificationsCol(_uid)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Fetches ALL unread notification IDs from Firestore, chunked to avoid
  /// exceeding Firestore's query limits. Used by markAllAsRead so it covers
  /// notifications beyond the currently-loaded pagination page.
  Future<List<String>> getAllUnreadIds() async {
    if (_uid.isEmpty) return [];

    final ids = <String>[];
    DocumentSnapshot? lastDoc;

    // Page through all unread docs in chunks of 400 to stay under limits
    while (true) {
      var query = _notificationsCol(_uid)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(400);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        // Use doc.id (Firestore's canonical document ID) rather than reading
        // 'id' from the data map. The data-layer field could be missing or
        // stale for partially-written documents, silently skipping records.
        // doc.id is always present and never empty.
        ids.add(doc.id);
      }

      if (snap.docs.length < 400) break;
      lastDoc = snap.docs.last;
    }

    return ids;
  }

  // ── Pagination: load more ─────────────────────────────────────────────────

  /// Fetches the next page of notifications after [lastDoc].
  /// Returns an empty list when there are no more notifications.
  Future<List<AppNotificationModel>> fetchNextPage(
      DocumentSnapshot lastDoc) async {
    if (_uid.isEmpty) return [];
    final snap = await _notificationsCol(_uid)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(pageSize)
        .get();
    return snap.docs
        .map((d) => AppNotificationModel.fromFirestore(d.data()))
        .toList();
  }

  /// Fetches the raw Firestore snapshot for the last document in the current page.
  /// Used as the pagination cursor for fetchNextPage().
  Future<DocumentSnapshot?> getDocSnapshot(String notificationId) async {
    if (_uid.isEmpty) return null;
    final doc =
        await _notificationsCol(_uid).doc(notificationId).get();
    return doc.exists ? doc : null;
  }

  // ── Backward-compat: stream used by badge provider ─────────────────────────

  /// Alias for watchLatestPage() — kept so existing provider code compiles.
  Stream<List<AppNotificationModel>> watchNotifications() =>
      watchLatestPage();

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

  // ── Clear all ─────────────────────────────────────────────────────────────

  /// Permanently deletes ALL notifications for the current user.
  /// Executes in batch pages of 400 to stay within Firestore write limits.
  /// This is a destructive, irreversible operation — always confirm before calling.
  Future<void> clearAll() async {
    // Capture the uid once before the loop begins so that an auth change
    // mid-deletion cannot redirect later batches to a different user's account.
    final uid = _uid;
    if (uid.isEmpty) return;

    DocumentSnapshot? lastDoc;
    while (true) {
      var query = _notificationsCol(uid).limit(400);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snap.docs.length < 400) break;
      lastDoc = snap.docs.last;
    }
  }
}
