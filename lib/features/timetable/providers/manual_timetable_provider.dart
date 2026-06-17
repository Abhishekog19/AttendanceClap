import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/timetable_entry_model.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/timetable_repository.dart';

part 'manual_timetable_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────────────────────

enum ManualEntryStatus { idle, saving, success, error }

class ManualEntryState {
  final ManualEntryStatus status;
  final String? errorMessage;
  final int? generatedSessions;

  const ManualEntryState({
    this.status = ManualEntryStatus.idle,
    this.errorMessage,
    this.generatedSessions,
  });

  ManualEntryState copyWith({
    ManualEntryStatus? status,
    String? errorMessage,
    int? generatedSessions,
  }) =>
      ManualEntryState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        generatedSessions: generatedSessions ?? this.generatedSessions,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stream provider — watches all persisted timetable entries
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<TimetableEntry>> timetableEntriesStream(Ref ref) {
  return ref.watch(timetableRepositoryProvider).watchTimetableEntries();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notifier — save / update / delete individual entries
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class ManualTimetableNotifier extends _$ManualTimetableNotifier {
  @override
  ManualEntryState build() => const ManualEntryState();

  TimetableRepository get _repo => ref.read(timetableRepositoryProvider);
  SubjectRepository get _subjects => ref.read(subjectRepositoryProvider);

  // ── Add a new entry ───────────────────────────────────────────────────────

  Future<void> addEntry(TimetableEntry entry) async {
    state = state.copyWith(status: ManualEntryStatus.saving, errorMessage: null);
    try {
      // 1. Ensure subject exists; create if not — get the canonical subjectId
      final subjectId = await _ensureSubjectExists(entry);

      // 2. Persist the entry WITH subjectId so the subject link survives renames
      final entryWithId = entry.copyWith(subjectId: subjectId);
      await _repo.addTimetableEntry(entryWithId);

      // 3. If an active semester exists, generate sessions from today forward
      final semester = await _repo.getActiveSemester();
      int sessions = 0;
      if (semester != null) {
        sessions = await _repo.addSessionsForEntry(
          entry: entryWithId,
          subjectId: subjectId,
          semester: semester,
          fromDate: DateTime.now(),
        );
      }

      state = state.copyWith(
        status: ManualEntryStatus.success,
        generatedSessions: sessions,
      );
    } catch (e) {
      state = state.copyWith(
        status: ManualEntryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Update an existing entry ──────────────────────────────────────────────

  Future<void> updateEntry(TimetableEntry updated) async {
    if (updated.id == null) {
      state = state.copyWith(
          status: ManualEntryStatus.error,
          errorMessage: 'Cannot update: entry has no ID.');
      return;
    }
    state = state.copyWith(status: ManualEntryStatus.saving, errorMessage: null);
    try {
      await _repo.updateTimetableEntry(updated.id!, updated);
      state = state.copyWith(status: ManualEntryStatus.success);
    } catch (e) {
      state = state.copyWith(
          status: ManualEntryStatus.error, errorMessage: e.toString());
    }
  }

  // ── Delete an entry ───────────────────────────────────────────────────────

  Future<void> deleteEntry(
    TimetableEntry entry, {
    bool deleteFutureSessions = false,
  }) async {
    if (entry.id == null) return;
    state = state.copyWith(status: ManualEntryStatus.saving, errorMessage: null);
    try {
      await _repo.deleteTimetableEntry(
        entry.id!,
        subjectId: entry.subjectId, // preferred: rename-safe via subjectId
        subjectName: entry.subject,  // fallback: for legacy entries without subjectId
        day: entry.day,
        startTime: entry.startTime,
        deleteFutureSessions: deleteFutureSessions,
      );
      state = state.copyWith(status: ManualEntryStatus.success);
    } catch (e) {
      state = state.copyWith(
          status: ManualEntryStatus.error, errorMessage: e.toString());
    }
  }

  /// Returns the count of future notMarked sessions for the given entry.
  Future<int> countFutureSessions(TimetableEntry entry) =>
      _repo.countFutureSessionsForEntry(
        subjectId: entry.subjectId,
        subjectName: entry.subject,
        day: entry.day,
        startTime: entry.startTime,
      );

  void reset() => state = const ManualEntryState();

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Finds the subject by name in Firestore (case-insensitive) or creates it.
  Future<String> _ensureSubjectExists(TimetableEntry entry) async {
    final existing = await _subjects.getSubjects();
    final match = existing
        .where((s) =>
            s.name.toLowerCase() == entry.subject.toLowerCase())
        .firstOrNull;

    if (match != null) return match.id;

    // Create new subject
    await _subjects.addSubject(
      name: entry.subject,
      faculty: entry.faculty,
    );
    // Fetch again to get the generated ID
    final refreshed = await _subjects.getSubjects();
    return refreshed
        .firstWhere((s) =>
            s.name.toLowerCase() == entry.subject.toLowerCase())
        .id;
  }
}
