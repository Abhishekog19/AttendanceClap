import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/auth_repository.dart';
import '../models/app_notification_model.dart';
import '../repositories/app_notification_repository.dart';

part 'app_notification_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// appNotificationsProvider
//
// Real-time stream of all notifications for the current user.
// Automatically re-subscribes when the auth user changes.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<AppNotificationModel>> appNotifications(Ref ref) {
  // Re-subscribe whenever the authenticated user changes.
  ref.watch(authStateChangesProvider);

  final repo = ref.watch(appNotificationRepositoryProvider);
  return repo.watchNotifications();
}

// ── Derived: unread count ─────────────────────────────────────────────────────

@riverpod
int unreadNotificationCount(Ref ref) {
  final notifications = ref.watch(appNotificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNotificationNotifier
//
// Handles user actions: markAsRead, markAllAsRead, delete, and adding new
// notifications from other parts of the app (scheduler, etc.).
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class AppNotificationNotifier extends _$AppNotificationNotifier {
  @override
  AsyncValue<List<AppNotificationModel>> build() {
    return ref.watch(appNotificationsProvider);
  }

  AppNotificationRepository get _repo =>
      ref.read(appNotificationRepositoryProvider);

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _repo.markAsRead(notificationId);
  }

  /// Mark all unread notifications as read.
  Future<void> markAllAsRead() async {
    final notifications = state.valueOrNull ?? [];
    final unreadIds =
        notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;
    await _repo.markAllAsRead(unreadIds);
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String notificationId) async {
    await _repo.deleteNotification(notificationId);
  }

  /// Add a new notification (called by scheduler, etc.).
  /// Returns false if a notification with the same [stableId] already exists
  /// (deduplication guard).
  Future<bool> addNotification({
    required String stableId,
    required String title,
    required String message,
    required AppNotificationType type,
  }) async {
    // Dedup: don't add if already exists
    final exists = await _repo.notificationExists(stableId);
    if (exists) {
      // ignore: avoid_print
      print('[AppNotifications] Skipped duplicate: $stableId');
      return false;
    }

    final notification = AppNotificationModel(
      id: stableId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _repo.addNotification(notification);
    // ignore: avoid_print
    print('[AppNotifications] Added: $stableId — $title');
    return true;
  }
}

// ── Convenience: generate a stable daily notification ID ─────────────────────

/// Generates a stable notification ID for a given [type] and [dateKey] (YYYY-MM-DD).
/// Using the same ID on the same day prevents duplicate Firestore writes.
String dailyNotificationId(AppNotificationType type, String dateKey) {
  return '${type.name}_$dateKey';
}

/// Generates a unique notification ID.
String generateNotificationId() => const Uuid().v4();
