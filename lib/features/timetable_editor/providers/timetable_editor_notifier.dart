/// Timetable Editor Notifier
///
/// Central state manager for the timetable editor. Wires two Firestore
/// stream listeners (config, lectures) into a single in-memory
/// TimetableEditorState. Subjects come from the canonical subjectsStreamProvider.
///
/// All UI mutations apply locally first (instant rebuild), then fire
/// Firestore writes asynchronously.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/subject_model.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../models/timetable_editor_models.dart';
import '../repository/timetable_editor_repository.dart';

part 'timetable_editor_notifier.g.dart';

// ─── UI-only ephemeral state ──────────────────────────────────────────────────

class TimetableEditorUiState {
  final String? selectedSubjectId;

  const TimetableEditorUiState({
    this.selectedSubjectId,
  });

  TimetableEditorUiState copyWith({
    Object? selectedSubjectId = _sentinel,
  }) =>
      TimetableEditorUiState(
        selectedSubjectId: selectedSubjectId == _sentinel
            ? this.selectedSubjectId
            : selectedSubjectId as String?,
      );

  bool get isPlacementMode => selectedSubjectId != null;

  static const _sentinel = Object();
}

// ─── Combined notifier state ──────────────────────────────────────────────────

class TimetableEditorFullState {
  final TimetableEditorState data;
  final TimetableEditorUiState ui;
  final Map<String, ConflictInfo> conflicts; // keyed by lectureId

  const TimetableEditorFullState({
    required this.data,
    required this.ui,
    required this.conflicts,
  });

