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
///
/// ⚠️  Phase 3 note: auth has been removed. _uid is always '' in this build.
/// Every method that requires a Firestore document path guards against an empty
/// uid and returns early (no-op) so the app never throws
/// "document path must be a non-empty string".
/// Full local-DB replacement of this class is planned for Phase 4.
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

  // ─── Guard helper ─────────────────────────────────────────────────────────

  /// True when uid is missing — all Firestore calls must no-op in this case.
  bool get _noAuth => _uid.isEmpty;

  // ─── Step tracking ────────────────────────────────────────────────────────

  Future<void> saveStep(String stepKey) async {
    if (_noAuth) return; // Phase 3 guard — no uid, skip Firestore write
    await _db.updateOnboardingStep(_uid, stepKey);
  }

  Future<void> markComplete() async {
    if (_noAuth) return; // Phase 3 guard
    await _db.setOnboardingComplete(_uid);
  }

  // ─── College Details ──────────────────────────────────────────────────────

  Future<void> saveCollegeDetails({
    required String collegeName,
    required String courseName,
    String? year,
    String? section,
  }) async {
    if (_noAuth) return; // Phase 3 guard
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'collegeName': collegeName,
      'courseName': courseName,
      if (year != null && year.isNotEmpty) 'year': year,
      if (section != null && section.isNotEmpty) 'section': section,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Semester Setup ───────────────────────────────────────────────────────

  /// Saves the semester and returns a generated ID.
  /// Returns a UUID even when no-auth so callers always receive a non-null id.
  Future<String> saveSemester({
    required DateTime startDate,
    required DateTime endDate,
    required String semesterName,
    required double attendanceGoal,
    List<DateTime> holidays = const [],
  }) async {
    final id = _uuid.v4();
    if (_noAuth) return id; // Phase 3 guard — return id, skip Firestore

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
    final id = existingId ?? _uuid.v4();
    if (_noAuth) return id; // Phase 3 guard — return id, skip Firestore

    final now = DateTime.now();
    DateTime createdAt = now;
    if (existingId != null) {
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
    final existingSubjects = await _db.getSubjects(_uid);
    final usedColors = existingSubjects
        .where((s) => s.colorHex != null)
        .map((s) => s.colorHex!)
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

  Future<void> deleteSubject(String subjectId) async {
    if (_noAuth) return; // Phase 3 guard
    await _db.deleteSubject(_uid, subjectId);
  }

  Future<List<SubjectModel>> getSubjects() async {
    if (_noAuth) return []; // Phase 3 guard
    return _db.getSubjects(_uid);
  }

  Stream<List<SubjectModel>> watchSubjects() {
    if (_noAuth) return const Stream.empty(); // Phase 3 guard
    return _db.watchSubjects(_uid);
  }

  /// Returns the active semester ID, or null.
  Future<String?> getActiveSemesterId() async {
    if (_noAuth) return null; // Phase 3 guard
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

  // ─── Holiday Calendar ─────────────────────────────────────────────────────

  Future<void> updateHolidays(String semesterId, List<DateTime> holidays) async {
    if (_noAuth) return; // Phase 3 guard
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

  Future<void> saveManualCounts(
    Map<String, ({int attended, int total})> counts,
  ) async {
    if (_noAuth) return; // Phase 3 guard
    await _db.saveOnboardingManualCounts(_uid, counts);
  }

  Future<void> saveAbsentDates({
    required Map<String, List<DateTime>> absentDatesBySubject,
    required Map<String, String> subjectIdToName,
  }) async {
    if (_noAuth) return; // Phase 3 guard

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

  Future<void> generateClassSessions() async {
    if (_noAuth) return; // Phase 3 guard
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
