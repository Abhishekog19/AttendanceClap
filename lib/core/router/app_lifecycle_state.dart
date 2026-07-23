/// Single source of truth for app boot/navigation state.
///
/// This is the ONLY place in the app that translates `app_settings` fields
/// into a navigation decision. The router watches [appLifecycleStateProvider]
/// and redirects based on the returned variant — nothing else in the app is
/// allowed to make a "should I navigate somewhere?" decision.
///
/// ## State machine
///
/// ```
/// app_settings row absent → onboarding('welcome')   (fresh install)
/// onboarding_complete == 0 → onboarding(step)
/// onboarding_complete == 1, active_semester_id == null → needsSemester()
/// onboarding_complete == 1, active_semester_id != null → ready(semId)
/// ```

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/database.dart';

part 'app_lifecycle_state.g.dart';

// ── Database singleton provider ───────────────────────────────────────────────

/// The single [AppDatabase] instance for the whole app.
///
/// [keepAlive: true] — disposing a Drift database closes the underlying SQLite
/// file handle, so this provider must never be torn down mid-session.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => AppDatabase();

// ── AppLifecycleState sealed class ───────────────────────────────────────────

/// Every possible app state, derived purely from the `app_settings` SQLite row.
sealed class AppLifecycleState {
  const AppLifecycleState();

  /// Settings row not yet loaded. Router must NOT redirect in this state.
  const factory AppLifecycleState.booting() = AppLifecycleBooting;

  /// Onboarding incomplete. [step] is the step to resume at.
  const factory AppLifecycleState.onboarding(String step) =
      AppLifecycleOnboarding;

  /// Onboarding done, but no active semester set.
  const factory AppLifecycleState.needsSemester() = AppLifecycleNeedsSemester;

  /// Fully ready — onboarding complete and active semester exists.
  const factory AppLifecycleState.ready(String activeSemesterId) =
      AppLifecycleReady;
}

/// Concrete type for [AppLifecycleState.booting].
/// Public so it can be used in exhaustive switch patterns across files.
final class AppLifecycleBooting extends AppLifecycleState {
  const AppLifecycleBooting();
}

/// Concrete type for [AppLifecycleState.onboarding].
/// Public so it can be used in exhaustive switch patterns across files.
final class AppLifecycleOnboarding extends AppLifecycleState {
  final String step;
  const AppLifecycleOnboarding(this.step);
}

/// Concrete type for [AppLifecycleState.needsSemester].
/// Public so it can be used in exhaustive switch patterns across files.
final class AppLifecycleNeedsSemester extends AppLifecycleState {
  const AppLifecycleNeedsSemester();
}

/// Concrete type for [AppLifecycleState.ready].
/// Public so it can be used in exhaustive switch patterns across files.
final class AppLifecycleReady extends AppLifecycleState {
  final String activeSemesterId;
  const AppLifecycleReady(this.activeSemesterId);
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Watches the singleton `app_settings` row (id = 1) and emits the correct
/// [AppLifecycleState]. Stream-backed so the router reacts to any write.
///
/// [keepAlive: true] — the router always needs an up-to-date state.
@Riverpod(keepAlive: true)
Stream<AppLifecycleState> appLifecycleState(Ref ref) {
  final db = ref.watch(appDatabaseProvider);

  return (db.select(db.appSettings)..where((s) => s.id.equals(1)))
      .watchSingleOrNull()
      .map(_rowToState);
}

/// Pure function: [AppSetting] row → [AppLifecycleState].
AppLifecycleState _rowToState(AppSetting? row) {
  if (row == null) {
    // Fresh install — no row yet; start onboarding from welcome.
    return const AppLifecycleState.onboarding('welcome');
  }

  if (row.onboardingComplete != 1) {
    return AppLifecycleState.onboarding(row.onboardingStep ?? 'welcome');
  }

  final semId = row.activeSemesterId;
  if (semId == null || semId.isEmpty) {
    return const AppLifecycleState.needsSemester();
  }

  return AppLifecycleState.ready(semId);
}
