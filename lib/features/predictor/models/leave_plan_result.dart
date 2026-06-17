/// Result of a leave-date-range simulation.
class LeavePlanResult {
  final List<SubjectLeaveImpact> subjectImpacts;
  final double overallBefore;
  final double overallAfter;

  const LeavePlanResult({
    required this.subjectImpacts,
    required this.overallBefore,
    required this.overallAfter,
  });

  double get overallDelta => overallAfter - overallBefore;

  bool get hasImpact => subjectImpacts.any((i) => i.missedCount > 0);

  int get totalRecoveryNeeded =>
      subjectImpacts.fold(0, (sum, i) => sum + i.recoveryNeeded);
}

/// Per-subject leave impact entry.
class SubjectLeaveImpact {
  final String subjectId;
  final String subjectName;
  final int missedCount;
  final double pctBefore;
  final double pctAfter;

  /// Classes to attend AFTER the leave to recover back to [goal]%.
  /// 0 when the subject remains above goal.
  final int recoveryNeeded;

  const SubjectLeaveImpact({
    required this.subjectId,
    required this.subjectName,
    required this.missedCount,
    required this.pctBefore,
    required this.pctAfter,
    this.recoveryNeeded = 0,
  });

  double get delta => pctAfter - pctBefore;

  /// True when the subject drops below the attendance requirement after leave.
  bool isBelow(double goal) => pctAfter < goal;
}