  TimetableEditorFullState copyWith({
    TimetableEditorState? data,
    TimetableEditorUiState? ui,
    Map<String, ConflictInfo>? conflicts,
  }) =>
      TimetableEditorFullState(
        data: data ?? this.data,
        ui: ui ?? this.ui,
        conflicts: conflicts ?? this.conflicts,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

@riverpod
class TimetableEditorNotifier extends _$TimetableEditorNotifier {
  final _uuid = const Uuid();

  StreamSubscription<Map<String, dynamic>>? _configSub;
  StreamSubscription<List<LectureBlock>>? _lecturesSub;
  Timer? _regenDebounce;
  // Phase E: backfill runs at most once per notifier lifetime.
  bool _backfillDone = false;

  @override
  TimetableEditorFullState build() {
    const initialState = TimetableEditorFullState(
      data: TimetableEditorState(),
      ui: TimetableEditorUiState(),
      conflicts: {},
    );

    // Watch the repo provider so the notifier is torn down and rebuilt
    // whenever the authenticated user changes (auth switch, logout, login).
    // onDispose below cancels the old subscriptions automatically.
    ref.watch(timetableEditorRepositoryProvider);

    // Wire stream listeners after first build
    Future.microtask(_wireListeners);

    ref.onDispose(() {
      _configSub?.cancel();
      _lecturesSub?.cancel();
      _regenDebounce?.cancel();
    });

    return initialState;
  }

  TimetableEditorRepository get _repo =>
      ref.read(timetableEditorRepositoryProvider);

  // ── Stream wiring ────────────────────────────────────────────────────────────

  void _wireListeners() {
    // Config stream — reads grid settings
    _configSub = _repo.watchConfig().listen((configMap) {
      final defaultDuration =
          (configMap['defaultLectureDurationMinutes'] as num?)?.toInt() ?? 60;
      final gridStart = (configMap['gridStartHour'] as num?)?.toInt() ?? 8;
      final gridEnd = (configMap['gridEndHour'] as num?)?.toInt() ?? 22;

      _updateData(state.data.copyWith(
        defaultLectureDurationMinutes: defaultDuration,
        gridStartHour: gridStart,
        gridEndHour: gridEnd,
      ));
    });

    // Subjects come from the canonical subjects stream
    ref.listen<AsyncValue<List<SubjectModel>>>(
      subjectsStreamProvider,
      (_, next) {
        if (next.hasValue) {
          _updateData(state.data.copyWith(subjects: next.value!));
          // Re-run purge whenever subjects list changes (e.g. a subject deleted)
          _purgeOrphanedLectures();
          // Phase E: one-time backfill for subjects missing colorHex / shortName.
          // Fire-and-forget — never blocks the UI or causes a provider cycle.
          if (!_backfillDone && next.value!.isNotEmpty) {
            _backfillDone = true;
            ref.read(subjectRepositoryProvider).backfillSubjectMetadata();
          }
        }
      },
      fireImmediately: true,
    );

    // Lectures stream
    _lecturesSub = _repo.watchLectures().listen((lectures) {
      _updateData(state.data.copyWith(lectures: lectures));
      // Purge lectures that don't match any loaded subject
      _purgeOrphanedLectures();
    });
  }

  void _updateData(TimetableEditorState newData) {
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);
  }

  // ── Orphan purge ─────────────────────────────────────────────────────────────

  /// Removes LectureBlocks whose subjectId no longer exists in the loaded
  /// subjects list. Fires Firestore deletes fire-and-forget.
  /// Safe to call speculatively — no-ops when subjects list is empty (still loading).
  void _purgeOrphanedLectures() {
    final subjects = state.data.subjects;
    if (subjects.isEmpty) return; // subjects not loaded yet — wait
    final subjectIds = subjects.map((s) => s.id).toSet();
    final orphans = state.data.lectures
        .where((l) => !subjectIds.contains(l.subjectId))
        .toList();
    if (orphans.isEmpty) return;
    for (final l in orphans) {
      _repo.deleteLecture(l.id);
    }
    _updateData(state.data.copyWith(
      lectures:
          state.data.lectures.where((l) => subjectIds.contains(l.subjectId)).toList(),
    ));
  }

  // ── Subject management (delegates to SubjectRepository via onboarding path) ──

  // Subjects are managed via the canonical subjectsStreamProvider.
  // The grid's "+ Subject" button should trigger the same add-subject flow as
  // the onboarding Subject Setup screen. No subject CRUD in this notifier.

  // ── Placement mode ───────────────────────────────────────────────────────────

  /// Selects a subject for placement (or clears selection if same ID tapped again).
  void selectSubject(String? id) {
    final newId = (id == state.ui.selectedSubjectId) ? null : id;
    state = state.copyWith(
      ui: state.ui.copyWith(selectedSubjectId: newId),
    );
  }

  /// Clears placement mode.
  void cancelPlacement() {
    state = state.copyWith(
      ui: state.ui.copyWith(selectedSubjectId: null),
    );
  }

  // ── Place lecture ─────────────────────────────────────────────────────────────

  /// Places the currently selected subject at an exact [startTime] ("HH:mm")
  /// for a given [day]. Returns false if no subject is selected or the
  /// new block would overlap an existing block (so callers can give feedback).
  Future<bool> placeLectureAt(String day, String startTime) async {
    final subjectId = state.ui.selectedSubjectId;
    if (subjectId == null) return false;

    final id = _uuid.v4();
    final lecture = LectureBlock(
      id: id,
      day: day,
      subjectId: subjectId,
      startTime: startTime,
      durationMinutes: state.data.defaultLectureDurationMinutes,
    );

    // Check overlap with existing blocks
    final newStart = _timeToMins(startTime);
    final newEnd   = newStart + lecture.durationMinutes;
    final overlaps = state.data.lecturesForDay(day).any((l) {
      final lStart = _timeToMins(l.startTime);
      final lEnd   = lStart + l.durationMinutes;
      return newStart < lEnd && lStart < newEnd;
    });
    if (overlaps) return false;

    // Optimistic local update
    _updateData(state.data.copyWith(
      lectures: [...state.data.lectures, lecture],
    ));

    // Firestore (fire-and-forget)
    _repo.addLecture(lecture);

    // Debounced session regeneration
    _scheduleRegen();
    return true;
  }

  /// Legacy method retained for compatibility — places at whole-hour boundary.
  @Deprecated('Use placeLectureAt(day, startTime) instead')
  Future<bool> placeLecture(String day, int hour) =>
      placeLectureAt(day, '${hour.toString().padLeft(2, '0')}:00');

  // ── Delete lecture ─────────────────────────────────────────────────────────────

  Future<void> deleteLecture(String lectureId) async {
    _updateData(state.data.copyWith(
      lectures: state.data.lectures.where((l) => l.id != lectureId).toList(),
    ));
    _repo.deleteLecture(lectureId);
    _scheduleRegen();
  }

  // ── Update lecture time / metadata ────────────────────────────────────────────

  Future<void> updateLectureTime(
    String lectureId, {
    required String startTime,
    required int durationMinutes,
  }) async {
    final before = _lectureById(lectureId);
    if (before == null) return;
    final after = before.copyWith(
        startTime: startTime, durationMinutes: durationMinutes);
    _updateData(state.data.copyWith(
      lectures:
          state.data.lectures.map((l) => l.id == lectureId ? after : l).toList(),
    ));
    _repo.updateLecture(after);
    _scheduleRegen();
  }

  Future<void> updateLectureDetails(
    String lectureId, {
    String? facultyName,
    String? classroom,
    String? notes,
    String? subjectId,
    String? startTime,
    int? durationMinutes,
  }) async {
    final before = _lectureById(lectureId);
    if (before == null) return;
    final after = before.copyWith(
      facultyName: facultyName ?? before.facultyName,
      classroom: classroom ?? before.classroom,
      notes: notes ?? before.notes,
      subjectId: subjectId,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
    _updateData(state.data.copyWith(
      lectures:
          state.data.lectures.map((l) => l.id == lectureId ? after : l).toList(),
    ));
    _repo.updateLecture(after);
    _scheduleRegen();
  }

  // ── Grid Config ─────────────────────────────────────────────────────────────

  Future<void> updateDefaultLectureDuration(int minutes) async {
    _updateData(state.data.copyWith(defaultLectureDurationMinutes: minutes));
    _repo.saveGridConfig(defaultLectureDurationMinutes: minutes);
  }

  Future<void> updateGridHourRange(int startHour, int endHour) async {
    _updateData(state.data.copyWith(
      gridStartHour: startHour,
      gridEndHour: endHour,
    ));
    _repo.saveGridConfig(gridStartHour: startHour, gridEndHour: endHour);
  }

  // ── Session regeneration (debounced) ────────────────────────────────────────

  /// Schedules a session regeneration 1.5 seconds after the last edit.
  /// Rapid-fire placements only trigger one regeneration.
  void _scheduleRegen() {
    _regenDebounce?.cancel();
    _regenDebounce = Timer(const Duration(milliseconds: 1500), _doRegen);
  }

  Future<void> _doRegen() async {
    final lectures = state.data.lectures;
    // Always run regeneration (even for empty lectures list) so stale future
    // sessions are cleaned up when all lectures are removed.
    await ref.read(timetableRepositoryProvider)
        .regenerateFutureSessionsFromLectures(lectures: lectures);
  }

  /// Cancels any pending debounce and immediately runs regeneration.
  /// Called by [EditTimetableScreen] when the user taps Done.
  Future<void> flushRegeneration() async {
    _regenDebounce?.cancel();
    _regenDebounce = null;
    await _doRegen();
  }

  // ── Conflict detection ────────────────────────────────────────────────────────

  Map<String, ConflictInfo> _detectConflicts(TimetableEditorState data) {
    final conflicts = <String, ConflictInfo>{};

    for (final day in kDayOrder) {
      final dayLectures = data.lecturesForDay(day);

      for (int i = 0; i < dayLectures.length; i++) {
        final a = dayLectures[i];
        final aStart = _timeToMins(a.startTime);
        final aEnd = aStart + a.durationMinutes;

        for (int j = i + 1; j < dayLectures.length; j++) {
          final b = dayLectures[j];
          final bStart = _timeToMins(b.startTime);
          final bEnd = bStart + b.durationMinutes;

          final overlaps = aStart < bEnd && bStart < aEnd;
          if (overlaps) {
            final subjectA =
                data.subjectById(a.subjectId)?.effectiveShortName ?? '?';
            final subjectB =
                data.subjectById(b.subjectId)?.effectiveShortName ?? '?';
            conflicts[a.id] = ConflictInfo(
              lectureId: a.id,
              message: 'Overlaps with $subjectB',
            );
            conflicts[b.id] = ConflictInfo(
              lectureId: b.id,
              message: 'Overlaps with $subjectA',
            );
          }
        }
      }
    }

    return conflicts;
  }

  static int _timeToMins(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  LectureBlock? _lectureById(String id) {
    try {
      return state.data.lectures.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gets the lecture occupying a given hour row for a day, if any.
  LectureBlock? lectureAtHour(String day, int hour) =>
      state.data.lectureAtHour(day, hour);

  /// Checks if a given hour row is occupied.
  bool isHourOccupied(String day, int hour) =>
      lectureAtHour(day, hour) != null;
}
