import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../data/models/semester_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../../data/repositories/timetable_repository.dart';

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
  Future<String> saveSubject({
    required String name,
    String? faculty,
    double? attendanceTarget,
    int attendedClasses = 0,
    int totalClasses = 0,
    String? existingId,
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
      );
      await _db.updateSubject(_uid, updated);
      return id;
    }
    final subject = SubjectModel(
      id: id,
      name: name,
      attendedClasses: attendedClasses,
      totalClasses: totalClasses,
      faculty: faculty,
      createdAt: createdAt,
      updatedAt: now,
      attendanceTarget: attendanceTarget,
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

  // ─── Timetable Builder ────────────────────────────────────────────────────

  /// Adds a single timetable entry. Returns the Firestore document ID.
  Future<String> addTimetableEntry({
    required String subjectId,
    required String subjectName,
    required String day,
    required String startTime,
    required String endTime,
    String? faculty,
    String? room,
  }) async {
    final entry = TimetableEntry(
      subjectId: subjectId,
      subject: subjectName,
      day: day,
      startTime: startTime,
      endTime: endTime,
      faculty: faculty,
      room: room,
      confidence: 1.0,
    );
    return _timetableRepo.addTimetableEntry(entry);
  }

  Future<void> deleteTimetableEntry(String entryId) =>
      _timetableRepo.deleteTimetableEntry(entryId);

  Stream<List<TimetableEntry>> watchTimetableEntries() =>
      _timetableRepo.watchTimetableEntries();

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
  /// AttendanceLogModel(status=absent) per absent date per timetable slot.
  /// Log IDs are derived from subjectId+date+startTime so retries are idempotent.
  Future<void> saveAbsentDates({
    required Map<String, List<DateTime>> absentDatesBySubject,
    required List<TimetableEntry> timetableEntries,
    required Map<String, String> subjectIdToName,
  }) async {
    final logs = <AttendanceLogModel>[];

    absentDatesBySubject.forEach((subjectId, dates) {
      final subjectName = subjectIdToName[subjectId] ?? '';
      final entries =
          timetableEntries.where((e) => e.subjectId == subjectId).toList();

      for (final date in dates) {
        final dayName = _weekdayName(date.weekday);
        final dayEntries = entries.where((e) => e.day == dayName).toList();
        for (final entry in dayEntries) {
          // Use a stable ID so repeated calls don't create duplicate logs.
          final dateStr =
              '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
          final stableId = '${subjectId}_${dateStr}_${entry.startTime.replaceAll(':', '')}';
          logs.add(AttendanceLogModel(
            id: stableId,
            subjectId: subjectId,
            subjectName: subjectName,
            status: AttendanceStatus.absent,
            date: date,
            startTime: entry.startTime,
            endTime: entry.endTime,
          ));
        }
      }
    });

    await _db.saveOnboardingAttendanceLogs(_uid, logs);
  }

  // ─── Review / Finalize ────────────────────────────────────────────────────

  /// Generates class_sessions from the saved timetable + active semester.
  /// Called when the user confirms on the Review screen.
  Future<void> generateClassSessions() async {
    final semester = await _timetableRepo.getActiveSemester();
    if (semester == null) return;

    final entries = await _timetableRepo.watchTimetableEntries().first;
    if (entries.isEmpty) return;

    // Build name→id map from existing timetable entries (subjectId already set)
    final subjectIdMap = <String, String>{};
    for (final e in entries) {
      if (e.subjectId != null) {
        subjectIdMap[e.subject] = e.subjectId!;
      }
    }

    await _timetableRepo.deleteAllSessions();
    await _timetableRepo.saveClassSessions(
      entries: entries,
      semester: semester,
      subjectIdMap: subjectIdMap,
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
