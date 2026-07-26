import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/class_session_model.dart';
import '../../../data/models/daily_schedule_override_model.dart';
import '../../../data/repositories/local_attendance_repository.dart';
import '../../../core/router/app_lifecycle_state.dart'
    show appLifecycleStateProvider, AppLifecycleReady;

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

// ───────────────────────────────────────────────────────────────────────────────
//  Today's raw sessions stream  (LOCAL — Phase 4)
// ───────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<ClassSession>> todaySessionsStream(Ref ref) {
  final repo = ref.watch(localAttendanceRepositoryProvider);
  // Resolve active semester from lifecycle state (already computed by router).
  final lifecycle = ref.watch(appLifecycleStateProvider).valueOrNull;
  final semId = lifecycle is AppLifecycleReady ? lifecycle.activeSemesterId : null;
  if (semId == null) return Stream.value(const <ClassSession>[]);
  return repo.watchTodaySessionModels(
    date: DateTime.now(),
    activeSemesterId: semId,
  );
}

// ───────────────────────────────────────────────────────────────────────────────
//  Daily overrides stream for today  (LOCAL — Phase 4)
// ───────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<DailyScheduleOverride>> todayOverridesStream(Ref ref) {
  return ref
      .watch(localAttendanceRepositoryProvider)
      .watchDailyOverrideModels(DateTime.now());
}

// ─────────────────────────────────────────────────────────────────────────────
//  Merged + bucketed schedule page data
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
SchedulePageData schedulePageData(Ref ref) {
  final sessionsAsync = ref.watch(todaySessionsStreamProvider);

  // Sessions arrive override-resolved from LocalAttendanceRepository.watchTodaySessionModels:
  // overrideStartTime / overrideEndTime are already embedded, so session.displayStartTime
  // and session.displayEndTime are correct without any extra merge step.
  final sessions = List<ClassSession>.from(sessionsAsync.valueOrNull ?? []);

  // Sort by display start time (already override-aware on fs.ClassSession)
  sessions.sort((a, b) => a.displayStartTime.compareTo(b.displayStartTime));

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  ClassSession? currentClass;
  final upcoming = <ClassSession>[];
  final actionRequired = <ClassSession>[];
  final completedToday = <ClassSession>[];

  for (final session in sessions) {
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
      currentClass ??= session;
    } else if (nowMinutes < startMin) {
      upcoming.add(session);
    } else {
      actionRequired.add(session);
    }
  }

  return SchedulePageData(
    currentClass: currentClass,
    upcoming: upcoming,
    actionRequired: actionRequired,
    completedToday: completedToday,
    totalTodayCount: sessions.where((s) => !s.isCancelled).length,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _applyOverrides removed — override merging now happens inside
//  LocalAttendanceRepository.watchTodaySessionModels (repo JOIN layer).
//  Sessions returned from todaySessionsStreamProvider already have
//  overrideStartTime / overrideEndTime / overrideSubjectId embedded.
// ─────────────────────────────────────────────────────────────────────────────

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

  LocalAttendanceRepository get _repo => ref.read(localAttendanceRepositoryProvider);

  // ── Core attendance marking (LOCAL — Phase 4) ─────────────────────────────

  /// Mark a single session's attendance.
  /// Only allowed after the class end time has passed.
  Future<void> markAttendance({
    required ClassSession session,
    required AttendanceStatus status,
  }) async {
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
      await _repo.saveOverride(override);
      state = const ScheduleNotifierState(status: ScheduleActionStatus.success);
    } catch (e) {
      state = ScheduleNotifierState(
        status: ScheduleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteOverride(String overrideId, DateTime date) async {
    state = const ScheduleNotifierState(status: ScheduleActionStatus.loading);
    try {
      await _repo.deleteOverride(overrideId, date);
      state = const ScheduleNotifierState(status: ScheduleActionStatus.success);
    } catch (e) {
      state = ScheduleNotifierState(
        status: ScheduleActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const ScheduleNotifierState();
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
