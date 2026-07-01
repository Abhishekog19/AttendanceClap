/// Timetable Editor Notifier
///
/// Central state manager for the timetable editor. Wires three Firestore
/// stream listeners (config, subjects, lectures) into a single in-memory
/// TimetableEditorState. All UI mutations apply locally first (instant
/// rebuild), then fire Firestore writes asynchronously (Section 1.4).
///
/// Also manages:
///   - selectedSubjectId  (ephemeral, not persisted — placement mode)
///   - pickupLectureId    (ephemeral — move-lecture mode)
///   - undo/redo stacks   (local only, never in Firestore)
///   - conflict detection (computed on every state change)
///   - day-copy suggestion tracking

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/timetable_action.dart';
import '../models/timetable_editor_models.dart';
import '../repository/timetable_editor_repository.dart';

part 'timetable_editor_notifier.g.dart';

// ─── UI-only ephemeral state ──────────────────────────────────────────────────

class TimetableEditorUiState {
  final String? selectedSubjectId;
  final String? pickupLectureId; // Move mode: lecture ID currently "picked up"
  final Set<String> dayCopySeen; // days whose copy suggestion was dismissed

  const TimetableEditorUiState({
    this.selectedSubjectId,
    this.pickupLectureId,
    this.dayCopySeen = const {},
  });

  TimetableEditorUiState copyWith({
    Object? selectedSubjectId = _sentinel,
    Object? pickupLectureId = _sentinel,
    Set<String>? dayCopySeen,
  }) =>
      TimetableEditorUiState(
        selectedSubjectId: selectedSubjectId == _sentinel
            ? this.selectedSubjectId
            : selectedSubjectId as String?,
        pickupLectureId: pickupLectureId == _sentinel
            ? this.pickupLectureId
            : pickupLectureId as String?,
        dayCopySeen: dayCopySeen ?? this.dayCopySeen,
      );

  bool get isPlacementMode => selectedSubjectId != null;
  bool get isPickupMode => pickupLectureId != null;

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

  // Undo/redo stacks — local only, never serialised
  final List<TimetableAction> _undoStack = [];
  final List<TimetableAction> _redoStack = [];

  // Stream subscriptions for the three Firestore listeners
  StreamSubscription<Map<String, dynamic>>? _configSub;
  StreamSubscription<List<TimetableSubject>>? _subjectsSub;
  StreamSubscription<List<LectureBlock>>? _lecturesSub;

  @override
  TimetableEditorFullState build() {
    final initialState = TimetableEditorFullState(
      data: const TimetableEditorState(),
      ui: const TimetableEditorUiState(),
      conflicts: const {},
    );

    // Wire stream listeners after first build
    Future.microtask(_wireListeners);

    ref.onDispose(() {
      _configSub?.cancel();
      _subjectsSub?.cancel();
      _lecturesSub?.cancel();
    });

    return initialState;
  }

  TimetableEditorRepository get _repo =>
      ref.read(timetableEditorRepositoryProvider);

  // ── Stream wiring ────────────────────────────────────────────────────────────

  void _wireListeners() {
    _configSub = _repo.watchConfig().listen((configMap) {
      final defaultSchedule = (configMap['defaultSchedule'] as List<dynamic>? ?? [])
          .map((m) => PeriodSlot.fromMap(m as Map<String, dynamic>))
          .toList();

      final daySchedulesRaw = configMap['daySchedules'] as Map<String, dynamic>? ?? {};
      final daySchedules = <String, DaySchedule>{};
      daySchedulesRaw.forEach((day, val) {
        daySchedules[day] =
            DaySchedule.fromMap(day, val as Map<String, dynamic>);
      });

      _updateData(state.data.copyWith(
        defaultSchedule: defaultSchedule,
        daySchedules: daySchedules,
      ));
    });

    _subjectsSub = _repo.watchSubjects().listen((subjects) {
      _updateData(state.data.copyWith(subjects: subjects));
    });

    _lecturesSub = _repo.watchLectures().listen((lectures) {
      _updateData(state.data.copyWith(lectures: lectures));
    });
  }

