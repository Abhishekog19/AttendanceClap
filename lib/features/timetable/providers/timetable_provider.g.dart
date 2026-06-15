// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todaySessionsStreamHash() =>
    r'412472dc8b1caee04f65804068bba78ef7273226';

/// See also [todaySessionsStream].
@ProviderFor(todaySessionsStream)
final todaySessionsStreamProvider =
    AutoDisposeStreamProvider<List<ClassSession>>.internal(
  todaySessionsStream,
  name: r'todaySessionsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todaySessionsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodaySessionsStreamRef
    = AutoDisposeStreamProviderRef<List<ClassSession>>;
String _$todayOverridesStreamHash() =>
    r'ec77c5610aaed59d5f6d9c242af9dd9183fb2388';

/// See also [todayOverridesStream].
@ProviderFor(todayOverridesStream)
final todayOverridesStreamProvider =
    AutoDisposeStreamProvider<List<DailyScheduleOverride>>.internal(
  todayOverridesStream,
  name: r'todayOverridesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayOverridesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayOverridesStreamRef
    = AutoDisposeStreamProviderRef<List<DailyScheduleOverride>>;
String _$schedulePageDataHash() => r'e9e869fdcbdfceb15d9bef579d6107360fbb33fc';

/// See also [schedulePageData].
@ProviderFor(schedulePageData)
final schedulePageDataProvider = AutoDisposeProvider<SchedulePageData>.internal(
  schedulePageData,
  name: r'schedulePageDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$schedulePageDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SchedulePageDataRef = AutoDisposeProviderRef<SchedulePageData>;
String _$clockTickHash() => r'f5e587d77891f0ad73da5505a687cb4f47b96747';

/// See also [clockTick].
@ProviderFor(clockTick)
final clockTickProvider = AutoDisposeStreamProvider<DateTime>.internal(
  clockTick,
  name: r'clockTickProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$clockTickHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClockTickRef = AutoDisposeStreamProviderRef<DateTime>;
String _$todayClassesHash() => r'1ead3d143200042a1caf5c0ccf5c2725affa0381';

/// See also [todayClasses].
@ProviderFor(todayClasses)
final todayClassesProvider = AutoDisposeProvider<List<ClassSession>>.internal(
  todayClasses,
  name: r'todayClassesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todayClassesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayClassesRef = AutoDisposeProviderRef<List<ClassSession>>;
String _$currentClassHash() => r'79ffd72672a980ba534d2ade9e289ae94346dfc2';

/// See also [currentClass].
@ProviderFor(currentClass)
final currentClassProvider = AutoDisposeProvider<ClassSession?>.internal(
  currentClass,
  name: r'currentClassProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentClassHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentClassRef = AutoDisposeProviderRef<ClassSession?>;
String _$nextClassHash() => r'2658a96f4ca7e5f36ac47921956080e092461801';

/// See also [nextClass].
@ProviderFor(nextClass)
final nextClassProvider = AutoDisposeProvider<ClassSession?>.internal(
  nextClass,
  name: r'nextClassProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$nextClassHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NextClassRef = AutoDisposeProviderRef<ClassSession?>;
String _$scheduleNotifierHash() => r'64bdba2acf5c98354a560eae23b3f339383293a3';

/// See also [ScheduleNotifier].
@ProviderFor(ScheduleNotifier)
final scheduleNotifierProvider = AutoDisposeNotifierProvider<ScheduleNotifier,
    ScheduleNotifierState>.internal(
  ScheduleNotifier.new,
  name: r'scheduleNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scheduleNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScheduleNotifier = AutoDisposeNotifier<ScheduleNotifierState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
