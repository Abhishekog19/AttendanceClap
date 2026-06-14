import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/attendance_calculator.dart';
import '../../../data/models/attendance_log_model.dart' as log_model;
import '../../../data/models/class_session_model.dart' hide AttendanceStatus;
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../profile/providers/profile_provider.dart';

part 'subject_detail_provider.g.dart';

// ── Upcoming sessions for a subject ──────────────────────────────────────────

@riverpod
Stream<List<ClassSession>> upcomingSessions(
    Ref ref, String subjectId) {
  // Watch all sessions and filter client-side (avoids composite index requirement)
  return ref
      .watch(timetableRepositoryProvider)
      .upcomingSessionsForSubject(subjectId);
}

// ── Logs stream for a single subject ─────────────────────────────────────────

@riverpod
Stream<List<log_model.AttendanceLogModel>> subjectLogsStream(
    Ref ref, String subjectId) {
  return ref
      .watch(attendanceRepositoryProvider)
      .watchLogsForSubject(subjectId);
}

// ── Subject detail data bundle ─────────────────────────────────────────────────

class SubjectDetailData {
  final SubjectModel subject;
  final List<log_model.AttendanceLogModel> logs;
  final List<ClassSession> upcomingSessions;
  final double goal;

  const SubjectDetailData({
    required this.subject,
    required this.logs,
    required this.upcomingSessions,
    required this.goal,
  });

  // ── Computed metrics ──────────────────────────────────────────────────────

  double get percentage => subject.attendancePercentage;

  int get safeBunks => AttendanceCalculator.getSafeBunks(
        attended: subject.attendedClasses,
        total: subject.totalClasses,
        targetPercent: goal,
      );

  int get classesNeeded => AttendanceCalculator.getClassesNeeded(
        attended: subject.attendedClasses,
        total: subject.totalClasses,
        targetPercent: goal,
      );

  AttendanceStatus get riskLevel =>
      AttendanceCalculator.getStatus(percentage, target: goal);

  // ── Trend chart data ──────────────────────────────────────────────────────

  /// Weekly chart: last 7 days, y = % for that day.
  List<FlSpot> get weeklyTrend {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayLogs = logs
          .where((l) =>
              l.date.year == day.year &&
              l.date.month == day.month &&
              l.date.day == day.day)
          .toList();
      final total = dayLogs.length;
      final present = dayLogs
          .where((l) =>
              l.status == log_model.AttendanceStatus.present ||
              l.status == log_model.AttendanceStatus.late)
          .length;
      spots.add(
          FlSpot((6 - i).toDouble(), total == 0 ? 0 : (present / total) * 100));
    }
    return spots;
  }

  /// Monthly chart: last 4 weeks, y = % for that week.
  List<FlSpot> get monthlyTrend {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int w = 3; w >= 0; w--) {
      final weekEnd = now.subtract(Duration(days: w * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));
      final weekLogs = logs
          .where((l) =>
              l.date.isAfter(weekStart) && l.date.isBefore(weekEnd))
          .toList();
      final total = weekLogs.length;
      final present = weekLogs
          .where((l) =>
              l.status == log_model.AttendanceStatus.present ||
              l.status == log_model.AttendanceStatus.late)
          .length;
      spots.add(
          FlSpot((3 - w).toDouble(), total == 0 ? 0 : (present / total) * 100));
    }
    return spots;
  }

  // ── Log stats ──────────────────────────────────────────────────────────────

  int get presentCount =>
      logs.where((l) => l.status == log_model.AttendanceStatus.present).length;
  int get absentCount =>
      logs.where((l) => l.status == log_model.AttendanceStatus.absent).length;
  int get lateCount =>
      logs.where((l) => l.status == log_model.AttendanceStatus.late).length;
}

// ── Subject detail period ─────────────────────────────────────────────────────

@riverpod
class SubjectDetailPeriodNotifier extends _$SubjectDetailPeriodNotifier {
  @override
  bool build() => true; // true = weekly, false = monthly

  void setWeekly() => state = true;
  void setMonthly() => state = false;
}

// ── Combined subject detail provider ─────────────────────────────────────────

@riverpod
AsyncValue<SubjectDetailData> subjectDetail(Ref ref, String subjectId) {
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  final logsAsync = ref.watch(subjectLogsStreamProvider(subjectId));
  final sessionsAsync = ref.watch(upcomingSessionsProvider(subjectId));
  final goal = ref.watch(attendanceGoalProvider);

  // Wait for subjects and logs; sessions are optional (empty if not loaded)
  final subjects = subjectsAsync.valueOrNull;
  final logs = logsAsync.valueOrNull;

  if (subjectsAsync.isLoading || logsAsync.isLoading) {
    return const AsyncLoading();
  }

  if (subjectsAsync.hasError) return AsyncError(subjectsAsync.error!, subjectsAsync.stackTrace!);
  if (logsAsync.hasError) return AsyncError(logsAsync.error!, logsAsync.stackTrace!);

  final subject = subjects?.where((s) => s.id == subjectId).firstOrNull;
  if (subject == null) {
    return AsyncError(
        Exception('Subject not found'), StackTrace.current);
  }

  return AsyncData(SubjectDetailData(
    subject: subject,
    logs: logs ?? [],
    upcomingSessions: sessionsAsync.valueOrNull ?? [],
    goal: goal,
  ));
}