  void _updateData(TimetableEditorState newData) {
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);
  }

  // ── Seed from onboarding subjects ────────────────────────────────────────────

  /// Called by the onboarding grid screen to seed subjects from onboarding state.
  /// Only seeds if no subjects exist yet in the editor collection.
  Future<void> seedSubjectsIfEmpty(List<TimetableSubject> subjects) async {
    if (state.data.subjects.isNotEmpty) return;
    for (final s in subjects) {
      await _repo.addSubject(s);
    }
  }

  // ── Subject management ───────────────────────────────────────────────────────

  Future<void> addSubject(TimetableSubject subject) async {
    final id = _uuid.v4();
    final withId = subject.copyWith(id: id);
    // Optimistic local update
    state = state.copyWith(
      data: state.data.copyWith(
        subjects: [...state.data.subjects, withId],
      ),
    );
    // Firestore write (fire-and-forget)
    _repo.addSubject(withId);
  }

  Future<void> updateSubject(TimetableSubject subject) async {
    state = state.copyWith(
      data: state.data.copyWith(
        subjects: state.data.subjects
            .map((s) => s.id == subject.id ? subject : s)
            .toList(),
      ),
    );
    _repo.updateSubject(subject);
  }

  Future<void> deleteSubject(String id) async {
    state = state.copyWith(
      data: state.data.copyWith(
        subjects: state.data.subjects.where((s) => s.id != id).toList(),
      ),
    );
    _repo.deleteSubject(id);
  }

  // ── Placement mode ───────────────────────────────────────────────────────────

  /// Selects a subject for placement (or clears selection if same ID tapped again).
  void selectSubject(String? id) {
    final newId = (id == state.ui.selectedSubjectId) ? null : id;
    state = state.copyWith(
      ui: state.ui.copyWith(
        selectedSubjectId: newId,
        pickupLectureId: null, // clear pickup mode if switching to placement
      ),
    );
  }

  /// Clears placement mode.
  void cancelPlacement() {
    state = state.copyWith(
      ui: state.ui.copyWith(
        selectedSubjectId: null,
        pickupLectureId: null,
      ),
    );
  }

  // ── Place lecture ────────────────────────────────────────────────────────────

  /// Places the currently selected subject (or picked-up lecture) into the given cell.
  /// [day]: "MON".."SUN", [periodId]: period slot ID.
  Future<void> placeLecture(String day, String periodId) async {
    // Move mode: relocate picked-up lecture
    if (state.ui.isPickupMode) {
      await _completeMoveToCell(day, periodId);
      return;
    }

    final subjectId = state.ui.selectedSubjectId;
    if (subjectId == null) return;

    // Check if cell is already occupied — if so, don't overwrite
    final existing = _lectureAtCell(day, periodId);
    if (existing != null) return; // cell bottom sheet should handle this

    final id = _uuid.v4();
    final lecture = LectureBlock(
      id: id,
      day: day,
      subjectId: subjectId,
      startPeriodId: periodId,
      spanPeriods: _pendingDuplicateSpan,
      isLab: _pendingDuplicateIsLab,
    );
    // Reset duplicate span/isLab after use
    _pendingDuplicateSpan = 1;
    _pendingDuplicateIsLab = false;

    // Optimistic local
    final newLectures = [...state.data.lectures, lecture];
    final newData = state.data.copyWith(lectures: newLectures);
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);
    // selection persists for rapid placement

    // Push to undo stack
    _pushUndo(PlaceLectureAction(lecture));

    // Firestore
    _repo.addLecture(lecture);
  }

  // ── Delete lecture ────────────────────────────────────────────────────────────

  Future<void> deleteLecture(String lectureId) async {
    final lecture = _lectureById(lectureId);
    if (lecture == null) return;

    // Optimistic local
    final newData = state.data.copyWith(
      lectures: state.data.lectures.where((l) => l.id != lectureId).toList(),
    );
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);

    _pushUndo(DeleteLectureAction(lecture));
    _repo.deleteLecture(lectureId);
  }

  // ── Update lecture ────────────────────────────────────────────────────────────

  Future<void> updateLecture(
    String lectureId, {
    int? spanPeriods,
    String? facultyName,
    String? classroom,
    String? notes,
    bool? isLab,
    String? subjectId,
  }) async {
    final before = _lectureById(lectureId);
    if (before == null) return;

    final after = before.copyWith(
      spanPeriods: spanPeriods,
      facultyName: facultyName ?? before.facultyName,
      classroom: classroom ?? before.classroom,
      notes: notes ?? before.notes,
      isLab: isLab,
      subjectId: subjectId,
    );

    final newData = state.data.copyWith(
      lectures: state.data.lectures.map((l) => l.id == lectureId ? after : l).toList(),
    );
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);

    _pushUndo(UpdateLectureAction(before: before, after: after));
    _repo.updateLecture(after);
  }

  // ── Move lecture ──────────────────────────────────────────────────────────────

  /// Picks up a lecture for moving — clears it from the grid, enters pickup mode.
  Future<void> startMoveLecture(String lectureId) async {
    final lecture = _lectureById(lectureId);
    if (lecture == null) return;

    // Store the original so _completeMoveToCell can reconstruct it
    _pendingPickup = lecture;

    // Remove from grid locally (will be re-placed on drop)
    final newData = state.data.copyWith(
      lectures: state.data.lectures.where((l) => l.id != lectureId).toList(),
    );
    state = state.copyWith(
      data: newData,
      ui: state.ui.copyWith(
        pickupLectureId: lectureId,
        selectedSubjectId: null,
      ),
    );
  }

  /// Cancels move mode — restores the lecture to its original position.
  Future<void> cancelMove() async {
    final lectureId = state.ui.pickupLectureId;
    if (lectureId == null) return;

    // The lecture was removed optimistically; we need to re-fetch from Firestore
    // by watching — but actually it's still in Firestore (we only removed locally).
    // The stream reconciliation will restore it. Just clear pickup mode.
    state = state.copyWith(
      ui: state.ui.copyWith(pickupLectureId: null),
    );
  }

  Future<void> _completeMoveToCell(String day, String periodId) async {
    final lectureId = state.ui.pickupLectureId;
    if (lectureId == null) return;

    // Get the original lecture from repo (stream will have it)
    // We need its original data — look it up from most recent stream data
    // Since we removed it locally, we'll reconstruct from context.
    // Use a workaround: re-listen once from Firestore.
    // For simplicity: store the "before" in ui state. We'll track it via a temp field.
    // Actually we can just use state — the lecture was in state.data.lectures before pickup.
    // Since we removed it in startMoveLecture, we must store the original elsewhere.
    // We'll persist the original in a local variable at pickup time.
    // This requires refactor — instead, store it in the UI state.
    // For now: the move is handled by creating a new lecture at destination and deleting source.

    // Since pickup removed the lecture locally (Firestore still has it),
    // the stream will bring it back unless we also delete from Firestore.
    // Strategy: Delete old + create new = effective move.

    // We need the original to reconstruct; use a pending-actions map.
    // Simpler: store original in _pickupOriginal field.
    final original = _pendingPickup;
    if (original == null) {
      cancelMove();
      return;
    }

    final after = original.copyWith(
      day: day,
      startPeriodId: periodId,
    );

    final newLectures = [...state.data.lectures, after];
    final newData = state.data.copyWith(lectures: newLectures);
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(
      data: newData,
      ui: state.ui.copyWith(pickupLectureId: null),
      conflicts: conflicts,
    );

    _pushUndo(MoveLectureAction(before: original, after: after));

    // Delete old from Firestore + add new (new doc with same data but different position)
    _repo.deleteLecture(original.id);
    _repo.addLecture(after);
    _pendingPickup = null;
  }

  LectureBlock? _pendingPickup; // temp storage during move

  // ── Duplicate lecture ─────────────────────────────────────────────────────────

  /// Enters placement mode pre-loaded with the given lecture's subject + span.
  void duplicateLecture(String lectureId) {
    final lecture = _lectureById(lectureId);
    if (lecture == null) return;
    // Select the same subject — user taps a cell to place duplicate
    state = state.copyWith(
      ui: state.ui.copyWith(selectedSubjectId: lecture.subjectId),
    );
    _pendingDuplicateSpan = lecture.spanPeriods;
    _pendingDuplicateIsLab = lecture.isLab;
  }

  int _pendingDuplicateSpan = 1;
  bool _pendingDuplicateIsLab = false;

  // ── Copy day ─────────────────────────────────────────────────────────────────

  Future<void> copyDaySchedule(String fromDay, String toDay) async {
    final fromLectures = state.data.lecturesForDay(fromDay);
    if (fromLectures.isEmpty) return;

    final removedLectures = state.data.lecturesForDay(toDay);

    // Generate new lectures with new IDs for the target day
    final addedLectures = fromLectures.map((l) {
      return l.copyWith(
        id: _uuid.v4(),
        day: toDay,
      );
    }).toList();

    // Optimistic: remove target day lectures, add copies
    final retainedLectures =
        state.data.lectures.where((l) => l.day != toDay).toList();
    final newLectures = [...retainedLectures, ...addedLectures];
    final newData = state.data.copyWith(lectures: newLectures);
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);

    _pushUndo(CopyDayAction(
      fromDay: fromDay,
      toDay: toDay,
      addedLectures: addedLectures,
      removedLectures: removedLectures,
    ));

    // Firestore
    await _repo.deleteLectures(removedLectures.map((l) => l.id).toList());
    await _repo.addLectures(addedLectures);
  }

  Future<void> copyDayToRange(String fromDay, List<String> toDays) async {
    final fromLectures = state.data.lecturesForDay(fromDay);
    if (fromLectures.isEmpty) return;

    final removedLectures = state.data.lectures
        .where((l) => toDays.contains(l.day))
        .toList();

    final addedLectures = <LectureBlock>[];
    for (final toDay in toDays) {
      addedLectures.addAll(fromLectures.map((l) => l.copyWith(
            id: _uuid.v4(),
            day: toDay,
          )));
    }

    final retainedLectures =
        state.data.lectures.where((l) => !toDays.contains(l.day)).toList();
    final newLectures = [...retainedLectures, ...addedLectures];
    final newData = state.data.copyWith(lectures: newLectures);
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);

    _pushUndo(CopyDayToRangeAction(
      fromDay: fromDay,
      toDays: toDays,
      addedLectures: addedLectures,
      removedLectures: removedLectures,
    ));

    await _repo.deleteLectures(removedLectures.map((l) => l.id).toList());
    await _repo.addLectures(addedLectures);
  }

  // ── Day-copy suggestion tracking ─────────────────────────────────────────────

  void dismissDayCopySuggestion(String day) {
    state = state.copyWith(
      ui: state.ui.copyWith(
        dayCopySeen: {...state.ui.dayCopySeen, day},
      ),
    );
  }

  bool shouldShowDayCopySuggestion(String day) {
    if (state.ui.dayCopySeen.contains(day)) return false;
    // Show if selected day is empty but prior day has lectures
    final dayIdx = kDayOrder.indexOf(day);
    if (dayIdx <= 0) return false;
    final prevDay = kDayOrder[dayIdx - 1];
    final prevHasLectures = state.data.lecturesForDay(prevDay).isNotEmpty;
    final currentEmpty = state.data.lecturesForDay(day).isEmpty;
    return prevHasLectures && currentEmpty;
  }

  // ── Schedule / Timing ────────────────────────────────────────────────────────

  Future<void> updateDefaultSchedule(List<PeriodSlot> slots) async {
    final before = state.data.defaultSchedule;
    final beforeDaySchedules = Map<String, DaySchedule>.from(state.data.daySchedules);

    final newData = state.data.copyWith(defaultSchedule: slots);
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);

    _pushUndo(TimingChangeAction(
      beforeDefault: before,
      afterDefault: slots,
      beforeDaySchedules: beforeDaySchedules,
      afterDaySchedules: state.data.daySchedules,
    ));

    _repo.saveDefaultSchedule(slots);
  }

  Future<void> updateDaySchedule(String day, DaySchedule schedule) async {
    final before = state.data.defaultSchedule;
    final beforeDaySchedules = Map<String, DaySchedule>.from(state.data.daySchedules);
    final afterDaySchedules = {...beforeDaySchedules, day: schedule};

    final newData = state.data.copyWith(daySchedules: afterDaySchedules);
    final conflicts = _detectConflicts(newData);
    state = state.copyWith(data: newData, conflicts: conflicts);

    _pushUndo(TimingChangeAction(
      beforeDefault: before,
      afterDefault: state.data.defaultSchedule,
      beforeDaySchedules: beforeDaySchedules,
      afterDaySchedules: afterDaySchedules,
    ));

    _repo.saveDaySchedule(day, schedule);
  }

  // ── Undo / Redo ──────────────────────────────────────────────────────────────

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushUndo(TimetableAction action) {
    _undoStack.add(action);
    _redoStack.clear(); // any new action clears redo history
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    await _applyInverse(action);
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) return;
    final action = _redoStack.removeLast();
    _undoStack.add(action);
    await _applyForward(action);
  }

  Future<void> _applyInverse(TimetableAction action) async {
    switch (action) {
      case PlaceLectureAction(:final placed):
        // Undo place = delete
        final newData = state.data.copyWith(
          lectures: state.data.lectures.where((l) => l.id != placed.id).toList(),
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.deleteLecture(placed.id);

      case DeleteLectureAction(:final deleted):
        // Undo delete = re-place
        final newData = state.data.copyWith(
          lectures: [...state.data.lectures, deleted],
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.addLecture(deleted);

      case MoveLectureAction(:final before, :final after):
        // Undo move = move back
        final newData = state.data.copyWith(
          lectures: state.data.lectures.map((l) => l.id == after.id ? before : l).toList(),
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.updateLecture(before);

      case UpdateLectureAction(:final before):
        // Undo update = restore original
        final newData = state.data.copyWith(
          lectures: state.data.lectures.map((l) => l.id == before.id ? before : l).toList(),
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.updateLecture(before);

      case CopyDayAction(:final addedLectures, :final removedLectures):
        // Undo copy = remove added, restore removed
        final withoutAdded = state.data.lectures
            .where((l) => !addedLectures.any((a) => a.id == l.id))
            .toList();
        final restored = [...withoutAdded, ...removedLectures];
        final newData = state.data.copyWith(lectures: restored);
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.deleteLectures(addedLectures.map((l) => l.id).toList());
        _repo.addLectures(removedLectures);

      case CopyDayToRangeAction(:final addedLectures, :final removedLectures):
        final withoutAdded = state.data.lectures
            .where((l) => !addedLectures.any((a) => a.id == l.id))
            .toList();
        final restored = [...withoutAdded, ...removedLectures];
        final newData = state.data.copyWith(lectures: restored);
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.deleteLectures(addedLectures.map((l) => l.id).toList());
        _repo.addLectures(removedLectures);

      case TimingChangeAction(:final beforeDefault, :final beforeDaySchedules):
        final newData = state.data.copyWith(
          defaultSchedule: beforeDefault,
          daySchedules: beforeDaySchedules,
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.saveDefaultSchedule(beforeDefault);
        for (final entry in beforeDaySchedules.entries) {
          _repo.saveDaySchedule(entry.key, entry.value);
        }
    }
  }

  Future<void> _applyForward(TimetableAction action) async {
    switch (action) {
      case PlaceLectureAction(:final placed):
        final newData = state.data.copyWith(
          lectures: [...state.data.lectures, placed],
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.addLecture(placed);

      case DeleteLectureAction(:final deleted):
        final newData = state.data.copyWith(
          lectures: state.data.lectures.where((l) => l.id != deleted.id).toList(),
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.deleteLecture(deleted.id);

      case MoveLectureAction(:final before, :final after):
        final newData = state.data.copyWith(
          lectures: state.data.lectures.map((l) => l.id == before.id ? after : l).toList(),
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.updateLecture(after);

      case UpdateLectureAction(:final after):
        final newData = state.data.copyWith(
          lectures: state.data.lectures.map((l) => l.id == after.id ? after : l).toList(),
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.updateLecture(after);

      case CopyDayAction(:final addedLectures, :final removedLectures, :final toDay):
        final withoutTarget = state.data.lectures.where((l) => l.day != toDay).toList();
        final newData = state.data.copyWith(lectures: [...withoutTarget, ...addedLectures]);
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.deleteLectures(removedLectures.map((l) => l.id).toList());
        _repo.addLectures(addedLectures);

      case CopyDayToRangeAction(:final addedLectures, :final removedLectures, :final toDays):
        final withoutTargets = state.data.lectures.where((l) => !toDays.contains(l.day)).toList();
        final newData = state.data.copyWith(lectures: [...withoutTargets, ...addedLectures]);
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.deleteLectures(removedLectures.map((l) => l.id).toList());
        _repo.addLectures(addedLectures);

      case TimingChangeAction(:final afterDefault, :final afterDaySchedules):
        final newData = state.data.copyWith(
          defaultSchedule: afterDefault,
          daySchedules: afterDaySchedules,
        );
        state = state.copyWith(data: newData, conflicts: _detectConflicts(newData));
        _repo.saveDefaultSchedule(afterDefault);
        for (final entry in afterDaySchedules.entries) {
          _repo.saveDaySchedule(entry.key, entry.value);
        }
    }
  }

  // ── Conflict detection ────────────────────────────────────────────────────────

  Map<String, ConflictInfo> _detectConflicts(TimetableEditorState data) {
    final conflicts = <String, ConflictInfo>{};

    for (final day in kDayOrder) {
      final dayLectures = data.lecturesForDay(day);
      final periods = data.periodsForDay(day);
      final periodIds = periods.map((p) => p.id).toList();

      for (int i = 0; i < dayLectures.length; i++) {
        final a = dayLectures[i];
        final aStart = periodIds.indexOf(a.startPeriodId);
        if (aStart == -1) continue;
        final aEnd = aStart + a.spanPeriods - 1;

        // Check 2: spanPeriods extends past last period
        if (aEnd >= periodIds.length) {
          conflicts[a.id] = ConflictInfo(
            lectureId: a.id,
            message: 'Extends past the last period for $day',
          );
        }

        // Check 1: overlapping lectures
        for (int j = i + 1; j < dayLectures.length; j++) {
          final b = dayLectures[j];
          final bStart = periodIds.indexOf(b.startPeriodId);
          if (bStart == -1) continue;
          final bEnd = bStart + b.spanPeriods - 1;

          final overlaps = aStart <= bEnd && bStart <= aEnd;
          if (overlaps) {
            final subjectA = data.subjectById(a.subjectId)?.shortName ?? '?';
            final subjectB = data.subjectById(b.subjectId)?.shortName ?? '?';
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

      // Check 3: overlapping PeriodSlot times
      for (int i = 0; i < periods.length - 1; i++) {
        final current = periods[i];
        final next = periods[i + 1];
        final currentEnd = _parseTimeToMins(current.endTime);
        final nextStart = _parseTimeToMins(next.startTime);
        if (currentEnd > nextStart) {
          // Mark all lectures in these overlapping slots
          for (final l in dayLectures) {
            if (l.startPeriodId == current.id || l.startPeriodId == next.id) {
              conflicts[l.id] = ConflictInfo(
                lectureId: l.id,
                message:
                    'Overlapping period times: ${current.endTime} vs ${next.startTime}',
              );
            }
          }
        }
      }
    }

    return conflicts;
  }

  static int _parseTimeToMins(String t) {
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

  LectureBlock? _lectureAtCell(String day, String periodId) {
    try {
      return state.data.lectures.firstWhere(
        (l) {
          if (l.day != day) return false;
          if (l.startPeriodId == periodId) return true;
          // Check if this period is within a multi-span lecture
          final periods = state.data.periodsForDay(day);
          final startIdx = periods.indexWhere((p) => p.id == l.startPeriodId);
          final cellIdx = periods.indexWhere((p) => p.id == periodId);
          if (startIdx == -1 || cellIdx == -1) return false;
          return cellIdx >= startIdx && cellIdx < startIdx + l.spanPeriods;
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if a cell is occupied (by any lecture including multi-span).
  bool isCellOccupied(String day, String periodId) =>
      _lectureAtCell(day, periodId) != null;

  /// Gets the lecture occupying a cell, if any.
  LectureBlock? lectureAtCell(String day, String periodId) =>
      _lectureAtCell(day, periodId);
}
