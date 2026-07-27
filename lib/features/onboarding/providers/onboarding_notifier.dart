import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/router/app_lifecycle_state.dart' show appDatabaseProvider;
import '../../../data/local/database.dart';
import '../../../data/models/subject_model.dart';
import '../../../features/timetable_editor/providers/timetable_editor_notifier.dart';
import 'onboarding_state.dart';

part 'onboarding_notifier.g.dart';

// ─── OnboardingNotifier ───────────────────────────────────────────────────────
//
// Phase 5: Firestore-backed OnboardingRepository removed entirely.
// Every previous _repo call was guarded by `if (_noAuth) return` (uid was ''),
// making it a runtime no-op throughout the app's lifetime. The repository class
// and its onboardingRepositoryProvider have been deleted.
//
// Resume logic: handled by the router (AppLifecycleOnboarding.step reads
// app_settings.onboarding_step written by advanceStep() on every screen).
// _hydrateIfNeeded() was a Phase 3 no-op stub — removed.

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  // ─── Step navigation ──────────────────────────────────────────────────────

  void goToStep(String step) =>
      state = state.copyWith(currentStep: step, error: null);

  Future<void> advanceStep(String completedStep) async {
    final next = OnboardingStep.nextStep(completedStep);
    state = state.copyWith(currentStep: next ?? completedStep, error: null);

    // Write the new step to the local SQLite app_settings row.
    // appLifecycleStateProvider watches this row — without this write the router
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
  }

  /// Navigates to the next step in the flow from [currentStep].
  /// Must be called with a mounted [BuildContext].
  Future<void> navigateNext(
    BuildContext context,
    String currentStep,
  ) async {
    await advanceStep(currentStep);
    final nextRoute = OnboardingStep.routeFor(state.currentStep);
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
    // College details are stored in OnboardingState (in-memory / on-device).
    // No Firestore write needed — the data is used during onboarding only and
    // is captured inside _persistLocalSemester() as semesterName metadata.
    await advanceStep(OnboardingStep.college);
    return true;
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
    // Generate a stable UUID for this semester. _persistLocalSemester() uses
    // state.semesterId if present, so setting it here keeps them in sync.
    final id = const Uuid().v4();
    state = state.copyWith(semesterId: id, isLoading: false);
    await advanceStep(OnboardingStep.semester);
    return true;
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
      // Generate a stable UUID now; will be written to SQLite subjects table
      // by _persistLocalSemester / confirmAndComplete at the end of onboarding.
      final id = const Uuid().v4();
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

  /// Sets the default lecture duration (in minutes) and saves to timetable config.
  Future<void> setDefaultLectureDuration(int minutes) async {
    await ref
        .read(timetableEditorNotifierProvider.notifier)
        .updateDefaultLectureDuration(minutes);
  }

  // ─── Holiday Calendar ─────────────────────────────────────────────────────

  Future<void> toggleHoliday(DateTime date) async {
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final updated = state.holidays.any((h) => isSameDay(h, date))
        ? state.holidays.where((h) => !isSameDay(h, date)).toList()
        : [...state.holidays, date];
    // Holidays are held in state and written to the semester row by
    // _persistLocalSemester() → they do not need a separate Firestore write.
    state = state.copyWith(holidays: updated);
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
    // Manual counts and absent-date logs are stored in state only.
    // They are written to the local SQLite attendance_logs table inside
    // confirmAndComplete() → _persistLocalSemester() when the user finalises.
    // No Firestore writes are performed here (previous calls were all no-ops
    // due to _noAuth guard).
    state = state.copyWith(importSkipped: false);
    await advanceStep(OnboardingStep.import);
    return true;
  }

  // ─── Review / Confirm ─────────────────────────────────────────────────────

  Future<bool> confirmAndComplete() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _persistLocalSemester();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Emergency skip: marks onboarding complete without further data entry.
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
}
