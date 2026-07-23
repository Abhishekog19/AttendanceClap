import 'package:drift/drift.dart';

import '../database.dart';

/// Data-access object for [Subjects] counters and stats reads.
///
/// **PRIVATE to the local data layer** — do NOT inject into providers or UI.
/// All counter mutations must go through [AttendanceRepository], which owns
/// the business logic for when and how counters change.
///
/// This DAO contains ONLY raw reads and atomic counter increments/decrements.
/// No attendance calculation logic belongs here.
class SubjectsDao {
  final AppDatabase _db;

  const SubjectsDao(this._db);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Returns the subject row for [subjectId], or null if not found.
  Future<Subject?> getSubjectById(String subjectId) async {
    return (_db.select(_db.subjects)
          ..where((s) => s.id.equals(subjectId)))
        .getSingleOrNull();
  }

  /// Returns all subjects, ordered by creation time ascending.
  Future<List<Subject>> getAllSubjects() async {
    return (_db.select(_db.subjects)
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  /// Streams all subjects, ordered by name ascending.
  Stream<List<Subject>> watchAllSubjects() {
    return (_db.select(_db.subjects)
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .watch();
  }

  // ── Counter updates ────────────────────────────────────────────────────────

  /// Applies a signed delta to [subjectId]'s counters in one UPDATE.
  ///
  /// [attendedDelta] and [totalDelta] may be negative (for reversal).
  /// A zero delta on either field is a no-op for that field.
  ///
  /// This method must always be called inside the same transaction as the
  /// log insert/update/delete that triggered the counter change.
  Future<void> applyCounterDelta({
    required String subjectId,
    required int attendedDelta,
    required int totalDelta,
  }) async {
    if (attendedDelta == 0 && totalDelta == 0) return;

    // Drift doesn't have a built-in "increment by N" expression in 2.28.x,
    // so we read then write atomically within the caller's transaction.
    final subject = await getSubjectById(subjectId);
    if (subject == null) return;

    final newAttended =
        (subject.attendedClasses + attendedDelta).clamp(0, 999999);
    final newTotal = (subject.totalClasses + totalDelta).clamp(0, 999999);
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.subjects)..where((s) => s.id.equals(subjectId)))
        .write(SubjectsCompanion(
      attendedClasses: Value(newAttended),
      totalClasses: Value(newTotal),
      updatedAt: Value(now),
    ));
  }
}
