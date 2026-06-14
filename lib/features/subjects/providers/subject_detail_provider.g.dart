// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$upcomingSessionsHash() => r'fe22078c5e533ed61a4505286574e9a0fc2ae0ac';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [upcomingSessions].
@ProviderFor(upcomingSessions)
const upcomingSessionsProvider = UpcomingSessionsFamily();

/// See also [upcomingSessions].
class UpcomingSessionsFamily extends Family<AsyncValue<List<ClassSession>>> {
  /// See also [upcomingSessions].
  const UpcomingSessionsFamily();

  /// See also [upcomingSessions].
  UpcomingSessionsProvider call(
    String subjectId,
  ) {
    return UpcomingSessionsProvider(
      subjectId,
    );
  }

  @override
  UpcomingSessionsProvider getProviderOverride(
    covariant UpcomingSessionsProvider provider,
  ) {
    return call(
      provider.subjectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'upcomingSessionsProvider';
}

/// See also [upcomingSessions].
class UpcomingSessionsProvider
    extends AutoDisposeStreamProvider<List<ClassSession>> {
  /// See also [upcomingSessions].
  UpcomingSessionsProvider(
    String subjectId,
  ) : this._internal(
          (ref) => upcomingSessions(
            ref as UpcomingSessionsRef,
            subjectId,
          ),
          from: upcomingSessionsProvider,
          name: r'upcomingSessionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$upcomingSessionsHash,
          dependencies: UpcomingSessionsFamily._dependencies,
          allTransitiveDependencies:
              UpcomingSessionsFamily._allTransitiveDependencies,
          subjectId: subjectId,
        );

  UpcomingSessionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subjectId,
  }) : super.internal();

  final String subjectId;

