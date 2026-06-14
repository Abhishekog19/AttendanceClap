// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$attendanceLogsStreamHash() =>
    r'528bb9797749b1a014b14ea7870042fff8ff8cf7';

/// See also [attendanceLogsStream].
@ProviderFor(attendanceLogsStream)
final attendanceLogsStreamProvider =
    AutoDisposeStreamProvider<List<AttendanceLogModel>>.internal(
  attendanceLogsStream,
  name: r'attendanceLogsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attendanceLogsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttendanceLogsStreamRef
    = AutoDisposeStreamProviderRef<List<AttendanceLogModel>>;
String _$filteredLogsHash() => r'4e8fd23afa2c37c1afe71f2e9089e41016e5be0e';

/// See also [filteredLogs].
@ProviderFor(filteredLogs)
final filteredLogsProvider =
    AutoDisposeProvider<List<AttendanceLogModel>>.internal(
  filteredLogs,
  name: r'filteredLogsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$filteredLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredLogsRef = AutoDisposeProviderRef<List<AttendanceLogModel>>;
String _$filteredStatsHash() => r'd2883f367a089b83d13465e61729a32143e3fff1';

/// See also [filteredStats].
@ProviderFor(filteredStats)
final filteredStatsProvider = AutoDisposeProvider<AttendanceStats>.internal(
  filteredStats,
  name: r'filteredStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredStatsRef = AutoDisposeProviderRef<AttendanceStats>;
String _$groupedLogsHash() => r'79530391000a62fe79a03789c0820b25ae5578c2';

/// See also [groupedLogs].
@ProviderFor(groupedLogs)
final groupedLogsProvider =
    AutoDisposeProvider<Map<String, List<AttendanceLogModel>>>.internal(
  groupedLogs,
  name: r'groupedLogsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupedLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupedLogsRef
    = AutoDisposeProviderRef<Map<String, List<AttendanceLogModel>>>;
String _$attendanceFilterNotifierHash() =>
    r'c5a4af0214e42f6c11e01683ed768e4cc1e8cf2a';

/// See also [AttendanceFilterNotifier].
@ProviderFor(AttendanceFilterNotifier)
final attendanceFilterNotifierProvider = AutoDisposeNotifierProvider<
    AttendanceFilterNotifier, AttendanceFilter>.internal(
  AttendanceFilterNotifier.new,
  name: r'attendanceFilterNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attendanceFilterNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AttendanceFilterNotifier = AutoDisposeNotifier<AttendanceFilter>;
String _$logEditNotifierHash() => r'c9f4dbcacdd318cc6d4c1386f9298d4dbae87a0b';

/// See also [LogEditNotifier].
@ProviderFor(LogEditNotifier)
final logEditNotifierProvider =
    AutoDisposeNotifierProvider<LogEditNotifier, LogEditState>.internal(
  LogEditNotifier.new,
  name: r'logEditNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$logEditNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LogEditNotifier = AutoDisposeNotifier<LogEditState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
