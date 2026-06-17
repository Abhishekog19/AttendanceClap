import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/user_model.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/datasources/local_cache_datasource.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../features/subjects/providers/subjects_provider.dart';
import '../../../features/notifications/providers/notification_preferences_provider.dart';
import '../../../features/notifications/providers/app_notification_provider.dart';

part 'profile_provider.g.dart';

// ── TASK 8: User Profile Stream ──────────────────────────────────────────────
//
// userProfileProvider is now a STREAM-backed provider (not one-shot Future).
// Changes to the user profile document in Firestore (attendance goal, theme,
// premium status, etc.) propagate INSTANTLY to all watching providers:
//   • attendanceGoalProvider → Dashboard, Analytics, Notifications
//   • themeModeProviderProvider → App theme (light/dark/system)
//   • ProfileNotifier.build() → Profile screen UI
//
// The manual ref.invalidate(userProfileProvider) calls in updateGoal() and
// updateTheme() have been removed — the stream self-updates.

@riverpod
Stream<UserModel?> userProfile(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreDatasourceProvider).watchUserProfile(uid);
}

@riverpod
double attendanceGoal(Ref ref) {
  final userAsync = ref.watch(userProfileProvider);
  return userAsync.valueOrNull?.attendanceGoal ?? 75.0;
}

@riverpod
ThemeMode themeModeProvider(Ref ref) {
  final userAsync = ref.watch(userProfileProvider);
  final mode = userAsync.valueOrNull?.themeMode ?? 'system';
  return switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  AsyncValue<UserModel?> build() {
    // Watch the stream — updates automatically when Firestore doc changes.
    return ref.watch(userProfileProvider);
  }

  Future<void> updateGoal(double goal) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(firestoreDatasourceProvider).updateUserProfile(uid, {
      'attendanceGoal': goal,
    });
    // Also save locally for offline access
    final cache = await ref.read(localCacheDatasourceProvider.future);
    await cache.saveAttendanceGoal(goal);
    // No ref.invalidate() needed — stream auto-updates from Firestore.
  }

  Future<void> updateTheme(String mode) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(firestoreDatasourceProvider).updateUserProfile(uid, {
      'themeMode': mode,
    });
    final cache = await ref.read(localCacheDatasourceProvider.future);
    await cache.saveThemeMode(mode);
    // No ref.invalidate() needed — stream auto-updates from Firestore.
  }

  Future<void> signOut() async {
    // 1. Sign out from Firebase and Google
    await ref.read(authRepositoryProvider).signOut();

    // 2. Invalidate all user-specific providers to prevent stale data leaking
    //    into the next account's session. Without this, Account A's data can
    //    briefly appear when Account B logs in.
    ref.invalidate(userProfileProvider);
    ref.invalidate(subjectsNotifierProvider);
    ref.invalidate(notificationPreferencesProvider);
    ref.invalidate(appNotificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);

    // 3. Reset self
    ref.invalidateSelf();
  }
}
