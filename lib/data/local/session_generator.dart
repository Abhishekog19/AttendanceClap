import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

/// Expands [TimetableEntries] into [ClassSessions] for an entire semester.
///
/// **INTERNAL** — call only from [LocalAttendanceRepository] or an onboarding
/// service. Never call directly from providers or UI.
///
/// ## Idempotency
///
/// Idempotency is achieved by collecting all already-existing
/// `(timetable_entry_id, date)` pairs **in a single query** at the start of
/// the transaction, then skipping insertion for any pair already in that set.
///
/// This is preferred over INSERT OR IGNORE because drift 2.28.x's `uniqueKeys`
/// table override does not emit a SQL UNIQUE constraint in the CREATE TABLE DDL
/// (it is used for query-building metadata only). A pre-fetch set check is
/// therefore the reliable, version-safe approach:
///   1. O(1) set lookup per candidate row.
///   2. No extra round-trip per session — one bulk fetch at start.
///   3. Race-condition-safe within the outer transaction.
///   4. Clear and easy to test.
class SessionGenerator {
  final AppDatabase _db;
  static const _uuid = Uuid();

  const SessionGenerator(this._db);

  /// Generates class_sessions for every timetable entry belonging to
  /// [semesterId].
  ///
  /// Expansion rules (identical to the legacy [SemesterModel.getDatesForWeekday]):
  ///   - Walk `semester.start_date` → `semester.end_date` (both **inclusive**).
  ///   - Emit a session when: `date.weekday == entry.day_of_week` AND
  ///     `date` is NOT in `semester_holidays`.
  ///   - Every session's `semester_id` is copied from the entry (never inferred).
  ///   - All writes are in **one atomic transaction**.
  ///
  /// Returns the count of sessions newly inserted (0 on a no-op re-run when
  /// all rows already existed).
  Future<int> generateSessionsForSemester(String semesterId) async {
    return _db.transaction<int>(() async {
      // ── 1. Fetch semester bounds ───────────────────────────────────────────
      final semester = await (_db.select(_db.semesters)
            ..where((s) => s.id.equals(semesterId)))
          .getSingleOrNull();
      if (semester == null) return 0;

      final startDate = DateTime.fromMillisecondsSinceEpoch(
          semester.startDate,
          isUtc: true);
      final endDate = DateTime.fromMillisecondsSinceEpoch(
          semester.endDate,
          isUtc: true);

      // ── 2. Load holiday set (midnight UTC ms → fast O(1) lookup) ──────────
      final holidays = await (_db.select(_db.semesterHolidays)
            ..where((h) => h.semesterId.equals(semesterId)))
          .get();
      final holidaySet = {for (final h in holidays) h.holidayDate};

      // ── 3. Load timetable entries for this semester ────────────────────────
      final entries = await (_db.select(_db.timetableEntries)
            ..where((t) => t.semesterId.equals(semesterId)))
          .get();
      if (entries.isEmpty) return 0;

      // ── 4. Pre-fetch existing (timetable_entry_id, date) pairs ────────────
      // This single bulk fetch powers the idempotency check (O(1) per row).
      final existing = await (_db.select(_db.classSessions)
            ..where((s) => s.semesterId.equals(semesterId)))
          .get();
      final existingPairs = <String>{};
      for (final s in existing) {
        if (s.timetableEntryId != null) {
          existingPairs.add('${s.timetableEntryId}:${s.date}');
        }
      }

      // ── 5. Expand entries into sessions, skipping existing pairs ───────────
      int inserted = 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in entries) {
        var current = startDate;
        while (!current.isAfter(endDate)) {
          if (current.weekday == entry.dayOfWeek) {
            final midnight =
                DateTime.utc(current.year, current.month, current.day)
                    .millisecondsSinceEpoch;

            if (!holidaySet.contains(midnight)) {
              final pairKey = '${entry.id}:$midnight';
              if (!existingPairs.contains(pairKey)) {
                await _db.into(_db.classSessions).insert(
                      ClassSessionsCompanion.insert(
                        id: _uuid.v4(),
                        subjectId: entry.subjectId,
                        semesterId: entry.semesterId,
                        timetableEntryId: Value(entry.id),
                        date: midnight,
                        startTime: entry.startTime,
                        endTime: entry.endTime,
                        faculty: Value(entry.faculty),
                        room: Value(entry.room),
                        createdAt: now,
                      ),
                    );
                existingPairs.add(pairKey); // guard against duplicate entries
                inserted++;
              }
            }
          }
          current = current.add(const Duration(days: 1));
        }
      }

      return inserted;
    });
  }
}
