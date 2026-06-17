// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileHash() => r'120344a359db08572b105facb59d835d9b5942b6';

/// See also [userProfile].
@ProviderFor(userProfile)
final userProfileProvider = AutoDisposeStreamProvider<UserModel?>.internal(
  userProfile,
  name: r'userProfileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserProfileRef = AutoDisposeStreamProviderRef<UserModel?>;
String _$attendanceGoalHash() => r'25e3caa7f834d97aabceaa6490162dbb9b8d99a4';

/// See also [attendanceGoal].
@ProviderFor(attendanceGoal)
final attendanceGoalProvider = AutoDisposeProvider<double>.internal(
  attendanceGoal,
  name: r'attendanceGoalProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attendanceGoalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttendanceGoalRef = AutoDisposeProviderRef<double>;
String _$themeModeProviderHash() => r'11eb8ea6aaf511e25ba00e4ee6ea4e23858695da';

/// See also [themeModeProvider].
@ProviderFor(themeModeProvider)
final themeModeProviderProvider = AutoDisposeProvider<ThemeMode>.internal(
  themeModeProvider,
  name: r'themeModeProviderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeModeProviderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ThemeModeProviderRef = AutoDisposeProviderRef<ThemeMode>;
String _$profileNotifierHash() => r'728321d9560c49f08dcb36e7bf65f287ab9f1cca';

/// See also [ProfileNotifier].
@ProviderFor(ProfileNotifier)
final profileNotifierProvider = AutoDisposeNotifierProvider<ProfileNotifier,
    AsyncValue<UserModel?>>.internal(
  ProfileNotifier.new,
  name: r'profileNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileNotifier = AutoDisposeNotifier<AsyncValue<UserModel?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
