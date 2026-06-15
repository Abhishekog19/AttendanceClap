// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationPreferencesStreamHash() =>
    r'9068593e6e932f3aa2bcc3193cfeb12d9e6c8900';

/// See also [notificationPreferencesStream].
@ProviderFor(notificationPreferencesStream)
final notificationPreferencesStreamProvider =
    AutoDisposeStreamProvider<NotificationPreferences>.internal(
  notificationPreferencesStream,
  name: r'notificationPreferencesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPreferencesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationPreferencesStreamRef
    = AutoDisposeStreamProviderRef<NotificationPreferences>;
String _$notificationPreferencesHash() =>
    r'a8c71abb2675dd0339326d1edff895645d6b83ee';

/// See also [notificationPreferences].
@ProviderFor(notificationPreferences)
final notificationPreferencesProvider =
    AutoDisposeProvider<NotificationPreferences>.internal(
  notificationPreferences,
  name: r'notificationPreferencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPreferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationPreferencesRef
    = AutoDisposeProviderRef<NotificationPreferences>;
String _$notificationPreferencesNotifierHash() =>
    r'c3ef282b93573588d36253f44efc24f539a01b7e';

/// See also [NotificationPreferencesNotifier].
@ProviderFor(NotificationPreferencesNotifier)
final notificationPreferencesNotifierProvider = AutoDisposeNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>.internal(
  NotificationPreferencesNotifier.new,
  name: r'notificationPreferencesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPreferencesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationPreferencesNotifier
    = AutoDisposeNotifier<AsyncValue<NotificationPreferences>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
