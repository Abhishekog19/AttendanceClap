// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appNotificationsHash() => r'edc0988e7d3676676385771de2749f9138f733fd';

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
    r'7bda1a09b3fd05ba4c472aa971c1e418b72a9f55';

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
    r'41a3d7fca0470a2eded74c60dea826480da72f43';

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
    r'7427154801430266c7772d42118b5b3188ba6907';

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
