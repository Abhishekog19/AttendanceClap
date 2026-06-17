import '../../../data/models/subject_model.dart';
import 'risk_level.dart';

/// Computed prediction snapshot for a single subject.
/// All fields are derived from [SubjectModel] + future session data —
/// never computed inside widgets.
class SubjectPrediction {
  final SubjectModel subject;

  /// Current attendance: attended / total * 100
  final double currentPct;

  /// Safe bunks: max(0, floor(attended / required_decimal - total))
  final int safeBunks;

  /// Risk classification derived from safeBunks + currentPct vs. goal.
  final RiskLevel riskLevel;

  /// Recovery classes needed if below threshold; 0 if above.
  final int classesNeeded;

  /// Projected % if student attends ALL remaining future classes.
  final double projectedPct;

  /// Count of future (after today) scheduled classes for this subject.
  final int remainingClasses;

  /// The global attendance goal used for all calculations.
  final double goal;

  const SubjectPrediction({
    required this.subject,
    required this.currentPct,
    required this.safeBunks,
    required this.riskLevel,
    required this.classesNeeded,
    required this.projectedPct,
    required this.remainingClasses,
    required this.goal,
  });

  String get name => subject.name;
  String? get faculty => subject.faculty;
  int get attended => subject.attendedClasses;
  int get total => subject.totalClasses;
}
