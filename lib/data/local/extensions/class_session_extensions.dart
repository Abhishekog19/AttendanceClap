/// Extension on the Drift-generated [ClassSession] data class.
///
/// Recreates every computed property that the Firestore [class_session_model.dart]
/// ClassSession model provided, using only the raw fields stored in the local
/// SQLite table.
///
/// ## Override-awareness
///
/// The Drift [ClassSession] table stores ONLY base timetable values — override
/// fields (overrideStartTime, overrideEndTime, overrideSubjectId, etc.) live in
/// the separate [DailyScheduleOverrides] table.
///
/// Override resolution is performed at the REPOSITORY JOIN layer:
///   [LocalAttendanceRepository.watchTodaySessionModels] pre-fetches all overrides
///   for today and embeds them into the returned [fs.ClassSession] (Firestore model
///   shape). That model's [displayStartTime] / [displayEndTime] are then correctly
///   override-aware for any provider or screen that consumes the enriched stream.
///
/// The extension properties [displayStartTime] and [displayEndTime] below return
/// the BASE times (i.e. the raw timetable values). Use them only when working
/// directly with a Drift [ClassSession] row that has NOT gone through the
/// repository override-join (e.g. in subject_detail_provider or session queries
/// that don't need override-awareness).
///
/// ## Computed properties provided by this extension
///   1. displayStartTime   — base start time (NOT override-aware; see note above)
///   2. displayEndTime     — base end time   (NOT override-aware; see note above)
///   3. isToday            — calendar date check
///   4. isPast             — session date before today
///   5. isCurrentlyInProgress — class actively running based on base times
///   6. hasEnded           — class end time has passed (or session not today)
///   7. hasNotStarted      — class start time not yet reached
///   8. isCancelledBool    — int (0/1) → bool
///   9. isExtraPeriodBool  — int (0/1) → bool
///  10. isStatusMarked     — status ≠ 'notMarked'
///  11. dateTime           — date int ms → DateTime

library;

import '../database.dart' show ClassSession;

extension ClassSessionX on ClassSession {
  // ── Base display values (NOT override-aware) ──────────────────────────────
  //
  // These return the raw timetable start/end times. For override-aware
  // times, use the repository-enriched fs.ClassSession stream from
  // LocalAttendanceRepository.watchTodaySessionModels — those instances
  // carry overrideStartTime / overrideEndTime and their displayStartTime
  // / displayEndTime are already resolved.

  /// Base start time "HH:MM" from the timetable entry. NOT override-aware.
  String get displayStartTime => startTime;

  /// Base end time "HH:MM" from the timetable entry. NOT override-aware.
  String get displayEndTime => endTime;

  // ── Boolean wrappers for Drift's int fields ───────────────────────────────

  /// Whether this session was cancelled for the day (Drift stores as 0/1).
  bool get isCancelledBool => isCancelled == 1;

  /// Whether this session is an extra period added outside the timetable.
  bool get isExtraPeriodBool => isExtraPeriod == 1;

  /// Whether attendance has been recorded (status ≠ 'notMarked').
  bool get isStatusMarked => status != 'notMarked';

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// The session date as a [DateTime] (Drift stores as millisecondsSinceEpoch).
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);

  /// True if this session's calendar date is today.
  bool get isToday {
    final now = DateTime.now();
    final d = dateTime;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// True if this session's calendar date is in the past (before today).
  bool get isPast {
    final today = DateTime.now();
    final d = dateTime;
    return d.year < today.year ||
        (d.year == today.year && d.month < today.month) ||
        (d.year == today.year &&
            d.month == today.month &&
            d.day < today.day);
  }

  // ── Time helpers ──────────────────────────────────────────────────────────

  static int _parseTimeMin(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// True if the class is currently in progress (startTime ≤ now < endTime, today only).
  bool get isCurrentlyInProgress {
    if (!isToday) return false;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    return nowMin >= _parseTimeMin(displayStartTime) &&
        nowMin < _parseTimeMin(displayEndTime);
  }

  /// True if the class end time has already passed (or the session is not today).
  bool get hasEnded {
    if (!isToday) return true; // past days are always "ended"
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    return nowMin >= _parseTimeMin(displayEndTime);
  }

  /// True if the class start time hasn't arrived yet (today only).
  bool get hasNotStarted {
    if (!isToday) return false;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    return nowMin < _parseTimeMin(displayStartTime);
  }
}
