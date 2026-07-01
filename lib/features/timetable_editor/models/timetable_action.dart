/// Timetable Editor — Undo/Redo Action Stack
///
/// Every mutation that should be undoable is represented as a sealed class.
/// The TimetableEditorNotifier holds two stacks: _undoStack and _redoStack.
/// Undo replays the inverse action; Redo replays the forward action.
/// The stack lives entirely in local Riverpod state — never in Firestore.

import 'timetable_editor_models.dart';

// ─── Sealed base class ────────────────────────────────────────────────────────

sealed class TimetableAction {
  const TimetableAction();
}

// ─── Place a lecture ─────────────────────────────────────────────────────────

/// Undo: delete the placed lecture.
/// Redo: re-place the same lecture (same ID).
class PlaceLectureAction extends TimetableAction {
  final LectureBlock placed;
  const PlaceLectureAction(this.placed);
}

// ─── Delete a lecture ─────────────────────────────────────────────────────────

/// Undo: re-place the deleted lecture (same ID, same position).
/// Redo: delete it again.
class DeleteLectureAction extends TimetableAction {
  final LectureBlock deleted;
  const DeleteLectureAction(this.deleted);
}

// ─── Move a lecture ───────────────────────────────────────────────────────────

/// Undo: move back to original position.
/// Redo: move to new position.
class MoveLectureAction extends TimetableAction {
  final LectureBlock before; // original position
  final LectureBlock after;  // new position (same ID)
  const MoveLectureAction({required this.before, required this.after});
}

// ─── Update a lecture (duration / faculty / classroom / notes) ────────────────

/// Undo: restore previous values.
/// Redo: apply new values.
class UpdateLectureAction extends TimetableAction {
  final LectureBlock before;
  final LectureBlock after;
  const UpdateLectureAction({required this.before, required this.after});
}

// ─── Copy day schedule ────────────────────────────────────────────────────────

/// Undo: delete all lectures that were copied (restore toDay to empty or prior state).
/// Redo: re-copy.
class CopyDayAction extends TimetableAction {
  final String fromDay;
  final String toDay;
  final List<LectureBlock> addedLectures; // lectures that were newly placed
  final List<LectureBlock> removedLectures; // lectures that were displaced (if any)
  const CopyDayAction({
    required this.fromDay,
    required this.toDay,
    required this.addedLectures,
    required this.removedLectures,
  });
}

// ─── Copy day to multiple targets ────────────────────────────────────────────

/// Same as CopyDayAction but for the "Mon–Fri" shortcut.
class CopyDayToRangeAction extends TimetableAction {
  final String fromDay;
  final List<String> toDays;
  final List<LectureBlock> addedLectures;
  final List<LectureBlock> removedLectures;
  const CopyDayToRangeAction({
    required this.fromDay,
    required this.toDays,
    required this.addedLectures,
    required this.removedLectures,
  });
}

// ─── Timing change ────────────────────────────────────────────────────────────

/// Undo: restore previous schedule (default or day-specific).
/// Redo: apply new schedule.
class TimingChangeAction extends TimetableAction {
  final List<PeriodSlot> beforeDefault;
  final List<PeriodSlot> afterDefault;
  final Map<String, DaySchedule> beforeDaySchedules;
  final Map<String, DaySchedule> afterDaySchedules;
  const TimingChangeAction({
    required this.beforeDefault,
    required this.afterDefault,
    required this.beforeDaySchedules,
    required this.afterDaySchedules,
  });
}
