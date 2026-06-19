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

    // Build a map: subjectName.trim() → remaining class count (future classes only)
    final remainingMap = _buildRemainingMap(entries, semester, today);

    final predictions = subjects.map((subject) {
      final attended = subject.attendedClasses;
      final total = subject.totalClasses;
      // Normalise subject name to match timetable entry keys
      final remaining = remainingMap[subject.name.trim()] ?? 0;

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

    // Key by trimmed name to handle whitespace mismatches between
    // SubjectModel.name and TimetableEntry.subject
    final predMap = {for (final p in predictions) p.subject.name.trim(): p};

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
      // Guard: goal=100% → goalPct=1, denominator=0 → cap at 999
      final recoveryNeeded = goalPct >= 1
          ? 999
          : () {
              final rawRecovery =
                  (goalPct * (total + missedCount) - attended) / (1 - goalPct);
              return rawRecovery > 0 ? rawRecovery.ceil().clamp(0, 999) : 0;
            }();

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
      // Use trimmed name — _countMissedInRange keys are also trimmed
      if (!missed.containsKey(pred.subject.name.trim())) {
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
    // Guard: goal=0% → required=0, division by zero → return 0 (undefined bunk count)
    if (required <= 0) return 0;
    final bunks = (attended / required) - total;
    return bunks > 0 ? bunks.floor() : 0;
  }

  /// Recovery: ceil((required * total - attended) / (1 - required))
  static int _classesNeeded(int attended, int total, double goal) {
    final required = goal / 100;
    final current = total > 0 ? attended / total : 0.0;
    if (current >= required) return 0;
    // Guard: goal=100% → required=1, denominator=0 → impossible to recover, cap at 999
    if (required >= 1) return 999;
    final needed = (required * total - attended) / (1 - required);
    return needed.ceil().clamp(0, 999);
  }

  /// Semester projection assuming student attends all remaining classes.
  static double _projectedPct(int attended, int total, int remaining) =>
      _pct(attended + remaining, total + remaining);

  /// Risk level derivation.
  ///
  /// Critical  → student is BELOW the attendance goal.
  /// Warning   → student is at or above goal, but has ≤ 2 safe bunks (very thin buffer).
  /// Safe      → student is above goal with > 2 safe bunks.
  static RiskLevel _riskLevel(double currentPct, int safeBunks, double goal) {
    if (currentPct < goal) return RiskLevel.critical;    // actually below goal
    if (safeBunks <= 2) return RiskLevel.warning;        // above goal but thin buffer
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
        // Normalise subject name so trailing/leading spaces don't break matching
        final subjectKey = entry.subject.trim();
        counts[subjectKey] = (counts[subjectKey] ?? 0) + dates.length;
      }
    }
    return counts;
  }

  // ─── Feature V2: Safe-Until Date ──────────────────────────────────────────

  /// Returns the date of the last lecture a student can safely skip for
  /// [prediction] and still remain at or above [goal]%.
  ///
  /// Algorithm:
  ///   Walk future occurrences of the subject (from tomorrow onward).
  ///   The student has [safeBunks] skips available.
  ///   The last available skip date is the [safeBunks]-th future occurrence.
  ///
  /// Returns null when [safeBunks] == 0.
  static DateTime? safeUntilDate({
    required SubjectPrediction prediction,
    required List<TimetableEntry> entries,
    required Semester semester,
  }) {
    if (prediction.safeBunks <= 0) return null;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Collect future dates for this subject in order
    final futureDates = _futureOccurrencesForSubject(
      subjectName: prediction.name,
      entries: entries,
      semester: semester,
      from: tomorrow,
    );

    if (futureDates.isEmpty) return null;

    // The [safeBunks]-th date (1-indexed) is the last safe skip
    final idx = prediction.safeBunks - 1;
    if (idx >= futureDates.length) {
      // Can skip ALL remaining — last available occurrence
      return futureDates.last;
    }
    return futureDates[idx];
  }

  // ─── Feature V2: Tomorrow Opportunities ─────────────────────────────────────

  /// Returns the attendance opportunity classification for every lecture
  /// scheduled tomorrow.
  ///
  /// A lecture is [TomorrowSafety.safeToSkip] when the matching subject
  /// has more than 1 safe bunk remaining (keeping a buffer of ≥ 1 after).
  /// Otherwise it is [TomorrowSafety.attendRecommended].
  ///
  /// Returns an empty list when no classes are scheduled tomorrow.
  static List<TomorrowOpportunity> tomorrowOpportunities({
    required List<SubjectPrediction> predictions,
    required List<TimetableEntry> entries,
    required Semester semester,
  }) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Map weekday number → day name (matching timetable entry format)
    final tomorrowDayName = _days[tomorrow.weekday - 1];

    // Check tomorrow is within the semester range
    if (tomorrow.isBefore(semester.startDate) ||
        tomorrow.isAfter(semester.endDate)) {
      return [];
    }
    // Skip if tomorrow is a holiday
    if (semester.isHoliday(tomorrow)) return [];

    // Get entries for tomorrow's weekday
    final tomorrowEntries =
        entries.where((e) => e.day == tomorrowDayName).toList();
    if (tomorrowEntries.isEmpty) return [];

    // Build lookup: trimmed subject name → prediction
    final predMap = {
      for (final p in predictions) p.subject.name.trim(): p,
    };

    final result = <TomorrowOpportunity>[];
    for (final entry in tomorrowEntries) {
      final pred = predMap[entry.subject.trim()];
      // Safe to skip only when bunks > 1 (keeps at least 1 buffer)
      final safety = (pred != null && pred.safeBunks > 1)
          ? TomorrowSafety.safeToSkip
          : TomorrowSafety.attendRecommended;
      result.add(TomorrowOpportunity(
        subjectName: entry.subject,
        startTime: entry.startTime,
        endTime: entry.endTime,
        safety: safety,
        safeBunksRemaining: pred?.safeBunks ?? 0,
      ));
    }

    // Sort: safe-to-skip first, then by start time
    result.sort((a, b) {
      final cmp = a.safety.index.compareTo(b.safety.index);
      if (cmp != 0) return cmp;
      return a.startTime.compareTo(b.startTime);
    });

    return result;
  }

  // ─── Feature V2: Recovery Date ───────────────────────────────────────────────

  /// Calculates the earliest date at which a student recovers above [goal]%
  /// for a subject that dropped below goal during a leave period.
  ///
  /// Starting state: [impact.pctAfter] → attended = [attended] out of [total + missed]
  /// Recovery: add 1 attended + 1 total per future occurrence of the subject
  /// until attendance >= goal.
  ///
  /// Returns null if recovery is not possible within the semester.
  static DateTime? recoveryDate({
    required SubjectLeaveImpact impact,
    required SubjectPrediction prediction,
    required List<TimetableEntry> entries,
    required Semester semester,
    required DateTime leaveEnd,
    required double goal,
  }) {
    if (impact.pctAfter >= goal) return null; // Already above goal — no recovery needed

    final startFrom = DateTime(
      leaveEnd.year,
      leaveEnd.month,
      leaveEnd.day + 1,
    );

    final futureDates = _futureOccurrencesForSubject(
      subjectName: prediction.name,
      entries: entries,
      semester: semester,
      from: startFrom,
    );

    if (futureDates.isEmpty) return null;

    // Current state after leave
    int attended = prediction.attended;
    int total = prediction.total + impact.missedCount;
    final required = goal / 100;

    for (final date in futureDates) {
      attended += 1;
      total += 1;
      final pct = total == 0 ? 0.0 : attended / total;
      if (pct >= required) return date;
    }

    return null; // Not recoverable within semester
  }

  // ─── Private: future occurrence list ─────────────────────────────────────────

  /// Returns a sorted list of future dates on which [subjectName] is scheduled,
  /// from [from] (inclusive) to [semester.endDate] (inclusive).
  static List<DateTime> _futureOccurrencesForSubject({
    required String subjectName,
    required List<TimetableEntry> entries,
    required Semester semester,
    required DateTime from,
  }) {
    final trimmedName = subjectName.trim();
    final subjectEntries =
        entries.where((e) => e.subject.trim() == trimmedName).toList();
    if (subjectEntries.isEmpty) return [];

    // Use a List (not Set) so that a subject with 2 entries on the same day
    // correctly contributes 2 occurrences per date.
    final allDates = <DateTime>[];
    for (int i = 0; i < _days.length; i++) {
      final day = _days[i];
      final weekday = i + 1;
      final entriesOnDay = subjectEntries.where((e) => e.day == day).toList();
      if (entriesOnDay.isEmpty) continue;

      final dates = semester
          .getDatesForWeekday(weekday)
          .where((d) => !d.isBefore(from))
          .toList();

      for (final date in dates) {
        // One occurrence per timetable entry on that day
        for (int j = 0; j < entriesOnDay.length; j++) {
          allDates.add(date);
        }
      }
    }

    allDates.sort();
    return allDates;
  }

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
        // Trim to match the predMap keys (which are also trimmed)
        final subjectKey = entry.subject.trim();
        counts[subjectKey] = (counts[subjectKey] ?? 0) + dates.length;
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

// ─────────────────────────────────────────────────────────────────────────────
// Predictor V2 Models
// ─────────────────────────────────────────────────────────────────────────────

/// Whether a tomorrow lecture is safe to skip or should be attended.
enum TomorrowSafety {
  /// Student has sufficient bunk buffer — skipping is safe.
  safeToSkip,

  /// Student is at or near the limit — attendance strongly advised.
  attendRecommended;

  String get label => switch (this) {
        TomorrowSafety.safeToSkip => 'Safe to Skip',
        TomorrowSafety.attendRecommended => 'Attend Recommended',
      };
}

/// A single lecture entry for tomorrow's opportunity list.
class TomorrowOpportunity {
  final String subjectName;
  final String startTime;
  final String endTime;
  final TomorrowSafety safety;

  /// How many safe bunks the student still has for this subject.
  final int safeBunksRemaining;

  const TomorrowOpportunity({
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.safety,
    required this.safeBunksRemaining,
  });

  bool get isSafe => safety == TomorrowSafety.safeToSkip;
}
