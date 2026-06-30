import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../repositories/onboarding_repository.dart';
import 'onboarding_state.dart';

part 'onboarding_notifier.g.dart';

// ─── OnboardingRepository provider ────────────────────────────────────────────

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  final uid = ref.watch(currentUserProvider)?.uid ?? '';
  return OnboardingRepository(
    db: ref.watch(firestoreDatasourceProvider),
    timetableRepo: ref.watch(timetableRepositoryProvider),
    uid: uid,
  );
}

// ─── OnboardingNotifier ───────────────────────────────────────────────────────

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);

  // ─── Step navigation ──────────────────────────────────────────────────────

  void goToStep(String step) =>
      state = state.copyWith(currentStep: step, error: null);

  Future<void> advanceStep(String completedStep) async {
    final next = OnboardingStep.nextStep(completedStep);
    state = state.copyWith(currentStep: next ?? completedStep, error: null);
    await _repo.saveStep(completedStep);
  }

  // ─── College Details ──────────────────────────────────────────────────────

  void setCollegeName(String v) =>
      state = state.copyWith(collegeName: v, error: null);
  void setCourseName(String v) =>
      state = state.copyWith(courseName: v, error: null);
  void setYear(String v) => state = state.copyWith(year: v);
  void setSection(String v) => state = state.copyWith(section: v);

  Future<bool> saveCollegeDetails() async {
    if (!state.collegeValid) {
      state = state.copyWith(error: 'College name and course are required.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.saveCollegeDetails(
        collegeName: state.collegeName.trim(),
        courseName: state.courseName.trim(),
        year: state.year.trim(),
        section: state.section.trim(),
      );
      await advanceStep(OnboardingStep.college);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Semester Setup ───────────────────────────────────────────────────────

  void setSemesterName(String v) =>
      state = state.copyWith(semesterName: v, error: null);
  void setSemesterStart(DateTime d) =>
      state = state.copyWith(semesterStart: d, error: null);
  void setSemesterEnd(DateTime d) =>
      state = state.copyWith(semesterEnd: d, error: null);
  void setAttendanceGoal(double v) => state = state.copyWith(attendanceGoal: v);

  Future<bool> saveSemester() async {
    if (!state.semesterValid) {
      state = state.copyWith(
          error: 'Please fill in semester name and valid start/end dates.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _repo.saveSemester(
        startDate: state.semesterStart!,
        endDate: state.semesterEnd!,
        semesterName: state.semesterName.trim(),
        attendanceGoal: state.attendanceGoal,
        holidays: state.holidays,
      );
      state = state.copyWith(semesterId: id, isLoading: false);
      await advanceStep(OnboardingStep.semester);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Subject Setup ────────────────────────────────────────────────────────

  Future<void> addSubject({
    required String name,
    String? faculty,
    double? attendanceTarget,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _repo.saveSubject(
        name: name.trim(),
        faculty: faculty?.trim(),
        attendanceTarget: attendanceTarget,
      );
      final subject = SubjectModel(
        id: id,
        name: name.trim(),
        attendedClasses: 0,
        totalClasses: 0,
        faculty: faculty?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attendanceTarget: attendanceTarget,
      );
      state = state.copyWith(
        subjects: [...state.subjects, subject],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> editSubject({
    required String subjectId,
    required String name,
    String? faculty,
    double? attendanceTarget,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final existing = state.subjects.firstWhere((s) => s.id == subjectId);
      await _repo.saveSubject(
        name: name.trim(),
        faculty: faculty?.trim(),
        attendanceTarget: attendanceTarget,
        existingId: subjectId,
        attendedClasses: existing.attendedClasses,
        totalClasses: existing.totalClasses,
      );
      final updated = state.subjects.map((s) {
        if (s.id == subjectId) {
          return s.copyWith(
            name: name.trim(),
            faculty: faculty?.trim(),
            attendanceTarget: attendanceTarget,
          );
        }
        return s;
      }).toList();
      state = state.copyWith(subjects: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeSubject(String subjectId) async {
    await _repo.deleteSubject(subjectId);
    state = state.copyWith(
      subjects: state.subjects.where((s) => s.id != subjectId).toList(),
    );
  }

  Future<bool> completeSubjectSetup() async {
    if (!state.subjectsValid) {
      state = state.copyWith(error: 'Add at least one subject to continue.');
      return false;
    }
    await advanceStep(OnboardingStep.subjects);
    return true;
  }

  // ─── Timetable Builder ────────────────────────────────────────────────────

  Future<void> addTimetableEntry({
    required String subjectId,
    required String subjectName,
    required String day,
    required String startTime,
    required String endTime,
    String? faculty,
    String? room,
  }) async {
    try {
      final id = await _repo.addTimetableEntry(
        subjectId: subjectId,
        subjectName: subjectName,
        day: day,
        startTime: startTime,
        endTime: endTime,
        faculty: faculty,
        room: room,
      );
      final entry = TimetableEntry(
        id: id,
        subjectId: subjectId,
        subject: subjectName,
        day: day,
        startTime: startTime,
        endTime: endTime,
        confidence: 1.0,
      );
      state = state.copyWith(
          timetableEntries: [...state.timetableEntries, entry]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeTimetableEntry(String entryId) async {
    await _repo.deleteTimetableEntry(entryId);
    state = state.copyWith(
      timetableEntries:
          state.timetableEntries.where((e) => e.id != entryId).toList(),
    );
  }

  void syncTimetableEntries(List<TimetableEntry> entries) =>
      state = state.copyWith(timetableEntries: entries);

  Future<void> skipTimetable() async {
    state = state.copyWith(timetableSkipped: true);
    await advanceStep(OnboardingStep.timetable);
  }

  Future<void> completeTimetable() async {
    state = state.copyWith(timetableSkipped: false);
    await advanceStep(OnboardingStep.timetable);
  }

  // ─── Holiday Calendar ─────────────────────────────────────────────────────

  Future<void> toggleHoliday(DateTime date) async {
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final previous = state.holidays;
    final isHoliday = previous.any((h) => isSameDay(h, date));
    final updated = isHoliday
        ? previous.where((h) => !isSameDay(h, date)).toList()
        : [...previous, date];
    // Optimistic update
    state = state.copyWith(holidays: updated);
    if (state.semesterId != null) {
      try {
        await _repo.updateHolidays(state.semesterId!, updated);
      } catch (_) {
        // Roll back to the last persisted value on failure
        state = state.copyWith(holidays: previous);
        rethrow;
      }
    }
  }

  Future<void> skipHolidays() async {
    state = state.copyWith(holidaysSkipped: true);
    await advanceStep(OnboardingStep.holidays);
  }

  Future<void> completeHolidays() async {
    state = state.copyWith(holidaysSkipped: false);
    await advanceStep(OnboardingStep.holidays);
  }

  // ─── Attendance Import ────────────────────────────────────────────────────

  void initImportData() {
    // Always rebuild from the current subjects list so state changes
    // (or a restored session) are reflected when re-entering this screen.
    final data = <String, SubjectImportData>{};
    for (final s in state.subjects) {
      // Preserve any data the user already entered for this subject.
      final existing = state.importData[s.id];
      data[s.id] = existing ?? SubjectImportData(subjectId: s.id, subjectName: s.name);
    }
    state = state.copyWith(importData: data);
  }

  void setImportMethod(String subjectId, ImportMethod method) {
    final updated = Map<String, SubjectImportData>.from(state.importData);
    final existing = updated[subjectId];
    if (existing != null) {
      updated[subjectId] = existing.copyWith(method: method);
    }
    state = state.copyWith(importData: updated);
  }

  void setManualAttended(String subjectId, int value) {
    final updated = Map<String, SubjectImportData>.from(state.importData);
    final existing = updated[subjectId];
    if (existing != null) {
      updated[subjectId] = existing.copyWith(manualAttended: value);
    }
    state = state.copyWith(importData: updated);
  }

  void setManualTotal(String subjectId, int value) {
    final updated = Map<String, SubjectImportData>.from(state.importData);
    final existing = updated[subjectId];
    if (existing != null) {
      updated[subjectId] = existing.copyWith(manualTotal: value);
    }
    state = state.copyWith(importData: updated);
  }

  void toggleAbsentDate(String subjectId, DateTime date) {
    bool isSame(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final updated = Map<String, SubjectImportData>.from(state.importData);
    final existing = updated[subjectId];
    if (existing == null) return;
    final dates = existing.absentDates;
    final isAbsent = dates.any((d) => isSame(d, date));
    updated[subjectId] = existing.copyWith(
      absentDates: isAbsent
          ? dates.where((d) => !isSame(d, date)).toList()
          : [...dates, date],
    );
    state = state.copyWith(importData: updated);
  }

  Future<void> skipImport() async {
    state = state.copyWith(importSkipped: true);
    await advanceStep(OnboardingStep.import);
  }

  Future<bool> saveImport() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final manualCounts = <String, ({int attended, int total})>{};
      final absentBySubject = <String, List<DateTime>>{};
      final subjectIdToName = <String, String>{};

      for (final entry in state.importData.entries) {
        final d = entry.value;
        subjectIdToName[d.subjectId] = d.subjectName;
        if (d.method == ImportMethod.manualCount) {
          if (d.manualTotal > 0) {
            manualCounts[d.subjectId] =
                (attended: d.manualAttended, total: d.manualTotal);
          }
        } else {
          if (d.absentDates.isNotEmpty) {
            absentBySubject[d.subjectId] = d.absentDates;
          }
        }
      }

      if (manualCounts.isNotEmpty) {
        await _repo.saveManualCounts(manualCounts);
      }
      if (absentBySubject.isNotEmpty) {
        await _repo.saveAbsentDates(
          absentDatesBySubject: absentBySubject,
          timetableEntries: state.timetableEntries,
          subjectIdToName: subjectIdToName,
        );
      }

      state = state.copyWith(importSkipped: false, isLoading: false);
      await advanceStep(OnboardingStep.import);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Review / Confirm ─────────────────────────────────────────────────────

  Future<bool> confirmAndComplete() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!state.timetableSkipped && state.timetableEntries.isNotEmpty) {
        await _repo.generateClassSessions();
      }
      await _repo.markComplete();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ─── Resume (called on launch when onboardingComplete == false) ───────────

  Future<void> restoreFromFirestore({
    required String lastStep,
    String? collegeName,
    String? courseName,
    String? semesterName,
    double attendanceGoal = 75.0,
  }) async {
    final subjects = await _repo.getSubjects();
    // Reload the active semester ID so holiday updates can persist after resume.
    final semesterId = await _repo.getActiveSemesterId();
    state = state.copyWith(
      currentStep: lastStep,
      collegeName: collegeName ?? '',
      courseName: courseName ?? '',
      semesterName: semesterName ?? '',
      attendanceGoal: attendanceGoal,
      subjects: subjects,
      semesterId: semesterId,
    );
  }
}
