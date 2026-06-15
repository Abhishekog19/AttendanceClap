import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/notification_preferences_model.dart';
import '../repositories/notification_preferences_repository.dart';

part 'notification_preferences_provider.g.dart';

// ── Stream provider ───────────────────────────────────────────────────────────

@riverpod
Stream<NotificationPreferences> notificationPreferencesStream(Ref ref) {
  final repo = ref.watch(notificationPreferencesRepositoryProvider);
  return repo.watchPreferences();
}

// ── Convenience accessor (sync, falls back to defaults) ───────────────────────

@riverpod
NotificationPreferences notificationPreferences(Ref ref) {
  return ref.watch(notificationPreferencesStreamProvider).valueOrNull ??
      NotificationPreferences.defaults();
}

// ── Notifier (for settings screen mutations) ──────────────────────────────────

@riverpod
class NotificationPreferencesNotifier
    extends _$NotificationPreferencesNotifier {
  @override
  AsyncValue<NotificationPreferences> build() {
    return ref.watch(notificationPreferencesStreamProvider).whenData((p) => p);
  }

  NotificationPreferencesRepository get _repo =>
      ref.read(notificationPreferencesRepositoryProvider);

  Future<void> update(NotificationPreferences updated) async {
    await _repo.savePreferences(updated);
    // Stream will auto-update via Firestore listener
  }

  /// Convenience: patch a single field and persist.
  Future<void> patch(
      NotificationPreferences Function(NotificationPreferences) patcher) async {
    final current = state.valueOrNull ?? NotificationPreferences.defaults();
    await _repo.savePreferences(patcher(current));
  }
}
