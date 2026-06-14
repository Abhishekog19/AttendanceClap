import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/subject_model.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../profile/providers/profile_provider.dart';

part 'dashboard_provider.g.dart';

@riverpod
Stream<List<SubjectModel>> subjectsStream(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(firestoreDatasourceProvider).watchSubjects(uid);
}

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  AsyncValue<DashboardData> build() {
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final goal = ref.watch(attendanceGoalProvider);

    return subjectsAsync.when(
      data: (subjects) => AsyncData(_computeDashboard(subjects, goal)),
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
    );
  }

  DashboardData _computeDashboard(List<SubjectModel> subjects, double goal) {
    if (subjects.isEmpty) {
      return DashboardData(
        subjects: [],
        overallPercentage: 0,
        safeBunks: 0,
        classesNeeded: 0,
        bunkStatus: BunkStatus.mustAttend,
        attendanceGoal: goal,
      );
    }

    // Aggregate
    int totalAttended = 0;
    int totalClasses = 0;
    for (final s in subjects) {
      totalAttended += s.attendedClasses;
      totalClasses += s.totalClasses;
    }

    final overall = AttendanceCalculator.calculatePercentage(
      attended: totalAttended,
      total: totalClasses,
    );
    final bunks = AttendanceCalculator.getSafeBunks(
      attended: totalAttended,
      total: totalClasses,
      targetPercent: goal,
    );
    final needed = AttendanceCalculator.getClassesNeeded(
      attended: totalAttended,
      total: totalClasses,
      targetPercent: goal,
    );
    final bunkStatus = AttendanceCalculator.canIBunk(
      attended: totalAttended,
      total: totalClasses,
      targetPercent: goal,
    );

    return DashboardData(
      subjects: subjects,
      overallPercentage: overall,
      safeBunks: bunks,
      classesNeeded: needed,
      bunkStatus: bunkStatus,
      attendanceGoal: goal,
    );
  }
}

class DashboardData {
  final List<SubjectModel> subjects;
  final double overallPercentage;
  final int safeBunks;
  final int classesNeeded;
  final BunkStatus bunkStatus;
  final double attendanceGoal;

  const DashboardData({
    required this.subjects,
    required this.overallPercentage,
    required this.safeBunks,
    required this.classesNeeded,
    required this.bunkStatus,
    required this.attendanceGoal,
  });

  AttendanceStatus get overallStatus =>
      AttendanceCalculator.getStatus(overallPercentage, target: attendanceGoal);
}
