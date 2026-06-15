// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isPremiumUserHash() => r'a341dc3a0a55ebbcb557c768a2811ff267f95573';

/// Convenience provider — returns true if the current user has an active
/// premium subscription.
///
/// Copied from [isPremiumUser].
@ProviderFor(isPremiumUser)
final isPremiumUserProvider = AutoDisposeProvider<bool>.internal(
  isPremiumUser,
  name: r'isPremiumUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isPremiumUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsPremiumUserRef = AutoDisposeProviderRef<bool>;
String _$premiumNotifierHash() => r'b7c08b2e78d3a25f9dbdd4597464308b64a2b9d7';

/// See also [PremiumNotifier].
@ProviderFor(PremiumNotifier)
final premiumNotifierProvider =
    AutoDisposeNotifierProvider<PremiumNotifier, PremiumState>.internal(
  PremiumNotifier.new,
  name: r'premiumNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$premiumNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PremiumNotifier = AutoDisposeNotifier<PremiumState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
