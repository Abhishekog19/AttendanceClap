import 'package:equatable/equatable.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/timetable_entry_model.dart';

// ─── Onboarding Step Keys ─────────────────────────────────────────────────────

/// Canonical step keys used for Firestore resume tracking and router redirect.
class OnboardingStep {
  static const welcome = 'welcome';
  static const college = 'college';
  static const semester = 'semester';
  static const subjects = 'subjects';
  static const periodTiming = 'periodTiming'; // NEW: period setup before grid
  static const timetable = 'timetable';
  static const holidays = 'holidays';
  static const import = 'import';
  static const review = 'review';
  static const complete = 'complete';

  /// Ordered list of all steps for progress indicator.
  static const all = [
    welcome, college, semester, subjects, periodTiming, timetable, holidays, import, review,
  ];

  /// Mandatory steps — cannot be skipped.
  static const mandatory = {welcome, college, semester, subjects};

  /// Optional steps — have a Skip button.
  static const optional = {periodTiming, timetable, holidays, import};

  /// Returns 0-based index of step in the flow (for progress bar).
  static int indexOf(String step) => all.indexOf(step);

  /// Returns the step to navigate to AFTER the given step.
  static String? nextStep(String current) {
    final idx = all.indexOf(current);
    if (idx == -1 || idx >= all.length - 1) return null;
    return all[idx + 1];
  }

  /// Maps a step key to its route path under /onboarding.
  static String routeFor(String step) {
    switch (step) {
      case welcome: return '/onboarding/welcome';
      case college: return '/onboarding/college';
      case semester: return '/onboarding/semester';
      case subjects: return '/onboarding/subjects';
      case periodTiming: return '/onboarding/period-timing';
      case timetable: return '/onboarding/timetable';
      case holidays: return '/onboarding/holidays';
      case import: return '/onboarding/import';
      case review: return '/onboarding/review';
      default: return '/onboarding/welcome';
    }
  }
}

// ─── Import Method ───────────────────────────────────────────────────────────

enum ImportMethod {
  /// User enters attended-count + total-count manually per subject.
  manualCount,

  /// User marks absent dates on a calendar; app counts from timetable.
  markAbsentDates,
}

// ─── Per-Subject Import State ─────────────────────────────────────────────────

class SubjectImportData extends Equatable {
  final String subjectId;
  final String subjectName;

  // Method A
  final int manualAttended;
  final int manualTotal;

  // Method B
  final List<DateTime> absentDates;

  final ImportMethod method;

  const SubjectImportData({
    required this.subjectId,
    required this.subjectName,
    this.manualAttended = 0,
    this.manualTotal = 0,
    this.absentDates = const [],
    this.method = ImportMethod.manualCount,
  });

  SubjectImportData copyWith({
    int? manualAttended,
    int? manualTotal,
    List<DateTime>? absentDates,
    ImportMethod? method,
  }) =>
      SubjectImportData(
        subjectId: subjectId,
        subjectName: subjectName,
        manualAttended: manualAttended ?? this.manualAttended,
        manualTotal: manualTotal ?? this.manualTotal,
        absentDates: absentDates ?? this.absentDates,
        method: method ?? this.method,
      );

  @override
  List<Object?> get props =>
      [subjectId, subjectName, manualAttended, manualTotal, absentDates, method];
}

// ─── Onboarding State ────────────────────────────────────────────────────────

/// Immutable in-progress onboarding state held by [OnboardingNotifier].
/// Persisted to Firestore on every write (auto-save).
class OnboardingState extends Equatable {
  // ── Current position ─────────────────────────────────────────────────────
  final String currentStep;
  final bool isLoading;
  final String? error;

  // ── College Details ───────────────────────────────────────────────────────
  final String collegeName;
  final String courseName;
  final String year;
  final String section;

  // ── Semester Setup ────────────────────────────────────────────────────────
  final String semesterName;
  final DateTime? semesterStart;
  final DateTime? semesterEnd;
  final double attendanceGoal; // global %

