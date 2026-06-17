// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trendDataHash() => r'3df1ef4992fb8ad1734a6f7de85fb46b3115a657';

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
String _$heatmapDataHash() => r'b81476b10bb4f91faf4a3b4c037ec731a4e52eee';

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
String _$analyticsSummaryHash() => r'7d42a33bb0da4315d50975310ff83607a554d45a';

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
String _$analyticsInsightsHash() => r'509d432205c5fa2ed689d7e253cb81dc94f98b2c';

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
