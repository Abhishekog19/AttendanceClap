import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/attendance_calculator.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../profile/providers/profile_provider.dart';

part 'predictor_provider.g.dart';

class PredictorState {
  final int futureAttended;
  final int futureMissed;
  final double currentAttended;
  final double currentTotal;
  final double goal;

  const PredictorState({
    this.futureAttended = 0,
    this.futureMissed = 0,
    this.currentAttended = 85,
    this.currentTotal = 100,
    this.goal = 75.0,
  });

  double get predictedPercentage => AttendanceCalculator.simulateFutureAttendance(
        currentAttended: currentAttended.round(),
        currentTotal: currentTotal.round(),
        futureAttended: futureAttended,
        futureMissed: futureMissed,
      );

  int get safeBunks => AttendanceCalculator.getSafeBunks(
        attended: currentAttended.round() + futureAttended,
        total: currentTotal.round() + futureAttended + futureMissed,
        targetPercent: goal,
      );

  String get riskLevel {
    final pct = predictedPercentage;
    if (pct >= goal + 10) return 'Low';
    if (pct >= goal) return 'Medium';
    return 'High';
  }

  PredictorStatus get status {
    final pct = predictedPercentage;
    if (pct >= goal + 5) return PredictorStatus.safe;
    if (pct >= goal) return PredictorStatus.caution;
    return PredictorStatus.danger;
  }

  PredictorState copyWith({int? futureAttended, int? futureMissed}) => PredictorState(
        futureAttended: futureAttended ?? this.futureAttended,
        futureMissed: futureMissed ?? this.futureMissed,
        currentAttended: currentAttended,
        currentTotal: currentTotal,
        goal: goal,
      );
}

enum PredictorStatus { safe, caution, danger }

@riverpod
class PredictorNotifier extends _$PredictorNotifier {
  @override
  PredictorState build() {
    final dashboard = ref.watch(dashboardNotifierProvider).valueOrNull;
    final goal = ref.watch(attendanceGoalProvider);

    // Aggregate current stats from dashboard
    double totalAttended = 0;
    double totalClasses = 0;
    if (dashboard != null) {
      for (final s in dashboard.subjects) {
        totalAttended += s.attendedClasses;
        totalClasses += s.totalClasses;
      }
    }
    if (totalClasses == 0) { totalAttended = 85; totalClasses = 100; }

    return PredictorState(
      currentAttended: totalAttended,
      currentTotal: totalClasses,
      goal: goal,
    );
  }

  void incrementAttended() => state = state.copyWith(
      futureAttended: state.futureAttended + 1);

  void decrementAttended() => state = state.copyWith(
      futureAttended: (state.futureAttended - 1).clamp(0, 999));

  void incrementMissed() => state = state.copyWith(
      futureMissed: state.futureMissed + 1);

  void decrementMissed() => state = state.copyWith(
      futureMissed: (state.futureMissed - 1).clamp(0, 999));

  void reset() => state = state.copyWith(futureAttended: 0, futureMissed: 0);
}
