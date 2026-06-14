// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_timetable_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timetableEntriesStreamHash() =>
    r'59d1ebea72af979317e85117f2b56b098ea16e18';

/// See also [timetableEntriesStream].
@ProviderFor(timetableEntriesStream)
final timetableEntriesStreamProvider =
    AutoDisposeStreamProvider<List<TimetableEntry>>.internal(
  timetableEntriesStream,
  name: r'timetableEntriesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timetableEntriesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TimetableEntriesStreamRef
    = AutoDisposeStreamProviderRef<List<TimetableEntry>>;
String _$manualTimetableNotifierHash() =>
    r'91904b2799eefae696b8e8ec813aa86d9bf4b6c9';

/// See also [ManualTimetableNotifier].
@ProviderFor(ManualTimetableNotifier)
final manualTimetableNotifierProvider = AutoDisposeNotifierProvider<
    ManualTimetableNotifier, ManualEntryState>.internal(
  ManualTimetableNotifier.new,
  name: r'manualTimetableNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manualTimetableNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ManualTimetableNotifier = AutoDisposeNotifier<ManualEntryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
