// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subjectsStreamHash() => r'5aca6fe63ddeddb69ce1dfc1b904aa7e5d30ae12';

/// Streams all subjects from the local SQLite database, ordered by name.
///
/// This replaces the old Firestore-backed `subjectsStreamProvider`.
/// The provider name is kept the same so all existing consumers
/// (subjects_provider.dart, subject_detail_provider.dart) continue to work
/// without any import changes.
///
/// Copied from [subjectsStream].
@ProviderFor(subjectsStream)
final subjectsStreamProvider =
    AutoDisposeStreamProvider<List<SubjectModel>>.internal(
  subjectsStream,
  name: r'subjectsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subjectsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubjectsStreamRef = AutoDisposeStreamProviderRef<List<SubjectModel>>;
String _$dashboardNotifierHash() => r'387698047bdf4317f0647ff49b20d71978c62a60';

/// See also [DashboardNotifier].
@ProviderFor(DashboardNotifier)
final dashboardNotifierProvider = AutoDisposeNotifierProvider<DashboardNotifier,
    AsyncValue<DashboardData>>.internal(
  DashboardNotifier.new,
  name: r'dashboardNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DashboardNotifier = AutoDisposeNotifier<AsyncValue<DashboardData>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
