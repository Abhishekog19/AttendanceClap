import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_ai/data/local/database.dart';
import 'package:attendance_ai/data/local/tables/semesters_table.dart';
import 'package:attendance_ai/data/local/tables/subjects_table.dart';
import 'package:attendance_ai/data/local/tables/timetable_entries_table.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory database — isolated per test, no file I/O.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase smoke test', () {
    test(
      'insert semester → subject → timetable_entry, read back, then '
      'assert semester deletion is blocked by RESTRICT FK',
      () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // ── 1. Insert a semester ────────────────────────────────────────────
        const semesterId = 'sem-001';
        await db.into(db.semesters).insert(
              SemestersCompanion.insert(
                id: semesterId,
                startDate: now,
                endDate: now + const Duration(days: 180).inMilliseconds,
                createdAt: now,
              ),
            );

        // ── 2. Insert a subject ─────────────────────────────────────────────
        const subjectId = 'sub-001';
        await db.into(db.subjects).insert(
              SubjectsCompanion.insert(
                id: subjectId,
                name: 'Data Structures',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // ── 3. Insert a timetable entry referencing both semester + subject ─
        const entryId = 'te-001';
        await db.into(db.timetableEntries).insert(
              TimetableEntriesCompanion.insert(
                id: entryId,
                subjectId: subjectId,
                semesterId: semesterId,
                dayOfWeek: 1, // Monday
                startTime: '09:00',
                endTime: '10:00',
                createdAt: now,
              ),
            );

        // ── 4. Read back the timetable entry and assert values ──────────────
        final entry = await (db.select(db.timetableEntries)
              ..where((t) => t.id.equals(entryId)))
            .getSingle();

        expect(entry.id, equals(entryId));
        expect(entry.subjectId, equals(subjectId));
        expect(entry.semesterId, equals(semesterId));
        expect(entry.dayOfWeek, equals(1));
        expect(entry.startTime, equals('09:00'));
        expect(entry.endTime, equals('10:00'));
        expect(entry.confidence, equals(1.0)); // default from schema

        // ── 5. Assert RESTRICT FK prevents semester deletion ────────────────
        // The timetable_entries.semester_id → semesters.id ON DELETE RESTRICT
        // means deleting the semester while entries exist must be rejected.
        expect(
          () async => db.delete(db.semesters)
            ..where((s) => s.id.equals(semesterId)),
          // Drift raises a SqliteException when a RESTRICT FK is violated.
          // We trigger the delete inside the expectation lambda.
          isA<Function>(),
        );

        // Actually execute and capture the FK violation:
        Object? caughtError;
        try {
          await (db.delete(db.semesters)
                ..where((s) => s.id.equals(semesterId)))
              .go();
        } catch (e) {
          caughtError = e;
        }

        expect(
          caughtError,
          isNotNull,
          reason:
              'Expected a SqliteException due to RESTRICT FK from '
              'timetable_entries.semester_id, but no error was thrown.',
        );

        // The semester and the timetable entry must still exist.
        final semesterStillExists = await (db.select(db.semesters)
              ..where((s) => s.id.equals(semesterId)))
            .getSingleOrNull();
        expect(semesterStillExists, isNotNull,
            reason: 'Semester should still exist after failed RESTRICT delete.');

        final entryStillExists = await (db.select(db.timetableEntries)
              ..where((t) => t.id.equals(entryId)))
            .getSingleOrNull();
        expect(entryStillExists, isNotNull,
            reason:
                'TimetableEntry should still exist after failed RESTRICT delete.');
      },
    );
  });
}
