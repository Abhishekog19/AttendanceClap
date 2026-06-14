import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/attendance_log_model.dart' as log_model;
import '../../../data/models/class_session_model.dart' as session_model;
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/timetable_repository.dart';

part 'timetable_provider.g.dart';

// ── Stream today's sessions as TimetableModel ─────────────────────────────────

@riverpod
Stream<List<TimetableModel>> timetableStream(Ref ref) {
  return ref
      .watch(timetableRepositoryProvider)
      .todaySessionsStream()
      .map((sessions) => sessions
          .map((s) => TimetableModel(
                id: s.id,
                subjectId: s.subjectId,
                subjectName: s.subjectName,
                day: s.date.weekday - 1, // DateTime.monday=1 → 0-indexed
                startTime: s.startTime,
                endTime: s.endTime,
                faculty: s.faculty,
                room: s.room,
              ))
          .toList());
}

@riverpod
List<TimetableModel> todayClasses(Ref ref) {
  final allAsync = ref.watch(timetableStreamProvider);
  final all = allAsync.valueOrNull ?? [];
  return all..sort((a, b) => a.startTime.compareTo(b.startTime));
}

@riverpod
TimetableModel? currentClass(Ref ref) {
  final today = ref.watch(todayClassesProvider);
  final now = TimeOfDay.now();
  for (final c in today) {
    final start = _parseTime(c.startTime);
    final end = _parseTime(c.endTime);
    if (_isAfterOrEqual(now, start) && _isBefore(now, end)) return c;
  }
  return null;
}

@riverpod
TimetableModel? nextClass(Ref ref) {
  final today = ref.watch(todayClassesProvider);
  final now = TimeOfDay.now();
  for (final c in today) {
    final start = _parseTime(c.startTime);
    if (_isAfter(now, start)) continue;
    return c;
  }
  return null;
}

TimeOfDay _parseTime(String t) {
  final parts = t.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

bool _isAfterOrEqual(TimeOfDay a, TimeOfDay b) =>
    a.hour > b.hour || (a.hour == b.hour && a.minute >= b.minute);
bool _isBefore(TimeOfDay a, TimeOfDay b) =>
    a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);
bool _isAfter(TimeOfDay a, TimeOfDay b) =>
    a.hour > b.hour || (a.hour == b.hour && a.minute > b.minute);

// ── Notifier for marking attendance ──────────────────────────────────────────

@riverpod
class TimetableNotifier extends _$TimetableNotifier {
  @override
  bool build() => false;

  /// Bridge: takes old-style (subjectId + log AttendanceStatus),
  /// looks up today's matching session, marks it with session AttendanceStatus.
  Future<void> markAttendance({
    required String subjectId,
    required log_model.AttendanceStatus status,
  }) async {
    final sessions = await ref
        .read(timetableRepositoryProvider)
        .todaySessionsStream()
        .first;

    final match =
        sessions.where((s) => s.subjectId == subjectId).firstOrNull;

    if (match != null) {
      final sessionStatus = status == log_model.AttendanceStatus.present
          ? session_model.AttendanceStatus.present
          : session_model.AttendanceStatus.absent;

      await ref
          .read(timetableRepositoryProvider)
          .markAttendance(match.id, sessionStatus);
    }
  }
}
