// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appNotificationsHash() => r'3bf8655ecb4d197c6df3b08dc7eb5e69a96c2385';

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
    r'f293a713dd8e9684730bbf86e038bcb0d48c23c7';

/// See also [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeStreamProvider<int>.internal(
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
typedef UnreadNotificationCountRef = AutoDisposeStreamProviderRef<int>;
String _$notificationPaginationHash() =>
    r'be50962480d869cbbea5741d468fd30c44a01abd';

/// See also [NotificationPagination].
@ProviderFor(NotificationPagination)
final notificationPaginationProvider = AutoDisposeNotifierProvider<
    NotificationPagination, NotificationPageState>.internal(
  NotificationPagination.new,
  name: r'notificationPaginationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPaginationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationPagination = AutoDisposeNotifier<NotificationPageState>;
String _$appNotificationNotifierHash() =>
    r'c768f5b3a2e3156a1c81e28b4f1fe77dc8e00acb';

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
