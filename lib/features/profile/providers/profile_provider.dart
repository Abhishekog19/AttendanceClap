import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/user_model.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/datasources/local_cache_datasource.dart';
import '../../../data/repositories/auth_repository.dart';

part 'profile_provider.g.dart';

@riverpod
Future<UserModel?> userProfile(Ref ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return null;
  return ref.watch(firestoreDatasourceProvider).getUserProfile(uid);
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
    ref.invalidate(userProfileProvider);
  }

  Future<void> updateTheme(String mode) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(firestoreDatasourceProvider).updateUserProfile(uid, {
      'themeMode': mode,
    });
    final cache = await ref.read(localCacheDatasourceProvider.future);
    await cache.saveThemeMode(mode);
    ref.invalidate(userProfileProvider);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}
