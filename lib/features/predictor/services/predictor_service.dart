import 'package:flutter/material.dart' show DateTimeRange;

import '../../../data/models/subject_model.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../../data/models/semester_model.dart';
import '../models/subject_prediction.dart';
import '../models/risk_level.dart';
import '../models/leave_plan_result.dart';

/// Central calculation engine for the Predictor feature.
///
/// Pure Dart class — no Flutter dependencies (except [DateTimeRange] from
/// material for the leave planner, which is a data type only).
/// All methods are static. No state, no async, no Firestore calls.
class PredictorService {
  const PredictorService._();

  // ─── Core: Per-subject prediction ────────────────────────────────────────

  /// Builds predictions for every subject.
  ///
  /// [futureSessions] is a list of (subjectId → count) pairs that represent
  /// how many classes each subject has from today until [semester.endDate].
  /// These are generated locally from [entries] + [semester] (no Firestore).
  static List<SubjectPrediction> computePredictions({
    required List<SubjectModel> subjects,
    required List<TimetableEntry> entries,
    required Semester semester,
    required double goal,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build a map: subjectName → remaining class count (future classes only)
    final remainingMap = _buildRemainingMap(entries, semester, today);

    final predictions = subjects.map((subject) {
      final attended = subject.attendedClasses;
      final total = subject.totalClasses;
      final remaining = remainingMap[subject.name] ?? 0;

      final currentPct = _pct(attended, total);
      final safeBunks = _safeBunks(attended, total, goal);
      final classesNeeded = _classesNeeded(attended, total, goal);
      final projectedPct = _projectedPct(attended, total, remaining);
      final riskLevel = _riskLevel(currentPct, safeBunks, goal);

      return SubjectPrediction(
        subject: subject,
        currentPct: currentPct,
        safeBunks: safeBunks,
        riskLevel: riskLevel,
        classesNeeded: classesNeeded,
        projectedPct: projectedPct,
        remainingClasses: remaining,
        goal: goal,
      );
    }).toList();

    // Sort: critical → warning → safe, then by name within group
    predictions.sort((a, b) {
      final cmp = a.riskLevel.sortOrder.compareTo(b.riskLevel.sortOrder);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    return predictions;
  }

  // ─── Feature 2: What-If Simulator ────────────────────────────────────────

  /// Simulates what happens if a student misses [missedClasses] future classes.
  ///
  /// Formula: newPct = attended / (total + missedClasses)
  /// (attended stays constant because we're skipping future classes)
  static double simulateMiss({
    required SubjectPrediction prediction,
    required int missedClasses,
  }) {
    final newTotal = prediction.total + missedClasses;
    return _pct(prediction.attended, newTotal);
  }

  /// Full breakdown for the What-If simulator UI.
  ///
  /// Given the student bunks [missedClasses] future classes:
  /// - [predictedPct]    — new % right now (attended / (total + missed))
  /// - [totalLectures]   — total lectures on record after bunking
  /// - [attendedSoFar]   — lectures already attended (unchanged)
  /// - [remainingAfterBunk] — future lectures remaining after the bunk
  /// - [minPresentNeeded]  — minimum of those remaining you MUST attend
  ///                         to still hit [goal]% by semester end
  /// - [isAchievable]    — whether [minPresentNeeded] ≤ [remainingAfterBunk]
  static WhatIfBreakdown whatIfBreakdown({
    required SubjectPrediction prediction,
    required int missedClasses,
  }) {
    final attended = prediction.attended;
    final total = prediction.total;
    final remaining = prediction.remainingClasses;
    final goal = prediction.goal;

    // Bunk [missedClasses] future classes → total ticks up, attended stays same
    final totalAfterBunk = total + missedClasses;
    final predictedPct = _pct(attended, totalAfterBunk);

    // Future lectures still available after the bunk
    final remainingAfterBunk = (remaining - missedClasses).clamp(0, 999);

    // Semester-end total = all current + all remaining
    final semesterTotal = total + remaining;

    // Minimum classes you still need to attend out of [remainingAfterBunk]
    // so that (attended + x) / semesterTotal >= goal/100
    final required = goal / 100;
    final rawNeeded = (required * semesterTotal) - attended;
    final minPresentNeeded = rawNeeded > 0 ? rawNeeded.ceil().clamp(0, 999) : 0;

    final isAchievable = minPresentNeeded <= remainingAfterBunk;

    return WhatIfBreakdown(
      missedClasses: missedClasses,
      predictedPct: predictedPct,
      attendedSoFar: attended,
      totalLectures: totalAfterBunk,
      remainingAfterBunk: remainingAfterBunk,
      minPresentNeeded: minPresentNeeded,
      isAchievable: isAchievable,
      goal: goal,
    );
  }

  // ─── Feature 5: Leave Planner ────────────────────────────────────────────

  /// Scans locally-generated future sessions within [range] and computes
  /// per-subject attendance impact. No Firestore reads — operates on the
  /// already-fetched entries + semester data.
  static LeavePlanResult simulateLeave({
    required List<SubjectPrediction> predictions,
    required List<TimetableEntry> entries,
    required Semester semester,
    required DateTimeRange range,
  }) {
    // Count missed sessions per subject name in the date range
    final missed = _countMissedInRange(entries, semester, range);

    final predMap = {for (final p in predictions) p.subject.name: p};

    int totalAttendedBefore = 0;
    int totalClassesBefore = 0;
    int totalAttendedAfter = 0;
    int totalClassesAfter = 0;

    final impacts = <SubjectLeaveImpact>[];

    for (final entry in missed.entries) {
      final subjectName = entry.key;
      final missedCount = entry.value;
      final pred = predMap[subjectName];
      if (pred == null) continue;

      final attended = pred.attended;
      final total = pred.total;
      final goalPct = pred.goal / 100;

      final pctBefore = _pct(attended, total);
      final pctAfter = _pct(attended, total + missedCount);

      // Recovery: classes to attend AFTER leave to get back to goal%
      // Formula: ceil((goal * newTotal - attended) / (1 - goal))
      final rawRecovery = (goalPct * (total + missedCount) - attended) / (1 - goalPct);
      final recoveryNeeded = rawRecovery > 0 ? rawRecovery.ceil().clamp(0, 999) : 0;

      totalAttendedBefore += attended;
      totalClassesBefore += total;
      totalAttendedAfter += attended;
      totalClassesAfter += total + missedCount;

      impacts.add(SubjectLeaveImpact(
        subjectId: pred.subject.id,
        subjectName: subjectName,
        missedCount: missedCount,
        pctBefore: pctBefore,
        pctAfter: pctAfter,
        recoveryNeeded: recoveryNeeded,
      ));
    }

    // Add subjects not in date range with 0 delta for overall calculation
    for (final pred in predictions) {
      if (!missed.containsKey(pred.subject.name)) {
        totalAttendedBefore += pred.attended;
        totalClassesBefore += pred.total;
        totalAttendedAfter += pred.attended;
        totalClassesAfter += pred.total;
      }
    }

    // Sort impacts by severity (biggest drop first)
    impacts.sort((a, b) => a.delta.compareTo(b.delta));

    return LeavePlanResult(
      subjectImpacts: impacts,
      overallBefore: _pct(totalAttendedBefore, totalClassesBefore),
      overallAfter: _pct(totalAttendedAfter, totalClassesAfter),
    );
  }

  // ─── Overall summary helpers ──────────────────────────────────────────────

  static double overallCurrentPct(List<SubjectPrediction> predictions) {
    int totalAttended = 0;
    int totalClasses = 0;
    for (final p in predictions) {
      totalAttended += p.attended;
      totalClasses += p.total;
    }
    return _pct(totalAttended, totalClasses);
  }

  static double overallProjectedPct(List<SubjectPrediction> predictions) {
    int totalAttended = 0;
    int totalClasses = 0;
    for (final p in predictions) {
      totalAttended += p.attended + p.remainingClasses;
      totalClasses += p.total + p.remainingClasses;
    }
    return _pct(totalAttended, totalClasses);
  }

  static int totalSafeBunks(List<SubjectPrediction> predictions) =>
      predictions.fold(0, (sum, p) => sum + p.safeBunks);

  static int criticalCount(List<SubjectPrediction> predictions) =>
      predictions.where((p) => p.riskLevel == RiskLevel.critical).length;

  // ─── Private: formulas ────────────────────────────────────────────────────

  static double _pct(int attended, int total) =>
      total == 0 ? 0 : (attended / total) * 100;

  /// Safe bunks formula: floor(attended / required_decimal - total)
  static int _safeBunks(int attended, int total, double goal) {
    if (total == 0) return 0;
    final required = goal / 100;
    final bunks = (attended / required) - total;
    return bunks > 0 ? bunks.floor() : 0;
  }

  /// Recovery: ceil((required * total - attended) / (1 - required))
  static int _classesNeeded(int attended, int total, double goal) {
    final required = goal / 100;
    final current = total > 0 ? attended / total : 0.0;
    if (current >= required) return 0;
    final needed = (required * total - attended) / (1 - required);
    return needed.ceil().clamp(0, 999);
  }

  /// Semester projection assuming student attends all remaining classes.
  static double _projectedPct(int attended, int total, int remaining) =>
      _pct(attended + remaining, total + remaining);

  /// Risk level derivation.
  static RiskLevel _riskLevel(double currentPct, int safeBunks, double goal) {
    if (currentPct < goal || safeBunks == 0) return RiskLevel.critical;
    if (safeBunks <= 2) return RiskLevel.warning;
    return RiskLevel.safe;
  }

  // ─── Private: session generation ─────────────────────────────────────────

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  /// Generates a subjectName → remainingClassCount map from timetable entries
  /// and semester data, for dates strictly after [from].
  static Map<String, int> _buildRemainingMap(
    List<TimetableEntry> entries,
    Semester semester,
    DateTime from,
  ) {
    final counts = <String, int>{};
    final limitedSemester = Semester(
      id: semester.id,
      uid: semester.uid,
      startDate: from.isAfter(semester.startDate) ? from : semester.startDate,
      endDate: semester.endDate,
      holidays: semester.holidays,
      createdAt: semester.createdAt,
    );

    for (int i = 0; i < _days.length; i++) {
      final day = _days[i];
      final weekday = i + 1;
      final dayEntries = entries.where((e) => e.day == day).toList();
      if (dayEntries.isEmpty) continue;

      final dates = limitedSemester.getDatesForWeekday(weekday)
          .where((d) => d.isAfter(from))
          .toList();

      for (final entry in dayEntries) {
        counts[entry.subject] = (counts[entry.subject] ?? 0) + dates.length;
      }
    }
    return counts;
  }

  /// Counts future sessions in [range] per subject, generated from entries.
  static Map<String, int> _countMissedInRange(
    List<TimetableEntry> entries,
    Semester semester,
    DateTimeRange range,
  ) {
    final counts = <String, int>{};
    final rangeStart = DateTime(
        range.start.year, range.start.month, range.start.day);
    final rangeEnd = DateTime(
        range.end.year, range.end.month, range.end.day, 23, 59, 59);
    final now = DateTime.now();

    for (int i = 0; i < _days.length; i++) {
      final day = _days[i];
      final weekday = i + 1;
      final dayEntries = entries.where((e) => e.day == day).toList();
      if (dayEntries.isEmpty) continue;

      final dates = semester.getDatesForWeekday(weekday).where((d) {
        // Only count future dates within the selected range
        return d.isAfter(now) &&
            !d.isBefore(rangeStart) &&
            !d.isAfter(rangeEnd);
      }).toList();

      for (final entry in dayEntries) {
        counts[entry.subject] = (counts[entry.subject] ?? 0) + dates.length;
      }
    }
    return counts;
  }
}

/// Container for the full predictor computation result.
class PredictorData {
  final List<SubjectPrediction> predictions;
  final List<TimetableEntry> entries;
  final Semester semester;
  final double overallCurrentPct;
  final double overallProjectedPct;
  final int totalSafeBunks;
  final int criticalCount;
  final double goal;

  const PredictorData({
    required this.predictions,
    required this.entries,
    required this.semester,
    required this.overallCurrentPct,
    required this.overallProjectedPct,
    required this.totalSafeBunks,
    required this.criticalCount,
    required this.goal,
  });
}

/// Snapshot of a What-If simulation for a single subject.
class WhatIfBreakdown {
  /// Number of classes the student is choosing to miss.
  final int missedClasses;

  /// Predicted % immediately after bunking (before any remaining classes).
  final double predictedPct;

  /// Lectures already attended (unchanged).
  final int attendedSoFar;

  /// Total recorded lectures after counting the bunks.
  final int totalLectures;

  /// Future lectures still available to attend (remaining - bunked).
  final int remainingAfterBunk;

  /// Minimum lectures from [remainingAfterBunk] the student MUST attend
  /// to still reach [goal]% by semester end.
  final int minPresentNeeded;

  /// True when [minPresentNeeded] ≤ [remainingAfterBunk] (goal is reachable).
  final bool isAchievable;

  /// The attendance goal used for all calculations.
  final double goal;

  const WhatIfBreakdown({
    required this.missedClasses,
    required this.predictedPct,
    required this.attendedSoFar,
    required this.totalLectures,
    required this.remainingAfterBunk,
    required this.minPresentNeeded,
    required this.isAchievable,
    required this.goal,
  });

  double get diff => predictedPct - (attendedSoFar /
      (totalLectures - missedClasses == 0 ? 1 : totalLectures - missedClasses) * 100);
}
