import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/attendance_calculator.dart';
import '../../../data/local/database.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/local_attendance_repository.dart';
import '../../profile/providers/profile_provider.dart';

part 'dashboard_provider.g.dart';

// ── Local subjects stream ─────────────────────────────────────────────────────

/// Streams all subjects from the local SQLite database, ordered by name.
///
/// This replaces the old Firestore-backed `subjectsStreamProvider`.
/// The provider name is kept the same so all existing consumers
/// (subjects_provider.dart, subject_detail_provider.dart) continue to work
/// without any import changes.
@riverpod
Stream<List<SubjectModel>> subjectsStream(Ref ref) {
  final repo = ref.watch(localAttendanceRepositoryProvider);
  // Convert Drift Subject → SubjectModel so downstream consumers keep
  // receiving the same type they already expect.
  return repo.watchAllSubjects().map(
    (rows) => rows
        .map((s) => SubjectModel(
              id: s.id,
              name: s.name,
              attendedClasses: s.attendedClasses,
              totalClasses: s.totalClasses,
              faculty: s.faculty,
              attendanceTarget: s.attendanceTarget,
              colorHex: s.colorHex,
              shortName: s.shortName,
              createdAt: DateTime.fromMillisecondsSinceEpoch(s.createdAt),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(s.updatedAt),
            ))
        .toList(),
  );
}

// ── DashboardNotifier ────────────────────────────────────────────────────────

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

// ── DashboardData ─────────────────────────────────────────────────────────────

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