  /// The Firestore document ID of the saved semester (set after save).
  final String? semesterId;

  // ── Subjects ──────────────────────────────────────────────────────────────
  final List<SubjectModel> subjects;

  // ── Timetable ─────────────────────────────────────────────────────────────
  /// Saved timetable entries (read from Firestore stream, not in-memory only).
  final List<TimetableEntry> timetableEntries;
  final bool timetableSkipped;

  // ── Holidays ──────────────────────────────────────────────────────────────
  final List<DateTime> holidays;
  final bool holidaysSkipped;

  // ── Attendance Import ─────────────────────────────────────────────────────
  final Map<String, SubjectImportData> importData; // keyed by subjectId
  final bool importSkipped;

  const OnboardingState({
    this.currentStep = OnboardingStep.welcome,
    this.isLoading = false,
    this.error,
    // College
    this.collegeName = '',
    this.courseName = '',
    this.year = '',
    this.section = '',
    // Semester
    this.semesterName = '',
    this.semesterStart,
    this.semesterEnd,
    this.attendanceGoal = 75.0,
    this.semesterId,
    // Subjects
    this.subjects = const [],
    // Timetable
    this.timetableEntries = const [],
    this.timetableSkipped = false,
    // Holidays
    this.holidays = const [],
    this.holidaysSkipped = false,
    // Import
    this.importData = const {},
    this.importSkipped = false,
  });

  // ── Derived helpers ───────────────────────────────────────────────────────

  bool get collegeValid =>
      collegeName.trim().isNotEmpty && courseName.trim().isNotEmpty;

  bool get semesterValid =>
      semesterName.trim().isNotEmpty &&
      semesterStart != null &&
      semesterEnd != null &&
      semesterEnd!.isAfter(semesterStart!);

  bool get subjectsValid => subjects.isNotEmpty;

  int get stepIndex => OnboardingStep.indexOf(currentStep);

  int get totalSteps => OnboardingStep.all.length;

  OnboardingState copyWith({
    String? currentStep,
    bool? isLoading,
    Object? error = _sentinel,
    String? collegeName,
    String? courseName,
    String? year,
    String? section,
    String? semesterName,
    Object? semesterStart = _sentinel,
    Object? semesterEnd = _sentinel,
    double? attendanceGoal,
    Object? semesterId = _sentinel,
    List<SubjectModel>? subjects,
    List<TimetableEntry>? timetableEntries,
    bool? timetableSkipped,
    List<DateTime>? holidays,
    bool? holidaysSkipped,
    Map<String, SubjectImportData>? importData,
    bool? importSkipped,
  }) =>
      OnboardingState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
        collegeName: collegeName ?? this.collegeName,
        courseName: courseName ?? this.courseName,
        year: year ?? this.year,
        section: section ?? this.section,
        semesterName: semesterName ?? this.semesterName,
        semesterStart: semesterStart == _sentinel
            ? this.semesterStart
            : semesterStart as DateTime?,
        semesterEnd: semesterEnd == _sentinel
            ? this.semesterEnd
            : semesterEnd as DateTime?,
        attendanceGoal: attendanceGoal ?? this.attendanceGoal,
        semesterId:
            semesterId == _sentinel ? this.semesterId : semesterId as String?,
        subjects: subjects ?? this.subjects,
        timetableEntries: timetableEntries ?? this.timetableEntries,
        timetableSkipped: timetableSkipped ?? this.timetableSkipped,
        holidays: holidays ?? this.holidays,
        holidaysSkipped: holidaysSkipped ?? this.holidaysSkipped,
        importData: importData ?? this.importData,
        importSkipped: importSkipped ?? this.importSkipped,
      );

  static const _sentinel = Object();

  @override
  List<Object?> get props => [
        currentStep, isLoading, error,
        collegeName, courseName, year, section,
        semesterName, semesterStart, semesterEnd, attendanceGoal, semesterId,
        subjects, timetableEntries, timetableSkipped,
        holidays, holidaysSkipped,
        importData, importSkipped,
      ];
}
