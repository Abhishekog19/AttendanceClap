import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/class_session_model.dart';
import '../../../data/models/daily_schedule_override_model.dart';
import '../../../data/repositories/timetable_repository.dart';

part 'timetable_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Schedule Page Data Bundle
// ─────────────────────────────────────────────────────────────────────────────

class SchedulePageData {
  /// The class that is currently in progress (startTime ≤ now < endTime).
  final ClassSession? currentClass;

  /// Classes that haven't started yet, sorted by start time (nearest first).
  final List<ClassSession> upcoming;

  /// Classes that have ended but attendance has NOT been marked yet.
  final List<ClassSession> actionRequired;

  /// Classes that have been marked (present, absent, cancelled).
  final List<ClassSession> completedToday;

  /// Total number of classes today (non-cancelled).
  final int totalTodayCount;

  const SchedulePageData({
    this.currentClass,
    this.upcoming = const [],
    this.actionRequired = const [],
    this.completedToday = const [],
    this.totalTodayCount = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Today's raw sessions stream
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<ClassSession>> todaySessionsStream(Ref ref) {
  return ref.watch(timetableRepositoryProvider).todaySessionsStream();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Daily overrides stream for today
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<DailyScheduleOverride>> todayOverridesStream(Ref ref) {
  return ref
      .watch(timetableRepositoryProvider)
      .watchDailyOverridesForDate(DateTime.now());
}

// ─────────────────────────────────────────────────────────────────────────────
//  Merged + bucketed schedule page data
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
SchedulePageData schedulePageData(Ref ref) {
  final sessionsAsync = ref.watch(todaySessionsStreamProvider);
  final overridesAsync = ref.watch(todayOverridesStreamProvider);

  final rawSessions = sessionsAsync.valueOrNull ?? [];
  final overrides = overridesAsync.valueOrNull ?? [];

  // Apply overrides to sessions
  final sessions = _applyOverrides(rawSessions, overrides);

  // Sort by display start time
  sessions.sort((a, b) => a.displayStartTime.compareTo(b.displayStartTime));

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  ClassSession? currentClass;
  final upcoming = <ClassSession>[];
  final actionRequired = <ClassSession>[];
  final completedToday = <ClassSession>[];

  for (final session in sessions) {
    // Skip cancelled sessions from buckets (they'll be in completed)
    if (session.isCancelled) {
      completedToday.add(session);
      continue;
    }

    final startMin = _parseTimeMinutes(session.displayStartTime);
    final endMin = _parseTimeMinutes(session.displayEndTime);
    final isMarked = session.status != AttendanceStatus.notMarked;

    if (isMarked) {
      completedToday.add(session);
    } else if (nowMinutes >= startMin && nowMinutes < endMin) {
      // Currently in progress
      currentClass ??= session;
    } else if (nowMinutes < startMin) {
      // Hasn't started yet
      upcoming.add(session);
    } else {
      // Ended, not marked → action required
      actionRequired.add(session);
    }
  }

  final totalNonCancelled =
      sessions.where((s) => !s.isCancelled).length;

  return SchedulePageData(
    currentClass: currentClass,
    upcoming: upcoming,
    actionRequired: actionRequired,
    completedToday: completedToday,
    totalTodayCount: totalNonCancelled,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Apply daily overrides to sessions
// ─────────────────────────────────────────────────────────────────────────────

List<ClassSession> _applyOverrides(
  List<ClassSession> sessions,
  List<DailyScheduleOverride> overrides,
) {
  if (overrides.isEmpty) return List.from(sessions);

  // Build override map: sessionId → override
  final overrideMap = <String, DailyScheduleOverride>{};
  final extraSessions = <DailyScheduleOverride>[];

  for (final o in overrides) {
    if (o.type == OverrideType.addExtra) {
      extraSessions.add(o);
    } else {
      overrideMap[o.sessionId] = o;
    }
  }

  final result = sessions.map((session) {
    final override = overrideMap[session.id];
    if (override == null) return session;

    return session.copyWith(
      isCancelled: override.type == OverrideType.cancel,
      overrideSubjectId: override.newSubjectId,
      overrideSubjectName: override.newSubjectName,
      overrideStartTime: override.newStartTime,
      overrideEndTime: override.newEndTime,
    );
  }).toList();

  // Add extra periods as synthetic ClassSession objects
  for (final extra in extraSessions) {
    if (extra.newSubjectId == null || extra.newStartTime == null) continue;
    final now = DateTime.now();
    result.add(ClassSession(
      id: extra.id, // Use override ID as session ID for extra periods
      subjectId: extra.newSubjectId!,
      subjectName: extra.newSubjectName ?? 'Extra Period',
      date: DateTime(now.year, now.month, now.day),
      startTime: extra.newStartTime!,
      endTime: extra.newEndTime ?? extra.newStartTime!,
      status: AttendanceStatus.notMarked,
      uid: extra.uid,
      isExtraPeriod: true,
    ));
  }

  return result;
}

int _parseTimeMinutes(String t) {
  final parts = t.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Clock tick provider (triggers every minute for live schedule updates)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<DateTime> clockTick(Ref ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now())
      .asBroadcastStream();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Schedule Page Notifier (correct attendance marking + bulk actions)
// ─────────────────────────────────────────────────────────────────────────────

enum ScheduleActionStatus { idle, loading, success, error }

class ScheduleNotifierState {
  final ScheduleActionStatus status;
  final String? errorMessage;
  const ScheduleNotifierState({
    this.status = ScheduleActionStatus.idle,
    this.errorMessage,
  });
}

@riverpod
class ScheduleNotifier extends _$ScheduleNotifier {
  @override
  ScheduleNotifierState build() => const ScheduleNotifierState();

  TimetableRepository get _repo => ref.read(timetableRepositoryProvider);

  // ── Core attendance marking (FIXED — writes log + updates counters) ────────

  /// Mark a single session's attendance.
  /// Only allowed after the class end time has passed.
  Future<void> markAttendance({
    required ClassSession session,
    required AttendanceStatus status,
  }) async {
    // Guard: only mark after class has ended
    if (!session.hasEnded && !session.isExtraPeriod) return;

    state = const ScheduleNotifierState(status: ScheduleActionStatus.loading);
    try {
      await _repo.markSessionAttendance(session: session, status: status);
      state = const ScheduleNotifierState(status: ScheduleActionStatus.success);
    } catch (e) {
      state = ScheduleNotifierState(
        status: ScheduleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Bulk: mark remaining classes absent ───────────────────────────────────

  /// Marks all upcoming (not yet started) and action-required sessions absent.
  Future<void> markRemainingAbsent(List<ClassSession> sessions) async {
    state = const ScheduleNotifierState(status: ScheduleActionStatus.loading);
    try {
      final toMark = sessions
          .where((s) =>
              s.status == AttendanceStatus.notMarked && !s.isCancelled)
          .toList();
      await _repo.markMultipleSessionsAbsent(toMark);
      state =
          const ScheduleNotifierState(status: ScheduleActionStatus.success);
    } catch (e) {
      state = ScheduleNotifierState(
        status: ScheduleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Bulk: mark full day absent ────────────────────────────────────────────

  /// Marks ALL unmarked sessions of the day absent.
  /// Skips already-marked and cancelled sessions.
  Future<void> markFullDayAbsent(List<ClassSession> allSessions) async {
    state = const ScheduleNotifierState(status: ScheduleActionStatus.loading);
    try {
      await _repo.markMultipleSessionsAbsent(allSessions);
      state =
          const ScheduleNotifierState(status: ScheduleActionStatus.success);
    } catch (e) {
      state = ScheduleNotifierState(
        status: ScheduleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Daily schedule overrides ──────────────────────────────────────────────

  Future<void> saveOverride(DailyScheduleOverride override) async {
    state = const ScheduleNotifierState(status: ScheduleActionStatus.loading);
    try {
      await _repo.saveDailyOverride(override);
      state =
          const ScheduleNotifierState(status: ScheduleActionStatus.success);
    } catch (e) {
      state = ScheduleNotifierState(
        status: ScheduleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteOverride(String overrideId, DateTime date) async {
    try {
      await _repo.deleteDailyOverride(overrideId, date);
    } catch (_) {}
  }

  void reset() =>
      state = const ScheduleNotifierState();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Legacy providers (kept for backward compat with other screens)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
List<ClassSession> todayClasses(Ref ref) {
  final allAsync = ref.watch(todaySessionsStreamProvider);
  final all = allAsync.valueOrNull ?? [];
  return all..sort((a, b) => a.startTime.compareTo(b.startTime));
}

@riverpod
ClassSession? currentClass(Ref ref) {
  final data = ref.watch(schedulePageDataProvider);
  return data.currentClass;
}

@riverpod
ClassSession? nextClass(Ref ref) {
  final data = ref.watch(schedulePageDataProvider);
  return data.upcoming.firstOrNull;
}
