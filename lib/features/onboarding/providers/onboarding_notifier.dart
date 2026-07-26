import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/router/app_lifecycle_state.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../../data/local/database.dart';
import '../../../data/models/subject_model.dart';
// auth_repository import removed — router now gates onboarding via AppLifecycleState.
import '../../../data/repositories/timetable_repository.dart';
import '../../../features/timetable_editor/providers/timetable_editor_notifier.dart';
import '../repositories/onboarding_repository.dart';
import 'onboarding_state.dart';

part 'onboarding_notifier.g.dart';

// ─── OnboardingRepository provider ────────────────────────────────────────────────────────────

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  // uid removed: local DB does not require a user ID.
  // Will be fully replaced when Firestore data layer is removed (Phase 4+).
  return OnboardingRepository(
    db: ref.watch(firestoreDatasourceProvider),
    timetableRepo: ref.watch(timetableRepositoryProvider),
    uid: '', // placeholder — auth uid no longer drives routing
  );
}

// ─── OnboardingNotifier ───────────────────────────────────────────────────────

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() {
    // Auto-restore when user profile is loaded and onboarding is incomplete.
    // This runs once per provider lifecycle (cold start / login).
    Future.microtask(_hydrateIfNeeded);
    return const OnboardingState();
  }

  Future<void> _hydrateIfNeeded() async {
    // Phase 3: no-op stub.
    // Previously read currentUserProfileProvider to decide whether to resume
    // onboarding. That check is now owned by the router (AppLifecycleState).
    // Full local-DB hydration replaces this in Phase 4.
  }

  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);

  // ─── Step navigation ──────────────────────────────────────────────────────

  void goToStep(String step) =>
      state = state.copyWith(currentStep: step, error: null);

  Future<void> advanceStep(String completedStep) async {
    final next = OnboardingStep.nextStep(completedStep);
    state = state.copyWith(currentStep: next ?? completedStep, error: null);

    // ── Write the new step to the local SQLite app_settings row ──────────────
    // appLifecycleStateProvider watches this row. Without this write the router
    // keeps emitting AppLifecycleOnboarding('welcome') and redirects every
    // GoRouter.go() call back to /onboarding/welcome.
    final db = ref.read(appDatabaseProvider);
    await (db.into(db.appSettings)).insertOnConflictUpdate(
      AppSettingsCompanion(
        id: const Value(1),
        onboardingStep: Value(next ?? completedStep),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Legacy Firestore write (uid = '' → no-op; safe to leave until Phase 4
    // removes Firestore entirely).
    await _repo.saveStep(completedStep);
  }

  /// Navigates to the next step in the flow from [currentStep].
  /// Also persists [currentStep] as completed to Firestore.
  /// Must be called with a mounted [BuildContext].
  Future<void> navigateNext(
    BuildContext context,
    String currentStep,
  ) async {
    await advanceStep(currentStep);
    final nextRoute =
        OnboardingStep.routeFor(state.currentStep);
    if (context.mounted) GoRouter.of(context).go(nextRoute);
  }

  /// Navigates back to [targetStep] without persisting any progress change.
  void navigateBack(BuildContext context, String targetStep) {
    if (context.mounted) {
      GoRouter.of(context).go(OnboardingStep.routeFor(targetStep));
    }
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
    String? colorHex,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = await _repo.saveSubject(
        name: name.trim(),
        faculty: faculty?.trim(),
        attendanceTarget: attendanceTarget,
        colorHex: colorHex,
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
        colorHex: colorHex,
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
    String? colorHex,
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
        colorHex: colorHex ?? existing.colorHex,
      );
      final updated = state.subjects.map((s) {
        if (s.id == subjectId) {
          return s.copyWith(
            name: name.trim(),
            faculty: faculty?.trim(),
            attendanceTarget: attendanceTarget,
            colorHex: colorHex ?? existing.colorHex,
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

  // ─── Timetable Builder ────────────────────────────────────────────────

  Future<void> skipTimetable() async {
    state = state.copyWith(timetableSkipped: true);
    await advanceStep(OnboardingStep.timetable);
  }

  Future<void> completeTimetable() async {
    state = state.copyWith(timetableSkipped: false);
    await advanceStep(OnboardingStep.timetable);
  }

  /// Sets the default lecture duration (in minutes) and saves to timetable/config.
  Future<void> setDefaultLectureDuration(int minutes) async {
    await ref
        .read(timetableEditorNotifierProvider.notifier)
        .updateDefaultLectureDuration(minutes);
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
        // timetable entries are now read from timetable/config/lectures
        // by the repository directly
        await _repo.saveAbsentDates(
          absentDatesBySubject: absentBySubject,
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
      // Generate class sessions from timetable (no-op when uid empty or skipped)
      if (!state.timetableSkipped) {
        await _repo.generateClassSessions();
      }

      // ── Persist semester + active_semester_id to local SQLite ────────────
      // The router requires active_semester_id != null for AppLifecycleReady.
      // Without this write the router stays in NeedsSemester and redirects
      // to the post-onboarding SemesterSetupScreen which crashes (needs auth uid).
      await _persistLocalSemester();

      // Legacy Firestore complete — no-op when uid is empty (Phase 3).
      await _repo.markComplete();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Emergency skip: marks onboarding complete without saving any data.
  /// Writes a placeholder semester row so the router sees AppLifecycleReady
  /// and navigates to /dashboard instead of looping into NeedsSemester.
  Future<void> skipAllAndComplete(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _persistLocalSemester();
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        GoRouter.of(context).go('/onboarding/success');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Inserts a semester row into the local SQLite `semesters` table and sets
  /// `app_settings.active_semester_id` to that UUID.
  ///
  /// Uses real semester dates when available (from state), otherwise falls back
  /// to a 6-month window starting today.
  ///
  /// Must be called BEFORE navigating away from onboarding so the router
  /// emits AppLifecycleReady on the very next stream event.
  Future<void> _persistLocalSemester() async {
    final db = ref.read(appDatabaseProvider);
    final semId = state.semesterId ?? const Uuid().v4();
    final now = DateTime.now();
    final start = state.semesterStart ?? now;
    final end = state.semesterEnd ?? now.add(const Duration(days: 180));
    final name = state.semesterName.isNotEmpty
        ? state.semesterName
        : 'Semester 1';

    // Insert the semester row (idempotent — replace on conflict).
    await (db.into(db.semesters)).insertOnConflictUpdate(
      SemestersCompanion(
        id: Value(semId),
        name: Value(name),
        startDate: Value(start.millisecondsSinceEpoch),
        endDate: Value(end.millisecondsSinceEpoch),
        createdAt: Value(now.millisecondsSinceEpoch),
        isActive: const Value(1),
      ),
    );

    // Update app_settings: mark onboarding done + point to this semester.
    await (db.into(db.appSettings)).insertOnConflictUpdate(
      AppSettingsCompanion(
        id: const Value(1),
        onboardingComplete: const Value(1),
        onboardingStep: const Value('complete'),
        activeSemesterId: Value(semId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
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
