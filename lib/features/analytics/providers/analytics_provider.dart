import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/attendance_log_model.dart';
import '../../../data/models/subject_model.dart';
import '../../attendance/providers/attendance_history_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

part 'analytics_provider.g.dart';

// ── Period enum ───────────────────────────────────────────────────────────────

enum AnalyticsPeriod { week, month, semester }

// ── Summary data model ────────────────────────────────────────────────────────

class AnalyticsSummary {
  final double overallPercentage;
  final int totalSubjects;
  final int totalAttended;
  final int totalMissed;
  final int totalClasses;
  final double attendanceGoal;

  const AnalyticsSummary({
    required this.overallPercentage,
    required this.totalSubjects,
    required this.totalAttended,
    required this.totalMissed,
    required this.totalClasses,
    required this.attendanceGoal,
  });

  const AnalyticsSummary.empty()
      : overallPercentage = 0,
        totalSubjects = 0,
        totalAttended = 0,
        totalMissed = 0,
        totalClasses = 0,
        attendanceGoal = 75;
}

// ── Insight model ─────────────────────────────────────────────────────────────

class AnalyticsInsight {
  final String title;
  final String subtitle;
  final InsightType type;

  const AnalyticsInsight({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

enum InsightType { positive, warning, neutral, critical }

// ── Analytics data bundle ──────────────────────────────────────────────────────

class AnalyticsData {
  final AnalyticsSummary summary;
  final List<AnalyticsInsight> insights;
  final Map<DateTime, int> heatmapData; // date → log count
  final List<SubjectModel> subjects;

  const AnalyticsData({
    required this.summary,
    required this.insights,
    required this.heatmapData,
    required this.subjects,
  });
}

// ── Period state notifier ─────────────────────────────────────────────────────

@riverpod
class AnalyticsPeriodNotifier extends _$AnalyticsPeriodNotifier {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.week;

  void set(AnalyticsPeriod period) => state = period;
}

// ── TASK 7: DUPLICATE STREAM REMOVED ─────────────────────────────────────────
//
// The former `analyticsLogsStream` provider has been deleted.
// It called `ref.watch(attendanceRepositoryProvider).watchAllLogs()` — which
// created a SECOND independent Firestore listener on the same attendance_logs
// collection, running in parallel with `attendanceLogsStreamProvider`.
//
// All analytics providers now watch `attendanceLogsStreamProvider` from
// attendance_history_provider.dart — a single, Riverpod-cached listener that
// all consumers share. This halves the number of Firestore reads and ensures
// analytics and history always see identical data.

// ── Trend data (FlSpot list) ──────────────────────────────────────────────────

@riverpod
List<FlSpot> trendData(Ref ref) {
  final period = ref.watch(analyticsPeriodNotifierProvider);
  // TASK 7: Use the single canonical logs stream (not a new separate listener).
  final logsAsync = ref.watch(attendanceLogsStreamProvider);
  final logs = logsAsync.valueOrNull ?? [];

  return _buildTrendSpots(logs, period);
}

List<FlSpot> _buildTrendSpots(
    List<AttendanceLogModel> logs, AnalyticsPeriod period) {
  final now = DateTime.now();

  switch (period) {
    case AnalyticsPeriod.week:
      // 7 days: x = 0 (Mon) to 6 (Sun of current week)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final spots = <FlSpot>[];
      for (int i = 0; i < 7; i++) {
        final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
        final dayLogs = logs.where((l) => _isSameDay(l.date, day)).toList();
        final total = dayLogs.length;
        final present =
            dayLogs.where((l) => l.status == AttendanceStatus.present || l.status == AttendanceStatus.late).length;
        final pct = total == 0 ? 0.0 : (present / total) * 100;
        spots.add(FlSpot(i.toDouble(), pct));
      }
      return spots;

    case AnalyticsPeriod.month:
      // 4 weeks: x = 0..3, y = average % per week
      final monthStart = DateTime(now.year, now.month, 1);
      final spots = <FlSpot>[];
      for (int w = 0; w < 4; w++) {
        final weekS = monthStart.add(Duration(days: w * 7));
        final weekE = weekS.add(const Duration(days: 7));
        final weekLogs = logs
            .where((l) => l.date.isAfter(weekS) && l.date.isBefore(weekE))
            .toList();
        final total = weekLogs.length;
        final present = weekLogs
            .where((l) =>
                l.status == AttendanceStatus.present ||
                l.status == AttendanceStatus.late)
            .length;
        final pct = total == 0 ? 0.0 : (present / total) * 100;
        spots.add(FlSpot(w.toDouble(), pct));
      }
      return spots;

    case AnalyticsPeriod.semester:
      // Last 6 months: x = 0..5
      final spots = <FlSpot>[];
      for (int m = 5; m >= 0; m--) {
        final month = DateTime(now.year, now.month - m, 1);
        final nextMonth = DateTime(now.year, now.month - m + 1, 1);
        final monthLogs = logs
            .where(
                (l) => l.date.isAfter(month) && l.date.isBefore(nextMonth))
            .toList();
        final total = monthLogs.length;
        final present = monthLogs
            .where((l) =>
                l.status == AttendanceStatus.present ||
                l.status == AttendanceStatus.late)
            .length;
        final pct = total == 0 ? 0.0 : (present / total) * 100;
        spots.add(FlSpot((5 - m).toDouble(), pct));
      }
      return spots;
  }
}

// ── Heatmap data ──────────────────────────────────────────────────────────────

@riverpod
Map<String, int> heatmapData(Ref ref) {
  final logsAsync = ref.watch(attendanceLogsStreamProvider); // TASK 7
  final logs = logsAsync.valueOrNull ?? [];

  final map = <String, int>{};
  for (final log in logs) {
    final key =
        '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';
    map[key] = (map[key] ?? 0) + 1;
  }
  return map;
}

// ── Analytics summary ─────────────────────────────────────────────────────────

@riverpod
AnalyticsSummary analyticsSummary(Ref ref) {
  final dashAsync = ref.watch(dashboardNotifierProvider);
  final logsAsync = ref.watch(attendanceLogsStreamProvider); // TASK 7

  final data = dashAsync.valueOrNull;
  final logs = logsAsync.valueOrNull ?? [];
  if (data == null) return const AnalyticsSummary.empty();

  final present = logs
      .where((l) =>
          l.status == AttendanceStatus.present ||
          l.status == AttendanceStatus.late)
      .length;
  final missed =
      logs.where((l) => l.status == AttendanceStatus.absent).length;

  return AnalyticsSummary(
    overallPercentage: data.overallPercentage,
    totalSubjects: data.subjects.length,
    totalAttended: present,
    totalMissed: missed,
    totalClasses: logs.length,
    attendanceGoal: data.attendanceGoal,
  );
}

// ── Insights engine ───────────────────────────────────────────────────────────

@riverpod
List<AnalyticsInsight> analyticsInsights(Ref ref) {
  final dashAsync = ref.watch(dashboardNotifierProvider);
  final logsAsync = ref.watch(attendanceLogsStreamProvider); // TASK 7

  final subjects = dashAsync.valueOrNull?.subjects ?? [];
  final goal = dashAsync.valueOrNull?.attendanceGoal ?? 75;
  final logs = logsAsync.valueOrNull ?? [];

  if (subjects.isEmpty) return [];
  return _generateInsights(subjects, logs, goal);
}

List<AnalyticsInsight> _generateInsights(
  List<SubjectModel> subjects,
  List<AttendanceLogModel> logs,
  double goal,
) {
  final insights = <AnalyticsInsight>[];

  if (subjects.isEmpty) return insights;

  // Best attended
  final sorted = [...subjects]
    ..sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
  final best = sorted.first;
  if (best.totalClasses > 0) {
    insights.add(AnalyticsInsight(
      title: 'Best Attended: ${best.name}',
      subtitle:
          '${best.attendancePercentage.toStringAsFixed(0)}% — Keep it up! 🎯',
      type: InsightType.positive,
    ));
  }

  // Worst attended
  final worst = sorted.last;
  if (worst.totalClasses > 0 &&
      worst.attendancePercentage < goal &&
      subjects.length > 1) {
    insights.add(AnalyticsInsight(
      title: 'Needs Attention: ${worst.name}',
      subtitle:
          '${worst.attendancePercentage.toStringAsFixed(0)}% — ${_classesNeeded(worst, goal)} more classes needed to reach $goal%',
      type: worst.attendancePercentage < goal - 10
          ? InsightType.critical
          : InsightType.warning,
    ));
  }

  // Risk subjects
  final risky = subjects
      .where((s) => s.totalClasses > 0 && s.attendancePercentage < goal)
      .toList();
  if (risky.isNotEmpty) {
    insights.add(AnalyticsInsight(
      title: '${risky.length} Subject${risky.length > 1 ? 's' : ''} Below Target',
      subtitle: risky.map((s) => s.name).join(', '),
      type: InsightType.critical,
    ));
  }

  // Attendance streak (consecutive days with at least one present log)
  final streak = _computeStreak(logs);
  if (streak > 1) {
    insights.add(AnalyticsInsight(
      title: '$streak-Day Attendance Streak 🔥',
      subtitle: 'You\'ve been consistently attending. Keep going!',
      type: InsightType.positive,
    ));
  }

  // Most missed subject (most absent logs)
  final subjectAbsences = <String, int>{};
  for (final l in logs) {
    if (l.status == AttendanceStatus.absent) {
      subjectAbsences[l.subjectId] =
          (subjectAbsences[l.subjectId] ?? 0) + 1;
    }
  }
  if (subjectAbsences.isNotEmpty) {
    final mostMissedId =
        subjectAbsences.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final mostMissedSubject = subjects.where((s) => s.id == mostMissedId).firstOrNull;
    if (mostMissedSubject != null) {
      insights.add(AnalyticsInsight(
        title: 'Most Missed: ${mostMissedSubject.name}',
        subtitle:
            '${subjectAbsences[mostMissedId]} absences recorded this semester',
        type: InsightType.warning,
      ));
    }
  }

  return insights;
}

int _computeStreak(List<AttendanceLogModel> logs) {
  if (logs.isEmpty) return 0;
  final now = DateTime.now();
  int streak = 0;
  var checkDate = DateTime(now.year, now.month, now.day);

  while (true) {
    final hasPresent = logs.any((l) =>
        _isSameDay(l.date, checkDate) &&
        (l.status == AttendanceStatus.present ||
            l.status == AttendanceStatus.late));
    if (!hasPresent) break;
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }
  return streak;
}

int _classesNeeded(SubjectModel s, double goal) {
  final target = goal / 100;
  if (s.totalClasses == 0) return 0;
  final needed =
      (target * s.totalClasses - s.attendedClasses) / (1 - target);
  return needed.ceil().clamp(0, 999);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
