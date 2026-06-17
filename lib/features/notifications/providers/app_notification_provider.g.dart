// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appNotificationsHash() => r'c29b34778f200f8ad8ab5e3e2868b7087d0e7ba8';

/// See also [appNotifications].
@ProviderFor(appNotifications)
final appNotificationsProvider =
    AutoDisposeStreamProvider<List<AppNotificationModel>>.internal(
  appNotifications,
  name: r'appNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppNotificationsRef
    = AutoDisposeStreamProviderRef<List<AppNotificationModel>>;
String _$unreadNotificationCountHash() =>
    r'9433dc067d4c9caf35fb8597bfededc94186819b';

/// See also [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeProvider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationCountRef = AutoDisposeProviderRef<int>;
String _$appNotificationNotifierHash() =>
    r'ecb7f4a135abb57ac88793e268de912cd02dbc14';

/// See also [AppNotificationNotifier].
@ProviderFor(AppNotificationNotifier)
final appNotificationNotifierProvider = AutoDisposeNotifierProvider<
    AppNotificationNotifier, AsyncValue<List<AppNotificationModel>>>.internal(
  AppNotificationNotifier.new,
  name: r'appNotificationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appNotificationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppNotificationNotifier
    = AutoDisposeNotifier<AsyncValue<List<AppNotificationModel>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
