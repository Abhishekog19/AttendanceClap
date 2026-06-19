import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/timetable_entry_model.dart';
import '../../../data/models/semester_model.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/leave_plan_result.dart';
import '../services/predictor_service.dart';

part 'predictor_provider.g.dart';

// ─── Timetable entries stream (reuses TimetableRepository stream) ─────────────

@riverpod
Stream<List<TimetableEntry>> predictorEntriesStream(Ref ref) {
  return ref.watch(timetableRepositoryProvider).watchTimetableEntries();
}

// ─── Active semester (one-time fetch) ─────────────────────────────────────────

@riverpod
Future<Semester?> predictorSemester(Ref ref) {
  return ref.watch(timetableRepositoryProvider).getActiveSemester();
}

// ─── Main predictor data (memoised — recomputes only when deps change) ────────

@riverpod
Future<PredictorData?> predictorData(Ref ref) async {
  // Watch goal FIRST (synchronous) so it is registered as a dependency
  // before any await. If goal changes (user updates settings), the provider
  // automatically recomputes with the new value.
  final goal = ref.watch(attendanceGoalProvider);

  final subjects = await ref.watch(subjectsStreamProvider.future);
  final semester = await ref.watch(predictorSemesterProvider.future);
  final entries = await ref.watch(predictorEntriesStreamProvider.future);

  if (semester == null || subjects.isEmpty || entries.isEmpty) return null;

  final predictions = PredictorService.computePredictions(
    subjects: subjects,
    entries: entries,
    semester: semester,
    goal: goal,
  );

  return PredictorData(
    predictions: predictions,
    entries: entries,
    semester: semester,
    overallCurrentPct: PredictorService.overallCurrentPct(predictions),
    overallProjectedPct: PredictorService.overallProjectedPct(predictions),
    totalSafeBunks: PredictorService.totalSafeBunks(predictions),
    criticalCount: PredictorService.criticalCount(predictions),
    goal: goal,
  );
}

// ─── What-If Simulator state ──────────────────────────────────────────────────

// Sentinel — distinguishes "parameter not provided" from "explicitly null".
const _absent = Object();

class WhatIfState {
  final String? subjectId;
  final int missedClasses;

  const WhatIfState({this.subjectId, this.missedClasses = 0});

  /// Pass [subjectId] explicitly (even as null) to override it.
  /// Omit [subjectId] entirely to keep the current value.
  WhatIfState copyWith({
    Object? subjectId = _absent,
    int? missedClasses,
  }) =>
      WhatIfState(
        subjectId: identical(subjectId, _absent)
            ? this.subjectId
            : subjectId as String?,
        missedClasses: missedClasses ?? this.missedClasses,
      );
}

@riverpod
class WhatIfNotifier extends _$WhatIfNotifier {
  @override
  WhatIfState build() => const WhatIfState();

  void selectSubject(String? subjectId) =>
      state = state.copyWith(subjectId: subjectId, missedClasses: 0);

  void setMissed(int missed) =>
      state = state.copyWith(missedClasses: missed.clamp(0, 15));
}

// ─── Leave Planner state ──────────────────────────────────────────────────────

@riverpod
class LeavePlannerNotifier extends _$LeavePlannerNotifier {
  @override
  DateTimeRange? build() => null;

  void setRange(DateTimeRange? range) => state = range;
  void clear() => state = null;
}

// ─── Leave plan result (derived — recomputes when range or data changes) ──────

@riverpod
LeavePlanResult? leavePlanResult(Ref ref) {
  final range = ref.watch(leavePlannerNotifierProvider);
  final dataAsync = ref.watch(predictorDataProvider);
  if (range == null) return null;

  final data = dataAsync.valueOrNull;
  if (data == null) return null;
  return PredictorService.simulateLeave(
    predictions: data.predictions,
    entries: data.entries,
    semester: data.semester,
    range: range,
  );
}

// ─── What-if result (derived) ─────────────────────────────────────────────────

@riverpod
double? whatIfResult(Ref ref) {
  final state = ref.watch(whatIfNotifierProvider);
  final dataAsync = ref.watch(predictorDataProvider);
  if (state.subjectId == null) return null;

  final data = dataAsync.valueOrNull;
  if (data == null) return null;
  final pred = data.predictions
      .where((p) => p.subject.id == state.subjectId)
      .firstOrNull;
  if (pred == null) return null;
  return PredictorService.simulateMiss(
    prediction: pred,
    missedClasses: state.missedClasses,
  );
}

// ─── Legacy compat: Keep old provider name so existing route/nav still works ──
// (The old PredictorState/PredictorNotifier is no longer needed — removed.)

// ─── Subject filter (empty set = show all subjects) ──────────────────────────
//
// Plain StateProvider — no code-gen needed.
// Holds the Set of subject IDs the user has selected.
// Empty → all subjects visible (default).
final subjectFilterProvider = StateProvider<Set<String>>((ref) => const {});

// =============================================================================
// Predictor V2 Providers
// =============================================================================

// ─── Bunk Bank data (V2 hero card) ───────────────────────────────────────────
//
// Pure derivation — zero Firebase reads.
// Rebuilds automatically whenever predictorDataProvider emits a new value
// (i.e. when attendance is marked, subjects change, goal changes, etc.)

/// Single entry in the Bunk Bank list.
class BunkBankEntry {
  final String subjectId;
  final String subjectName;
  final int safeBunks;

  /// The date of the last lecture that can safely be skipped.
  /// Null when no future classes are scheduled.
  final DateTime? safeUntil;

  const BunkBankEntry({
    required this.subjectId,
    required this.subjectName,
    required this.safeBunks,
    this.safeUntil,
  });
}

@riverpod
List<BunkBankEntry> bunkBank(Ref ref) {
  final dataAsync = ref.watch(predictorDataProvider);
  final data = dataAsync.valueOrNull;
  if (data == null) return [];

  final entries = <BunkBankEntry>[];

  for (final pred in data.predictions) {
    if (pred.safeBunks <= 0) continue; // Only subjects with remaining bunks

    final until = PredictorService.safeUntilDate(
      prediction: pred,
      entries: data.entries,
      semester: data.semester,
    );

    entries.add(BunkBankEntry(
      subjectId: pred.subject.id,
      subjectName: pred.name,
      safeBunks: pred.safeBunks,
      safeUntil: until,
    ));
  }

  // Sort ascending by safeBunks so riskiest subjects appear first
  entries.sort((a, b) => a.safeBunks.compareTo(b.safeBunks));
  return entries;
}

// ─── Tomorrow Opportunities (V2 compact card) ─────────────────────────────────
//
// Pure derivation — zero Firebase reads.
// Uses the same timetable source as the Schedule page.

@riverpod
List<TomorrowOpportunity> tomorrowOpportunities(Ref ref) {
  final dataAsync = ref.watch(predictorDataProvider);
  final data = dataAsync.valueOrNull;
  if (data == null) return [];

  return PredictorService.tomorrowOpportunities(
    predictions: data.predictions,
    entries: data.entries,
    semester: data.semester,
  );
}

