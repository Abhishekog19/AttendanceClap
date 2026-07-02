import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../data/models/semester_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../features/timetable_editor/models/timetable_editor_models.dart';
import '../../../features/timetable_editor/repository/timetable_editor_repository.dart';

/// Orchestrates all Firestore writes during the onboarding flow.
///
/// All onboarding persistence goes through this class so screens/providers stay
/// thin. Each method is idempotent (safe to call on resume/retry).
class OnboardingRepository {
  final FirestoreDatasource _db;
  final TimetableRepository _timetableRepo;
  final String _uid;
  final _uuid = const Uuid();

  OnboardingRepository({
    required FirestoreDatasource db,
    required TimetableRepository timetableRepo,
    required String uid,
  })  : _db = db,
        _timetableRepo = timetableRepo,
        _uid = uid;

  // ─── Step tracking ────────────────────────────────────────────────────────

  Future<void> saveStep(String stepKey) =>
      _db.updateOnboardingStep(_uid, stepKey);

  Future<void> markComplete() => _db.setOnboardingComplete(_uid);

  // ─── College Details ─────────────────────────────────────────────────────

  Future<void> saveCollegeDetails({
    required String collegeName,
    required String courseName,
    String? year,
    String? section,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'collegeName': collegeName,
      'courseName': courseName,
      if (year != null && year.isNotEmpty) 'year': year,
      if (section != null && section.isNotEmpty) 'section': section,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Semester Setup ───────────────────────────────────────────────────────

  /// Saves the semester doc and updates the global attendance goal on user profile.
  /// Returns the semester ID so callers can reference it (e.g. for holiday updates).
  Future<String> saveSemester({
    required DateTime startDate,
    required DateTime endDate,
    required String semesterName,
    required double attendanceGoal,
    List<DateTime> holidays = const [],
  }) async {
    final id = _uuid.v4();
    final semester = Semester(
      id: id,
      uid: _uid,
      startDate: startDate,
      endDate: endDate,
      holidays: holidays,
      createdAt: DateTime.now(),
      semesterName: semesterName,
    );
    await _timetableRepo.saveSemester(semester);
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'attendanceGoal': attendanceGoal,
      'semesterName': semesterName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return id;
  }

  // ─── Subject Setup ────────────────────────────────────────────────────────

  /// Writes a single subject to Firestore. Safe to call multiple times (sets doc).
  /// Auto-assigns [colorHex] and [shortName] on first creation if not provided.
  Future<String> saveSubject({
    required String name,
    String? faculty,
    double? attendanceTarget,
    int attendedClasses = 0,
    int totalClasses = 0,
    String? existingId,
    String? colorHex,
    String? shortName,
  }) async {
    final now = DateTime.now();
    final id = existingId ?? _uuid.v4();
    DateTime createdAt = now;
    if (existingId != null) {
      // Preserve the original creation timestamp so sort order is stable.
      final existing = await _db.getSubjectById(_uid, existingId);
      if (existing != null) {
        createdAt = existing.createdAt;
        attendedClasses = existing.attendedClasses;
        totalClasses = existing.totalClasses;
      }
      final updated = SubjectModel(
        id: id,
        name: name,
        attendedClasses: attendedClasses,
        totalClasses: totalClasses,
        faculty: faculty,
        createdAt: createdAt,
        updatedAt: now,
        attendanceTarget: attendanceTarget,
        colorHex: colorHex ?? existing?.colorHex,
        shortName: shortName ?? existing?.shortName,
      );
      await _db.updateSubject(_uid, updated);
      return id;
    }
    // Auto-assign color from palette (based on current subject count)
    final existingSubjects = await _db.getSubjects(_uid);
    final usedColors = existingSubjects
        .map((s) => s.effectiveColorHex)
        .toList();
    final assignedColor = colorHex ?? nextSubjectColor(usedColors);
    final assignedShortName = shortName ?? generateSubjectShortName(name);

    final subject = SubjectModel(
      id: id,
      name: name,
      attendedClasses: attendedClasses,
      totalClasses: totalClasses,
      faculty: faculty,
      createdAt: createdAt,
      updatedAt: now,
      attendanceTarget: attendanceTarget,
      colorHex: assignedColor,
      shortName: assignedShortName,
    );
    await _db.addSubject(_uid, subject);
    return id;
  }

  Future<void> deleteSubject(String subjectId) =>
      _db.deleteSubject(_uid, subjectId);

  Future<List<SubjectModel>> getSubjects() => _db.getSubjects(_uid);

  Stream<List<SubjectModel>> watchSubjects() => _db.watchSubjects(_uid);

  /// Returns the Firestore document ID of the most recently created semester,
  /// or null if none exists. Used by restoreFromFirestore to rehydrate semesterId.
  Future<String?> getActiveSemesterId() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('semesters')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  // ─── Timetable (delegates to timetable/config/lectures) ──────────────────
  // No direct timetable_entries writes — the TimetableEditorNotifier handles
  // all lecture CRUD via /users/{uid}/timetable/config/lectures.

  // ─── Holiday Calendar ─────────────────────────────────────────────────────

  /// Overwrites the holidays list on the active semester document.
  Future<void> updateHolidays(String semesterId, List<DateTime> holidays) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('semesters')
        .doc(semesterId)
        .update({
      'holidays': holidays.map((d) => Timestamp.fromDate(d)).toList(),
    });
  }

  // ─── Attendance Import ────────────────────────────────────────────────────

  /// Method A: manually entered attended/total counts.
  /// Directly sets counters without creating individual log records.
  Future<void> saveManualCounts(
    Map<String, ({int attended, int total})> counts,
  ) =>
      _db.saveOnboardingManualCounts(_uid, counts);

  /// Method B: mark absent dates → derive absent logs from timetable.
  ///
  /// For each subject in [absentDatesBySubject], generates one
  /// AttendanceLogModel(status=absent) per absent date per lecture slot.
  /// Reads lecture blocks directly from Firestore (timetable/config/lectures).
  /// Log IDs are derived from subjectId+date+startTime so retries are idempotent.
  Future<void> saveAbsentDates({
    required Map<String, List<DateTime>> absentDatesBySubject,
    required Map<String, String> subjectIdToName,
  }) async {
    // Read lectures from the canonical source
    final editorRepo = TimetableEditorRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    final lectures = await editorRepo.watchLectures().first;
    final logs = <AttendanceLogModel>[];

    absentDatesBySubject.forEach((subjectId, dates) {
      final subjectName = subjectIdToName[subjectId] ?? '';
      final subjectLectures =
          lectures.where((l) => l.subjectId == subjectId).toList();

      for (final date in dates) {
        final dayAbbr = kDayAbbreviations[_weekdayName(date.weekday)] ?? '';
        final dayLectures =
            subjectLectures.where((l) => l.day == dayAbbr).toList();
        for (final lecture in dayLectures) {
          final dateStr =
              '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
          final stableId =
              '${subjectId}_${dateStr}_${lecture.startTime.replaceAll(':', '')}';
          logs.add(AttendanceLogModel(
            id: stableId,
            subjectId: subjectId,
            subjectName: subjectName,
            status: AttendanceStatus.absent,
            date: date,
            startTime: lecture.startTime,
            endTime: lecture.endTime,
          ));
        }
      }
    });

    await _db.saveOnboardingAttendanceLogs(_uid, logs);
  }

  // ─── Review / Finalize ────────────────────────────────────────────────────

  /// Generates class_sessions from the saved timetable + active semester.
  /// Reads LectureBlocks from /users/{uid}/timetable/config/lectures.
  /// Called when the user confirms on the Review screen.
  Future<void> generateClassSessions() async {
    final semester = await _timetableRepo.getActiveSemester();
    if (semester == null) return;

    final editorRepo = TimetableEditorRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    final lectures = await editorRepo.watchLectures().first;
    if (lectures.isEmpty) return;

    await _timetableRepo.deleteAllSessions();
    await _timetableRepo.saveClassSessions(
      lectures: lectures,
      semester: semester,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _weekdayName(int weekday) {
    const names = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return names[weekday.clamp(1, 7)];
  }
}
