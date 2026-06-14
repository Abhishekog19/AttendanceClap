import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/attendance_log_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';

part 'attendance_history_provider.g.dart';

// ── Filter model ──────────────────────────────────────────────────────────────

enum DateRangePreset { today, thisWeek, thisMonth, custom, all }

class AttendanceFilter {
  final String? subjectId; // null = all subjects
  final AttendanceStatus? status; // null = all statuses
  final DateRangePreset dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;

  const AttendanceFilter({
    this.subjectId,
    this.status,
    this.dateRange = DateRangePreset.all,
    this.customStart,
    this.customEnd,
  });

  AttendanceFilter copyWith({
    Object? subjectId = _sentinel,
    Object? status = _sentinel,
    DateRangePreset? dateRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) =>
      AttendanceFilter(
        subjectId: subjectId == _sentinel ? this.subjectId : subjectId as String?,
        status: status == _sentinel ? this.status : status as AttendanceStatus?,
        dateRange: dateRange ?? this.dateRange,
        customStart: customStart ?? this.customStart,
        customEnd: customEnd ?? this.customEnd,
      );

  static const _sentinel = Object();

  /// Whether any filter is active.
  bool get isActive =>
      subjectId != null ||
      status != null ||
      dateRange != DateRangePreset.all;
}

// ── Stats model ───────────────────────────────────────────────────────────────

class AttendanceStats {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int cancelled;

  const AttendanceStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.cancelled,
  });

  double get percentage =>
      total == 0 ? 0 : ((present + late) / total) * 100;

  const AttendanceStats.empty()
      : total = 0,
        present = 0,
        absent = 0,
        late = 0,
        cancelled = 0;

  factory AttendanceStats.fromLogs(List<AttendanceLogModel> logs) {
    int p = 0, a = 0, l = 0, c = 0;
    for (final log in logs) {
      switch (log.status) {
        case AttendanceStatus.present:
          p++;
        case AttendanceStatus.absent:
          a++;
        case AttendanceStatus.late:
          l++;
        case AttendanceStatus.cancelled:
          c++;
      }
    }
    return AttendanceStats(
      total: logs.length,
      present: p,
      absent: a,
      late: l,
      cancelled: c,
    );
  }
}

// ── Raw logs stream ───────────────────────────────────────────────────────────

@riverpod
Stream<List<AttendanceLogModel>> attendanceLogsStream(Ref ref) {
  return ref.watch(attendanceRepositoryProvider).watchAllLogs();
}

// ── Filter state ──────────────────────────────────────────────────────────────

@riverpod
class AttendanceFilterNotifier extends _$AttendanceFilterNotifier {
  @override
  AttendanceFilter build() => const AttendanceFilter();

  void setSubject(String? subjectId) =>
      state = state.copyWith(subjectId: subjectId);

  void setStatus(AttendanceStatus? status) =>
      state = state.copyWith(status: status);

  void setDateRange(DateRangePreset range) =>
      state = state.copyWith(dateRange: range);

  void setCustomRange(DateTime start, DateTime end) => state = state.copyWith(
        dateRange: DateRangePreset.custom,
        customStart: start,
        customEnd: end,
      );

  void clear() => state = const AttendanceFilter();
}

// ── Filtered logs ─────────────────────────────────────────────────────────────

@riverpod
List<AttendanceLogModel> filteredLogs(Ref ref) {
  final logsAsync = ref.watch(attendanceLogsStreamProvider);
  final filter = ref.watch(attendanceFilterNotifierProvider);
  final subjectsAsync = ref.watch(subjectsStreamProvider);

  final logs = logsAsync.valueOrNull ?? [];
  final subjects = subjectsAsync.valueOrNull ?? [];

  return _applyFilter(logs, filter, subjects);
}

List<AttendanceLogModel> _applyFilter(
  List<AttendanceLogModel> logs,
  AttendanceFilter filter,
  List<SubjectModel> subjects,
) {
  var result = logs;

  // Subject filter
  if (filter.subjectId != null) {
    result = result.where((l) => l.subjectId == filter.subjectId).toList();
  }

  // Status filter
  if (filter.status != null) {
    result = result.where((l) => l.status == filter.status).toList();
  }

  // Date filter
  final now = DateTime.now();
  switch (filter.dateRange) {
    case DateRangePreset.today:
      result = result.where((l) => _isToday(l.date, now)).toList();
    case DateRangePreset.thisWeek:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      result = result.where((l) => l.date.isAfter(start)).toList();
    case DateRangePreset.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      result = result.where((l) => l.date.isAfter(start)).toList();
    case DateRangePreset.custom:
      if (filter.customStart != null && filter.customEnd != null) {
        final end = filter.customEnd!.add(const Duration(days: 1));
        result = result
            .where((l) =>
                l.date.isAfter(filter.customStart!) && l.date.isBefore(end))
            .toList();
      }
    case DateRangePreset.all:
      break;
  }

  return result;
}

bool _isToday(DateTime d, DateTime now) =>
    d.year == now.year && d.month == now.month && d.day == now.day;

// ── Stats (from filtered logs) ────────────────────────────────────────────────

@riverpod
AttendanceStats filteredStats(Ref ref) {
  final logs = ref.watch(filteredLogsProvider);
  return AttendanceStats.fromLogs(logs);
}

// ── Grouped logs (by date string) ─────────────────────────────────────────────

@riverpod
Map<String, List<AttendanceLogModel>> groupedLogs(Ref ref) {
  final logs = ref.watch(filteredLogsProvider);
  final grouped = <String, List<AttendanceLogModel>>{};
  for (final log in logs) {
    final key = _dateKey(log.date);
    grouped.putIfAbsent(key, () => []).add(log);
  }
  return grouped;
}

String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── Edit / Delete notifier ────────────────────────────────────────────────────

enum LogEditStatus { idle, saving, success, error }

class LogEditState {
  final LogEditStatus status;
  final String? errorMessage;

  const LogEditState({this.status = LogEditStatus.idle, this.errorMessage});
}

@riverpod
class LogEditNotifier extends _$LogEditNotifier {
  @override
  LogEditState build() => const LogEditState();

  Future<void> updateLog(
    AttendanceLogModel log,
    AttendanceStatus oldStatus,
  ) async {
    state = const LogEditState(status: LogEditStatus.saving);
    try {
      await ref.read(attendanceRepositoryProvider).updateLog(log, oldStatus);
      state = const LogEditState(status: LogEditStatus.success);
    } catch (e) {
      state = LogEditState(
        status: LogEditStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteLog(AttendanceLogModel log) async {
    state = const LogEditState(status: LogEditStatus.saving);
    try {
      await ref.read(attendanceRepositoryProvider).deleteLog(log);
      state = const LogEditState(status: LogEditStatus.success);
    } catch (e) {
      state = LogEditState(
        status: LogEditStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const LogEditState();
}
