// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'predictor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$predictorEntriesStreamHash() =>
    r'bf8b70dba564ad26db420d80e26033c3ad3a7b41';

/// See also [predictorEntriesStream].
@ProviderFor(predictorEntriesStream)
final predictorEntriesStreamProvider =
    AutoDisposeStreamProvider<List<TimetableEntry>>.internal(
  predictorEntriesStream,
  name: r'predictorEntriesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$predictorEntriesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PredictorEntriesStreamRef
    = AutoDisposeStreamProviderRef<List<TimetableEntry>>;
String _$predictorSemesterHash() => r'87fab0194e4454e67ae53cc19f4ccf5d3b8d691b';

/// See also [predictorSemester].
@ProviderFor(predictorSemester)
final predictorSemesterProvider = AutoDisposeFutureProvider<Semester?>.internal(
  predictorSemester,
  name: r'predictorSemesterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$predictorSemesterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PredictorSemesterRef = AutoDisposeFutureProviderRef<Semester?>;
String _$predictorDataHash() => r'731252c4ffaea8dda95be6e3a1c7026c648edc0e';

/// See also [predictorData].
@ProviderFor(predictorData)
final predictorDataProvider =
    AutoDisposeFutureProvider<PredictorData?>.internal(
  predictorData,
  name: r'predictorDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$predictorDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PredictorDataRef = AutoDisposeFutureProviderRef<PredictorData?>;
String _$leavePlanResultHash() => r'79388739a1ca726921edf26b85220a2b0bfc7a9f';

/// See also [leavePlanResult].
@ProviderFor(leavePlanResult)
final leavePlanResultProvider = AutoDisposeProvider<LeavePlanResult?>.internal(
  leavePlanResult,
  name: r'leavePlanResultProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$leavePlanResultHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeavePlanResultRef = AutoDisposeProviderRef<LeavePlanResult?>;
String _$whatIfResultHash() => r'f5b015c4763421a488dc532dde56e6d4519a9d1c';

/// See also [whatIfResult].
@ProviderFor(whatIfResult)
final whatIfResultProvider = AutoDisposeProvider<double?>.internal(
  whatIfResult,
  name: r'whatIfResultProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$whatIfResultHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WhatIfResultRef = AutoDisposeProviderRef<double?>;
String _$whatIfNotifierHash() => r'c6d9f8950f62dcee01351e0fa8d961c720e20fba';

/// See also [WhatIfNotifier].
@ProviderFor(WhatIfNotifier)
final whatIfNotifierProvider =
    AutoDisposeNotifierProvider<WhatIfNotifier, WhatIfState>.internal(
  WhatIfNotifier.new,
  name: r'whatIfNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$whatIfNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WhatIfNotifier = AutoDisposeNotifier<WhatIfState>;
String _$leavePlannerNotifierHash() =>
    r'5588d4f535740abeafbb46f8c2f9f88cb61a5283';

/// See also [LeavePlannerNotifier].
@ProviderFor(LeavePlannerNotifier)
final leavePlannerNotifierProvider =
    AutoDisposeNotifierProvider<LeavePlannerNotifier, DateTimeRange?>.internal(
  LeavePlannerNotifier.new,
  name: r'leavePlannerNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$leavePlannerNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LeavePlannerNotifier = AutoDisposeNotifier<DateTimeRange?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
