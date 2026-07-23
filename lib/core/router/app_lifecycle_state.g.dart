// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lifecycle_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'98a09c6cfd43966155dfbdb0787fa18c85438e13';

/// The single [AppDatabase] instance for the whole app.
///
/// [keepAlive: true] — disposing a Drift database closes the underlying SQLite
/// file handle, so this provider must never be torn down mid-session.
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$appLifecycleStateHash() => r'a4488c62ef8bd9f0c4110aea665491b35e944c4b';

/// Watches the singleton `app_settings` row (id = 1) and emits the correct
/// [AppLifecycleState]. Stream-backed so the router reacts to any write.
///
/// [keepAlive: true] — the router always needs an up-to-date state.
///
/// Copied from [appLifecycleState].
@ProviderFor(appLifecycleState)
final appLifecycleStateProvider = StreamProvider<AppLifecycleState>.internal(
  appLifecycleState,
  name: r'appLifecycleStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appLifecycleStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppLifecycleStateRef = StreamProviderRef<AppLifecycleState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
