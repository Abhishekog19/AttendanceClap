import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/semester_model.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../../data/repositories/timetable_repository.dart';

part 'semester_provider.g.dart';

// ── Semester form state ───────────────────────────────────────────────────────

class SemesterFormState {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime> holidays;
  final bool isGenerating;
  final double generationProgress;
  final String? error;
  final int? generatedCount;

  const SemesterFormState({
    this.startDate,
    this.endDate,
    this.holidays = const [],
    this.isGenerating = false,
    this.generationProgress = 0.0,
    this.error,
    this.generatedCount,
  });

  bool get isValid =>
      startDate != null &&
      endDate != null &&
      endDate!.isAfter(startDate!);

  int get estimatedWeeks =>
      isValid ? endDate!.difference(startDate!).inDays ~/ 7 : 0;

  SemesterFormState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<DateTime>? holidays,
    bool? isGenerating,
    double? generationProgress,
    String? error,
    int? generatedCount,
  }) {
    return SemesterFormState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      holidays: holidays ?? this.holidays,
      isGenerating: isGenerating ?? this.isGenerating,
      generationProgress: generationProgress ?? this.generationProgress,
      error: error ?? this.error,
      generatedCount: generatedCount ?? this.generatedCount,
    );
  }
}

@riverpod
class SemesterNotifier extends _$SemesterNotifier {
  @override
  SemesterFormState build() => const SemesterFormState();

  void setStartDate(DateTime date) =>
      state = state.copyWith(startDate: date, error: null);

  void setEndDate(DateTime date) =>
      state = state.copyWith(endDate: date, error: null);

  void addHoliday(DateTime date) {
    if (!state.holidays.any((h) =>
        h.year == date.year && h.month == date.month && h.day == date.day)) {
      state = state.copyWith(holidays: [...state.holidays, date]);
    }
  }

  void removeHoliday(DateTime date) {
    state = state.copyWith(
      holidays: state.holidays
          .where((h) => !(h.year == date.year &&
              h.month == date.month &&
              h.day == date.day))
          .toList(),
    );
  }

  /// Estimate session count without writing to Firestore
  int estimateSessions(List<TimetableEntry> entries) {
    if (!state.isValid) return 0;
    final semester = _buildSemester();
    int count = 0;
    for (int weekday = 1; weekday <= 7; weekday++) {
      final dayName = _weekdayName(weekday);
      final dayEntries = entries.where((e) => e.day == dayName).length;
      final dates = semester.getDatesForWeekday(weekday).length;
      count += dayEntries * dates;
    }
    return count;
  }

  Future<void> generateSchedule({
    required List<TimetableEntry> entries,
    required TimetableRepository repo,
  }) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please select valid start and end dates.');
      return;
    }

    state = state.copyWith(isGenerating: true, error: null, generationProgress: 0.0);

    try {
      final semester = _buildSemester();

      // 1. Save semester config
      await repo.saveSemester(semester);

      // 2. Save timetable entries
      await repo.saveTimetable(entries);

      // 3. Auto-create subjects
      final subjectIdMap = await repo.createSubjectsFromTimetable(entries);

      // 4. Generate and write all sessions
      final count = await repo.saveClassSessions(
        entries: entries,
        semester: semester,
        subjectIdMap: subjectIdMap,
        onProgress: (p) =>
            state = state.copyWith(generationProgress: p),
      );

      state = state.copyWith(
        isGenerating: false,
        generationProgress: 1.0,
        generatedCount: count,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate schedule: $e',
      );
    }
  }

  Semester _buildSemester() => Semester(
        id: const Uuid().v4(),
        uid: '', // set by repo
        startDate: state.startDate!,
        endDate: state.endDate!,
        holidays: state.holidays,
        createdAt: DateTime.now(),
      );

  String _weekdayName(int weekday) {
    const names = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return names[weekday];
  }
}
