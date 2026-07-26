import 'package:drift/drift.dart';

import '../database.dart';

/// Data-access object for [DailyScheduleOverrides].
///
/// **PRIVATE to the local data layer** — callers must go through
/// [LocalAttendanceRepository], never this DAO directly.
///
/// Responsibilities: insert, replace, delete, and query override rows.
/// No counter adjustments, no business rules.
class DailyOverridesDao {
  final AppDatabase _db;

  const DailyOverridesDao(this._db);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Returns all overrides for [dateMidnightMs], ordered by creation time.
  Future<List<DailyScheduleOverride>> getOverridesForDate(
      int dateMidnightMs) async {
    return (_db.select(_db.dailyScheduleOverrides)
          ..where((o) => o.date.equals(dateMidnightMs))
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
        .get();
  }

  /// Returns the override row for [sessionId], or null if none exists.
  Future<DailyScheduleOverride?> getOverrideForSession(
      String sessionId) async {
    return (_db.select(_db.dailyScheduleOverrides)
          ..where((o) => o.sessionId.equals(sessionId))
          ..limit(1))
        .getSingleOrNull();
  }

  // ── Insert / replace ───────────────────────────────────────────────────────

  /// Inserts or replaces the override for this session.
  ///
  /// The [DailyScheduleOverrides] table has a UNIQUE constraint on [sessionId],
  /// so inserting a second override for the same session replaces the first.
  Future<void> insertOrReplace(DailyScheduleOverridesCompanion companion) =>
      _db
          .into(_db.dailyScheduleOverrides)
          .insertOnConflictUpdate(companion);

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Hard-deletes the override row by [id].
  Future<void> deleteById(String id) =>
      (_db.delete(_db.dailyScheduleOverrides)
            ..where((o) => o.id.equals(id)))
          .go();

  /// Hard-deletes the override row for [sessionId] (if any).
  Future<void> deleteForSession(String sessionId) =>
      (_db.delete(_db.dailyScheduleOverrides)
            ..where((o) => o.sessionId.equals(sessionId)))
          .go();
}
