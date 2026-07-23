import 'package:drift/drift.dart';
import 'semesters_table.dart';

/// Table: semester_holidays
///
/// Join table — one row per holiday date within a semester.
/// Replaces the holidays List<DateTime> stored as a Firestore array.
/// Unique constraint on (semester_id, holiday_date) prevents duplicates.
///
/// FK: semester_id → semesters.id  ON DELETE CASCADE
///   (holidays only make sense within their semester)
@TableIndex(name: 'idx_sh_semester_date', columns: {#semesterId, #holidayDate})
class SemesterHolidays extends Table {
  /// Auto-increment surrogate PK. No UUID needed for this join table.
  IntColumn get id => integer().autoIncrement()();

  /// FK → semesters.id, ON DELETE CASCADE.
  TextColumn get semesterId =>
      text().references(Semesters, #id, onDelete: KeyAction.cascade)();

  /// Holiday date — Unix timestamp (ms), midnight UTC.
  IntColumn get holidayDate => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {semesterId, holidayDate},
      ];
}
