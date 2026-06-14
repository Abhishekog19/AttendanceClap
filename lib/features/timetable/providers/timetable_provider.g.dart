// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timetableStreamHash() => r'771ea8e1b2c2e411d7d29fb12dbc61c30a4d7282';

/// See also [timetableStream].
@ProviderFor(timetableStream)
final timetableStreamProvider =
    AutoDisposeStreamProvider<List<TimetableModel>>.internal(
  timetableStream,
  name: r'timetableStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timetableStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TimetableStreamRef = AutoDisposeStreamProviderRef<List<TimetableModel>>;
String _$todayClassesHash() => r'ec3abfbaeedff92cb879c38ed3a0b2f4f7d20f4e';

/// See also [todayClasses].
@ProviderFor(todayClasses)
final todayClassesProvider = AutoDisposeProvider<List<TimetableModel>>.internal(
  todayClasses,
  name: r'todayClassesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todayClassesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayClassesRef = AutoDisposeProviderRef<List<TimetableModel>>;
String _$currentClassHash() => r'ecb150fa17c8b9c8a3d486c221d0d47a5544245d';

/// See also [currentClass].
@ProviderFor(currentClass)
final currentClassProvider = AutoDisposeProvider<TimetableModel?>.internal(
  currentClass,
  name: r'currentClassProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentClassHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentClassRef = AutoDisposeProviderRef<TimetableModel?>;
String _$nextClassHash() => r'99a907531171533dd4b398e7fc98690d3d3b1866';

/// See also [nextClass].
@ProviderFor(nextClass)
final nextClassProvider = AutoDisposeProvider<TimetableModel?>.internal(
  nextClass,
  name: r'nextClassProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$nextClassHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NextClassRef = AutoDisposeProviderRef<TimetableModel?>;
String _$timetableNotifierHash() => r'24b22850638beb3f612a9b1ff9514dd032eb23a6';

/// See also [TimetableNotifier].
@ProviderFor(TimetableNotifier)
final timetableNotifierProvider =
    AutoDisposeNotifierProvider<TimetableNotifier, bool>.internal(
  TimetableNotifier.new,
  name: r'timetableNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timetableNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TimetableNotifier = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
