/// Core business logic for attendance calculations
class AttendanceCalculator {
  const AttendanceCalculator._();

  /// Calculates attendance percentage
  static double calculatePercentage({
    required int attended,
    required int total,
  }) {
    if (total == 0) return 0.0;
    return (attended / total) * 100;
  }

  /// Calculates how many classes can be safely missed while staying above [targetPercent]
  /// Returns 0 if already at or below target
  static int getSafeBunks({
    required int attended,
    required int total,
    double targetPercent = 75.0,
  }) {
    if (total == 0) return 0;
    final target = targetPercent / 100;
    final safeBunks = (attended / target) - total;
    return safeBunks > 0 ? safeBunks.floor() : 0;
  }

  /// Calculates how many more classes need to be attended to reach [targetPercent]
  /// Returns 0 if already above target
  static int getClassesNeeded({
    required int attended,
    required int total,
    double targetPercent = 75.0,
  }) {
    final target = targetPercent / 100;
    final current = total > 0 ? attended / total : 0.0;
    if (current >= target) return 0;
    // Solve: (attended + x) / (total + x) = target
    // attended + x = target * total + target * x
    // x(1 - target) = target * total - attended
    // x = (target * total - attended) / (1 - target)
    final needed = (target * total - attended) / (1 - target);
    return needed.ceil().clamp(0, 999);
  }

  /// "Can I Bunk Tomorrow?" - checks if missing next class keeps attendance >= target
  static BunkStatus canIBunk({
    required int attended,
    required int total,
    double targetPercent = 75.0,
  }) {
    if (total == 0) return BunkStatus.safe;

    // If I bunk one class: attended stays same, total increases by 1
    final afterBunk = calculatePercentage(attended: attended, total: total + 1);

    final safeBunks = getSafeBunks(
      attended: attended,
      total: total,
      targetPercent: targetPercent,
    );

    if (afterBunk >= targetPercent && safeBunks > 2) {
      return BunkStatus.safe;
    } else if (afterBunk >= targetPercent) {
      return BunkStatus.risky;
    } else {
      return BunkStatus.mustAttend;
    }
  }

  /// Simulates attendance after [futureAttended] attended and [futureMissed] missed
  static double simulateFutureAttendance({
    required int currentAttended,
    required int currentTotal,
    required int futureAttended,
    required int futureMissed,
  }) {
    final newTotal = currentTotal + futureAttended + futureMissed;
    final newAttended = currentAttended + futureAttended;
    return calculatePercentage(attended: newAttended, total: newTotal);
  }

  /// Returns color-coded attendance status label
  static AttendanceStatus getStatus(double percentage, {double target = 75}) {
    if (percentage >= target + 10) return AttendanceStatus.excellent;
    if (percentage >= target + 5) return AttendanceStatus.good;
    if (percentage >= target) return AttendanceStatus.safe;
    if (percentage >= target - 5) return AttendanceStatus.risky;
    return AttendanceStatus.critical;
  }
}

enum BunkStatus {
  safe,
  risky,
  mustAttend;

  String get label {
    switch (this) {
      case BunkStatus.safe:
        return 'Safe to Bunk';
      case BunkStatus.risky:
        return 'Risky';
      case BunkStatus.mustAttend:
        return 'Must Attend';
    }
  }

  String get emoji {
    switch (this) {
      case BunkStatus.safe:
        return '✅';
      case BunkStatus.risky:
        return '⚠️';
      case BunkStatus.mustAttend:
        return '🚨';
    }
  }
}

enum AttendanceStatus {
  excellent,
  good,
  safe,
  risky,
  critical;

  String get label {
    switch (this) {
      case AttendanceStatus.excellent:
        return 'Excellent';
      case AttendanceStatus.good:
        return 'Good';
      case AttendanceStatus.safe:
        return 'Safe';
      case AttendanceStatus.risky:
        return 'Watch';
      case AttendanceStatus.critical:
        return 'Critical';
    }
  }
}