  @override
  Override overrideWith(
    Stream<List<ClassSession>> Function(UpcomingSessionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingSessionsProvider._internal(
        (ref) => create(ref as UpcomingSessionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subjectId: subjectId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ClassSession>> createElement() {
    return _UpcomingSessionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingSessionsProvider && other.subjectId == subjectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subjectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpcomingSessionsRef on AutoDisposeStreamProviderRef<List<ClassSession>> {
  /// The parameter `subjectId` of this provider.
  String get subjectId;
}

class _UpcomingSessionsProviderElement
    extends AutoDisposeStreamProviderElement<List<ClassSession>>
    with UpcomingSessionsRef {
  _UpcomingSessionsProviderElement(super.provider);

  @override
  String get subjectId => (origin as UpcomingSessionsProvider).subjectId;
}

String _$subjectLogsStreamHash() => r'a0462129bedca07a73fa4beabed6caba91739ba5';

/// See also [subjectLogsStream].
@ProviderFor(subjectLogsStream)
const subjectLogsStreamProvider = SubjectLogsStreamFamily();

/// See also [subjectLogsStream].
class SubjectLogsStreamFamily
    extends Family<AsyncValue<List<AttendanceLogModel>>> {
  /// See also [subjectLogsStream].
  const SubjectLogsStreamFamily();

  /// See also [subjectLogsStream].
  SubjectLogsStreamProvider call(
    String subjectId,
  ) {
    return SubjectLogsStreamProvider(
      subjectId,
    );
  }

  @override
  SubjectLogsStreamProvider getProviderOverride(
    covariant SubjectLogsStreamProvider provider,
  ) {
    return call(
      provider.subjectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'subjectLogsStreamProvider';
}

/// See also [subjectLogsStream].
class SubjectLogsStreamProvider
    extends AutoDisposeStreamProvider<List<AttendanceLogModel>> {
  /// See also [subjectLogsStream].
  SubjectLogsStreamProvider(
    String subjectId,
  ) : this._internal(
          (ref) => subjectLogsStream(
            ref as SubjectLogsStreamRef,
            subjectId,
          ),
          from: subjectLogsStreamProvider,
          name: r'subjectLogsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subjectLogsStreamHash,
          dependencies: SubjectLogsStreamFamily._dependencies,
          allTransitiveDependencies:
              SubjectLogsStreamFamily._allTransitiveDependencies,
          subjectId: subjectId,
        );

  SubjectLogsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subjectId,
  }) : super.internal();

  final String subjectId;

  @override
  Override overrideWith(
    Stream<List<AttendanceLogModel>> Function(SubjectLogsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubjectLogsStreamProvider._internal(
        (ref) => create(ref as SubjectLogsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subjectId: subjectId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<AttendanceLogModel>> createElement() {
    return _SubjectLogsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubjectLogsStreamProvider && other.subjectId == subjectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subjectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubjectLogsStreamRef
    on AutoDisposeStreamProviderRef<List<AttendanceLogModel>> {
  /// The parameter `subjectId` of this provider.
  String get subjectId;
}

class _SubjectLogsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<AttendanceLogModel>>
    with SubjectLogsStreamRef {
  _SubjectLogsStreamProviderElement(super.provider);

  @override
  String get subjectId => (origin as SubjectLogsStreamProvider).subjectId;
}

String _$subjectDetailHash() => r'74023efeffc78208af36346bac524d7354c00212';

/// See also [subjectDetail].
@ProviderFor(subjectDetail)
const subjectDetailProvider = SubjectDetailFamily();

/// See also [subjectDetail].
class SubjectDetailFamily extends Family<AsyncValue<SubjectDetailData>> {
  /// See also [subjectDetail].
  const SubjectDetailFamily();

  /// See also [subjectDetail].
  SubjectDetailProvider call(
    String subjectId,
  ) {
    return SubjectDetailProvider(
      subjectId,
    );
  }

  @override
  SubjectDetailProvider getProviderOverride(
    covariant SubjectDetailProvider provider,
  ) {
    return call(
      provider.subjectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'subjectDetailProvider';
}

/// See also [subjectDetail].
class SubjectDetailProvider
    extends AutoDisposeProvider<AsyncValue<SubjectDetailData>> {
  /// See also [subjectDetail].
  SubjectDetailProvider(
    String subjectId,
  ) : this._internal(
          (ref) => subjectDetail(
            ref as SubjectDetailRef,
            subjectId,
          ),
          from: subjectDetailProvider,
          name: r'subjectDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subjectDetailHash,
          dependencies: SubjectDetailFamily._dependencies,
          allTransitiveDependencies:
              SubjectDetailFamily._allTransitiveDependencies,
          subjectId: subjectId,
        );

  SubjectDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subjectId,
  }) : super.internal();

  final String subjectId;

  @override
  Override overrideWith(
    AsyncValue<SubjectDetailData> Function(SubjectDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubjectDetailProvider._internal(
        (ref) => create(ref as SubjectDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subjectId: subjectId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<AsyncValue<SubjectDetailData>> createElement() {
    return _SubjectDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubjectDetailProvider && other.subjectId == subjectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subjectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubjectDetailRef
    on AutoDisposeProviderRef<AsyncValue<SubjectDetailData>> {
  /// The parameter `subjectId` of this provider.
  String get subjectId;
}

class _SubjectDetailProviderElement
    extends AutoDisposeProviderElement<AsyncValue<SubjectDetailData>>
    with SubjectDetailRef {
  _SubjectDetailProviderElement(super.provider);

  @override
  String get subjectId => (origin as SubjectDetailProvider).subjectId;
}

String _$subjectDetailPeriodNotifierHash() =>
    r'1638ed7114fd3255754ee142603ce150974e73ed';

/// See also [SubjectDetailPeriodNotifier].
@ProviderFor(SubjectDetailPeriodNotifier)
final subjectDetailPeriodNotifierProvider =
    AutoDisposeNotifierProvider<SubjectDetailPeriodNotifier, bool>.internal(
  SubjectDetailPeriodNotifier.new,
  name: r'subjectDetailPeriodNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subjectDetailPeriodNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubjectDetailPeriodNotifier = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
