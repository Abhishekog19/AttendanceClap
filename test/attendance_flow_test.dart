// ignore_for_file: avoid_print

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Drift-generated types — imported with prefix to avoid clash with Firestore
// model classes that share the same names (Semester, TimetableEntry).
import 'package:attendance_ai/data/local/database.dart' as drift_db;
import 'package:attendance_ai/data/repositories/local_attendance_repository.dart';

// Firestore model classes — unaliased so PredictorService receives the right
// types (PredictorService.computePredictions expects these, not Drift classes).
import 'package:attendance_ai/data/models/semester_model.dart';
import 'package:attendance_ai/data/models/timetable_entry_model.dart'
    show TimetableEntry;
import 'package:attendance_ai/features/predictor/providers/local_predictor_adapter.dart';
import 'package:attendance_ai/features/predictor/services/predictor_service.dart';

void main() {
  late drift_db.AppDatabase db;
  late LocalAttendanceRepository repo;

  // ── Fixture IDs ────────────────────────────────────────────────────────────
  const semesterId = 'sem-test-001';
  const subjectId = 'sub-test-001';
  const entryId = 'te-test-001';

  setUp(() async {
    db = drift_db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalAttendanceRepository(db);

    final now = DateTime.now().millisecondsSinceEpoch;

    // ── 1. Insert semester (Monday 2026-07-27 → Sunday 2026-08-02, 1 week) ──
    // This gives exactly 1 Monday in the range: 2026-07-27.
    final start = DateTime.utc(2026, 7, 27); // Monday
    final end = DateTime.utc(2026, 8, 2);   // Sunday
    await db.into(db.semesters).insert(
          drift_db.SemestersCompanion.insert(
            id: semesterId,
            startDate: start.millisecondsSinceEpoch,
            endDate: end.millisecondsSinceEpoch,
            createdAt: now,
          ),
        );

    // ── 2. Insert subject ──────────────────────────────────────────────────
    await db.into(db.subjects).insert(
          drift_db.SubjectsCompanion.insert(
            id: subjectId,
            name: 'Data Structures',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // ── 3. Insert timetable entry: every Monday ────────────────────────────
    await db.into(db.timetableEntries).insert(
          drift_db.TimetableEntriesCompanion.insert(
            id: entryId,
            subjectId: subjectId,
            semesterId: semesterId,
            dayOfWeek: 1, // Monday
            startTime: '09:00',
            endTime: '10:00',
            createdAt: now,
          ),
        );
  });

  tearDown(() async => db.close());

  // ── Assertion 1 + 2: session count and idempotency ─────────────────────────

  group('Assertion 1 — generateSessionsForSemester session count', () {
    test(
        'Generates exactly 1 session for a 1-week semester with 1 Monday entry',
        () async {
      final count = await repo.generateSessionsForSemester(semesterId);

      // Semester: Mon 2026-07-27 → Sun 2026-08-02.
      // Entry: every Monday → only 2026-07-27 qualifies.
      expect(count, equals(1),
          reason:
              'Expected exactly 1 session (one Monday in the 7-day window)');

      final sessions = await db.select(db.classSessions).get();
      expect(sessions.length, equals(1));
      expect(sessions.first.subjectId, equals(subjectId));
      expect(sessions.first.semesterId, equals(semesterId));
      expect(sessions.first.startTime, equals('09:00'));
    });
  });

  group('Assertion 2 — idempotency: no duplicates on second run', () {
    test('Running generateSessionsForSemester twice produces no new rows', () async {
      await repo.generateSessionsForSemester(semesterId);
      final secondCount = await repo.generateSessionsForSemester(semesterId);

      expect(secondCount, equals(0),
          reason:
              'Second run must return 0 — all sessions already exist '
              '(INSERT OR IGNORE skips duplicates)');

      final sessions = await db.select(db.classSessions).get();
      expect(sessions.length, equals(1),
          reason: 'Still exactly 1 session after second generation run');
    });
  });

  // ── Assertions 3 & 4: markAttendance and counters ──────────────────────────

  group('Assertions 3 & 4 — markAttendance counter tracking', () {
    late String sessionId;

    setUp(() async {
      // Generate the one session.
      await repo.generateSessionsForSemester(semesterId);
      final sessions = await db.select(db.classSessions).get();
      sessionId = sessions.first.id;
    });

    test(
        'Mark 5× present, 2× absent; counters reflect attended=5, total=7',
        () async {
      // We only have 1 session, so we simulate multiple marks by creating
      // additional session rows directly (representing different class days)
      // and calling markAttendance on each.

      // Helper: create a dummy session for subjectId on a given date.
      Future<String> addSession(int dateMs) async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final id = 'sess-${dateMs}';
        await db.into(db.classSessions).insert(
              drift_db.ClassSessionsCompanion.insert(
                id: id,
                subjectId: subjectId,
                semesterId: semesterId,
                date: dateMs,
                startTime: '09:00',
                endTime: '10:00',
                createdAt: now,
              ),
            );
        return id;
      }

      final base = DateTime.utc(2026, 7, 27).millisecondsSinceEpoch;
      // Create 7 sessions (1 already created by generator + 6 extra).
      final extraIds = <String>[];
      for (int i = 1; i <= 6; i++) {
        extraIds.add(await addSession(base + i * Duration.millisecondsPerDay));
      }

      // Sessions: first session (already created) + 6 extras = 7 total.
      // Mark 5 present.
      await repo.markAttendance(
          sessionId: sessionId, status: 'present', semesterId: semesterId);
      for (int i = 0; i < 4; i++) {
        await repo.markAttendance(
            sessionId: extraIds[i], status: 'present', semesterId: semesterId);
      }
      // Mark 2 absent.
      await repo.markAttendance(
          sessionId: extraIds[4], status: 'absent', semesterId: semesterId);
      await repo.markAttendance(
          sessionId: extraIds[5], status: 'absent', semesterId: semesterId);

      final subject =
          await (db.select(db.subjects)..where((s) => s.id.equals(subjectId)))
              .getSingle();

      // Assertion 3: 5 present → attended=5, total=5; 2 absent → total+2
      expect(subject.attendedClasses, equals(5),
          reason: 'present×5: attended must be 5');
      expect(subject.totalClasses, equals(7),
          reason: 'present×5 + absent×2: total must be 7');
    });
  });

  // ── Assertion 5: editAttendance delta, not double-count ───────────────────

  group('Assertion 5 — editAttendance uses signed delta', () {
    late String sessionId;

    setUp(() async {
      await repo.generateSessionsForSemester(semesterId);
      final sessions = await db.select(db.classSessions).get();
      sessionId = sessions.first.id;
    });

    test(
        'Edit one present → absent: attended decrements by 1, total unchanged',
        () async {
      // Mark present first.
      await repo.markAttendance(
          sessionId: sessionId, status: 'present', semesterId: semesterId);

      // Verify initial state: attended=1, total=1.
      var subject =
          await (db.select(db.subjects)..where((s) => s.id.equals(subjectId)))
              .getSingle();
      expect(subject.attendedClasses, 1);
      expect(subject.totalClasses, 1);

      // Find the log.
      final logs = await db.select(db.attendanceLogs).get();
      final logId = logs.first.id;

      // Edit to absent.
      await repo.editAttendance(logId: logId, newStatus: 'absent');

      subject =
          await (db.select(db.subjects)..where((s) => s.id.equals(subjectId)))
              .getSingle();

      // Assertion 5: present→absent delta: attended -1, total 0.
      // Net: attended=0, total=1.
      expect(subject.attendedClasses, equals(0),
          reason:
              'present→absent: attendedClasses must drop from 1 to 0 '
              '(delta = -1), not remain at 1 (which would indicate double-count)');
      expect(subject.totalClasses, equals(1),
          reason:
              'present→absent: totalClasses must stay 1 '
              '(delta: remove present (-1 total), add absent (+1 total) = net 0)');
    });
  });

  // ── Assertion 6: predictor adapter output ─────────────────────────────────

  group('Assertion 6 — predictor adapter output matches manual calculation',
      () {
    late String sessionId;

    setUp(() async {
      await repo.generateSessionsForSemester(semesterId);
      final sessions = await db.select(db.classSessions).get();
      sessionId = sessions.first.id;
    });

    test('Adapter produces SubjectModel matching DB counters; predictor output '
        'matches manual computation', () async {
      // Mark: 3 present, 1 absent (4 total, attended = 3).
      // We need 4 sessions — create 3 extras.
      Future<String> addSession(int offsetDays) async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final dateMs = DateTime.utc(2026, 7, 28 + offsetDays)
            .millisecondsSinceEpoch;
        final id = 'sess-p6-$offsetDays';
        await db.into(db.classSessions).insert(
              drift_db.ClassSessionsCompanion.insert(
                id: id,
                subjectId: subjectId,
                semesterId: semesterId,
                date: dateMs,
                startTime: '09:00',
                endTime: '10:00',
                createdAt: now,
              ),
            );
        return id;
      }

      final s2 = await addSession(0);
      final s3 = await addSession(1);
      final s4 = await addSession(2);

      await repo.markAttendance(
          sessionId: sessionId, status: 'present', semesterId: semesterId);
      await repo.markAttendance(
          sessionId: s2, status: 'present', semesterId: semesterId);
      await repo.markAttendance(
          sessionId: s3, status: 'present', semesterId: semesterId);
      await repo.markAttendance(
          sessionId: s4, status: 'absent', semesterId: semesterId);

      // Verify DB counters: attended=3, total=4.
      final dbSubject =
          await (db.select(db.subjects)..where((s) => s.id.equals(subjectId)))
              .getSingle();
      expect(dbSubject.attendedClasses, equals(3));
      expect(dbSubject.totalClasses, equals(4));

      // Run adapter.
      final adapter = LocalPredictorAdapter(repo);
      final subjects = await adapter.getSubjectsForPredictor();

      expect(subjects.length, equals(1));
      expect(subjects.first.id, equals(subjectId));
      expect(subjects.first.attendedClasses, equals(3));
      expect(subjects.first.totalClasses, equals(4));

      // Feed through PredictorService.computePredictions with a dummy semester
      // and no timetable entries (no remaining classes → remaining = 0).
      //
      // Manual calculation:
      //   currentPct = 3/4 × 100 = 75.0%
      //   safeBunks  = floor(3 / 0.75) - 4 = floor(4.0) - 4 = 0
      //   classesNeeded = 0 (already at 75%)
      const goal = 75.0;
      final dummySemester = Semester(
        id: semesterId,
        uid: 'test',
        startDate: DateTime.utc(2026, 7, 27),
        endDate: DateTime.utc(2026, 8, 2),
        createdAt: DateTime.utc(2026, 7, 1),
      );

      final predictions = PredictorService.computePredictions(
        subjects: subjects,
        entries: const <TimetableEntry>[],
        semester: dummySemester,
        goal: goal,
      );

      expect(predictions.length, equals(1));
      final pred = predictions.first;

      // Assertion 6: verify predictor output matches manual calculation.
      expect(pred.currentPct, closeTo(75.0, 0.001),
          reason: '3 attended / 4 total = 75.0%');
      expect(pred.safeBunks, equals(0),
          reason:
              'floor(3/0.75) - 4 = floor(4) - 4 = 0 safe bunks at exactly 75%');
      expect(pred.classesNeeded, equals(0),
          reason: 'Already at goal — no classes needed');

      print(
          '✓ Predictor: currentPct=${pred.currentPct.toStringAsFixed(1)}% '
          'safeBunks=${pred.safeBunks} classesNeeded=${pred.classesNeeded}');
    });
  });
}
