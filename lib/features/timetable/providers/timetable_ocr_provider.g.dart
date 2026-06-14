// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_ocr_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$editedTimetableHash() => r'6ae7bf5b6e01e2ea1f6d6c6c5c1dfa02714ba3d6';

/// See also [EditedTimetable].
@ProviderFor(EditedTimetable)
final editedTimetableProvider = NotifierProvider<EditedTimetable,
    Map<String, List<TimetableEntry>>>.internal(
  EditedTimetable.new,
  name: r'editedTimetableProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$editedTimetableHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EditedTimetable = Notifier<Map<String, List<TimetableEntry>>>;
String _$timetableOcrHash() => r'a6f37440c784c50838b3454c8cf73ae38adfa25e';

/// See also [TimetableOcr].
@ProviderFor(TimetableOcr)
final timetableOcrProvider =
    AutoDisposeNotifierProvider<TimetableOcr, OcrState>.internal(
  TimetableOcr.new,
  name: r'timetableOcrProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$timetableOcrHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TimetableOcr = AutoDisposeNotifier<OcrState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
