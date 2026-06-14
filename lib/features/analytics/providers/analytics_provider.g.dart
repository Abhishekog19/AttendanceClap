// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$analyticsLogsStreamHash() =>
    r'31313c723737fa033592dd8e4a4047d84801a9fc';

/// See also [analyticsLogsStream].
@ProviderFor(analyticsLogsStream)
final analyticsLogsStreamProvider =
    AutoDisposeStreamProvider<List<AttendanceLogModel>>.internal(
  analyticsLogsStream,
  name: r'analyticsLogsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsLogsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnalyticsLogsStreamRef
    = AutoDisposeStreamProviderRef<List<AttendanceLogModel>>;
String _$trendDataHash() => r'97bd2117bbb1f6e189e52069932f5cba06c32a55';

/// See also [trendData].
@ProviderFor(trendData)
final trendDataProvider = AutoDisposeProvider<List<FlSpot>>.internal(
  trendData,
  name: r'trendDataProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$trendDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrendDataRef = AutoDisposeProviderRef<List<FlSpot>>;
String _$heatmapDataHash() => r'd57a6a89cde11d3eaa785ceb5323e6223ec91b88';

/// See also [heatmapData].
@ProviderFor(heatmapData)
final heatmapDataProvider = AutoDisposeProvider<Map<String, int>>.internal(
  heatmapData,
  name: r'heatmapDataProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$heatmapDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HeatmapDataRef = AutoDisposeProviderRef<Map<String, int>>;
String _$analyticsSummaryHash() => r'6fe17f75d6b6cddab850922806ee05ce94665355';

/// See also [analyticsSummary].
@ProviderFor(analyticsSummary)
final analyticsSummaryProvider = AutoDisposeProvider<AnalyticsSummary>.internal(
  analyticsSummary,
  name: r'analyticsSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnalyticsSummaryRef = AutoDisposeProviderRef<AnalyticsSummary>;
String _$analyticsInsightsHash() => r'a5e3565a546a15280c522d0e382e01ba9c3648a7';

/// See also [analyticsInsights].
@ProviderFor(analyticsInsights)
final analyticsInsightsProvider =
    AutoDisposeProvider<List<AnalyticsInsight>>.internal(
  analyticsInsights,
  name: r'analyticsInsightsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsInsightsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnalyticsInsightsRef = AutoDisposeProviderRef<List<AnalyticsInsight>>;
String _$analyticsPeriodNotifierHash() =>
    r'269606218bf349fbbdd0f833639c2f7eaa7d7bb4';

/// See also [AnalyticsPeriodNotifier].
@ProviderFor(AnalyticsPeriodNotifier)
final analyticsPeriodNotifierProvider = AutoDisposeNotifierProvider<
    AnalyticsPeriodNotifier, AnalyticsPeriod>.internal(
  AnalyticsPeriodNotifier.new,
  name: r'analyticsPeriodNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsPeriodNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnalyticsPeriodNotifier = AutoDisposeNotifier<AnalyticsPeriod>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
