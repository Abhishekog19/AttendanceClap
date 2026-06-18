import 'package:cloud_firestore/cloud_firestore.dart';
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
// Real-time stream of the LATEST page of notifications.
// Limited to AppNotificationRepository.pageSize (20) docs — efficient.
// Re-subscribes automatically when the auth user changes.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<AppNotificationModel>> appNotifications(Ref ref) {
  ref.watch(authStateChangesProvider); // re-subscribe on auth change
  final repo = ref.watch(appNotificationRepositoryProvider);
  return repo.watchLatestPage();
}

// ── Unread badge count (lightweight query, not full list) ─────────────────────

@riverpod
Stream<int> unreadNotificationCount(Ref ref) {
  ref.watch(authStateChangesProvider); // re-subscribe on auth change
  final repo = ref.watch(appNotificationRepositoryProvider);
  return repo.watchUnreadCount();
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationPageState
//
// Holds the complete paginated list for the notification center screen.
// - pages[0] comes from the real-time stream (appNotificationsProvider)
// - subsequent pages are fetched one-shot via fetchNextPage()
//
// This approach keeps the first page live (new notifications appear instantly)
// while older pages are loaded on demand to limit Firestore reads.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationPageState {
  final List<AppNotificationModel> notifications;
  final bool isLoadingMore;
  final bool hasMore;
  final String? lastDocId; // ID of the oldest notification in current list

  const NotificationPageState({
    this.notifications = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDocId,
  });

  NotificationPageState copyWith({
    List<AppNotificationModel>? notifications,
    bool? isLoadingMore,
    bool? hasMore,
    String? lastDocId,
  }) {
    return NotificationPageState(
      notifications: notifications ?? this.notifications,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocId: lastDocId ?? this.lastDocId,
    );
  }
}

@riverpod
class NotificationPagination extends _$NotificationPagination {
  @override
  NotificationPageState build() {
    // Seed with the live first page from the stream
    ref.listen(appNotificationsProvider, (_, next) {
      final fresh = next.valueOrNull ?? [];

      // N6 FIX: Use ID-based merge instead of index-based sublist.
      // Index-based (sublist) breaks when stream emits deletions — the offset
      // shifts and extra-page items get duplicated or dropped.
      final freshIds = {for (final n in fresh) n.id};
      // Keep only extra-page items that are NOT already in the fresh first page
      final extraPageItems = state.notifications
          .where((n) => !freshIds.contains(n.id))
          .toList();

      final merged = [...fresh, ...extraPageItems];
      state = state.copyWith(
        notifications: merged,
        lastDocId: merged.isNotEmpty ? merged.last.id : null,
        // If first page is less than pageSize, no more pages exist
        hasMore: fresh.length >= AppNotificationRepository.pageSize,
      );
    }, fireImmediately: true);

    return const NotificationPageState();
  }

  /// Load the next page of older notifications.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDocId == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = ref.read(appNotificationRepositoryProvider);
      final lastDoc = await repo.getDocSnapshot(state.lastDocId!);
      if (lastDoc == null) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      final nextPage = await repo.fetchNextPage(lastDoc);
      final combined = [...state.notifications, ...nextPage];
      state = state.copyWith(
        notifications: combined,
        isLoadingMore: false,
        hasMore: nextPage.length >= AppNotificationRepository.pageSize,
        lastDocId: nextPage.isNotEmpty ? nextPage.last.id : state.lastDocId,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNotificationNotifier
//
// Handles user actions: markAsRead, markAllAsRead, delete, addNotification.
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

  /// Mark ALL unread notifications as read — not just the paginated page.
  /// N2 FIX: Previously only marked the currently-loaded page (≤20 items),
  /// leaving older unread notifications and keeping the badge dirty.
  /// Now fetches all unread IDs directly from Firestore.
  Future<void> markAllAsRead() async {
    final allUnreadIds = await _repo.getAllUnreadIds();
    if (allUnreadIds.isEmpty) return;
    await _repo.markAllAsRead(allUnreadIds);
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

// ── Convenience helpers ───────────────────────────────────────────────────────

/// Generates a stable notification ID for a given [type] and [dateKey] (YYYY-MM-DD).
/// Using the same ID on the same day prevents duplicate Firestore writes.
String dailyNotificationId(AppNotificationType type, String dateKey) {
  return '${type.name}_$dateKey';
}

/// Generates a unique notification ID.
String generateNotificationId() => const Uuid().v4();
