/// Timetable Editor — Model Classes
///
/// All models use plain Dart + toMap()/fromMap() to avoid build_runner overhead.
/// Times are stored as "HH:mm" 24-hour strings — never Timestamp — to avoid
/// timezone ambiguity (periods are day-of-week templates, not calendar dates).
///
/// Firestore layout:
///   /users/{uid}/timetable/config          ← defaultLectureDurationMinutes + gridStartHour + gridEndHour
///   /users/{uid}/timetable/config/lectures/{id}   ← LectureBlock docs
library;

import 'dart:ui';

import '../../../data/models/subject_model.dart';

// Re-export palette helpers so existing imports from here still compile.
export '../../../data/models/subject_model.dart'
    show
        kSubjectColorPalette,
        nextSubjectColor,
        generateSubjectShortName;

/// Converts a hex color string (e.g. "#E57373") to a Flutter Color.
Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ─── LectureBlock ─────────────────────────────────────────────────────────────

/// One scheduled lecture slot in the weekly timetable.
/// Uses absolute wall-clock start time + duration instead of period indices.
class LectureBlock {
  final String id;
  final String day;             // "MON".."SUN"
  final String subjectId;
  final String startTime;       // "HH:mm" 24hr, e.g. "09:00"
  final int durationMinutes;    // duration in minutes, e.g. 50
  final String? facultyName;
  final String? classroom;
  final String? notes;

  const LectureBlock({
    required this.id,
    required this.day,
    required this.subjectId,
    required this.startTime,
    required this.durationMinutes,
    this.facultyName,
    this.classroom,
    this.notes,
  });

  /// Computed end time string "HH:mm".
  String get endTime {
    final parts = startTime.split(':');
    final startMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endMins = startMins + durationMinutes;
    final h = endMins ~/ 60;
    final m = endMins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// The hour (0-23) in which this lecture starts.
  int get startHour => int.parse(startTime.split(':')[0]);

  /// The minute within the starting hour.
  int get startMinute => int.parse(startTime.split(':')[1]);

  LectureBlock copyWith({
    String? id,
    String? day,
    String? subjectId,
    String? startTime,
    int? durationMinutes,
    Object? facultyName = _sentinel,
    Object? classroom = _sentinel,
    Object? notes = _sentinel,
  }) =>
      LectureBlock(
        id: id ?? this.id,
        day: day ?? this.day,
        subjectId: subjectId ?? this.subjectId,
        startTime: startTime ?? this.startTime,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        facultyName:
            facultyName == _sentinel ? this.facultyName : facultyName as String?,
        classroom:
            classroom == _sentinel ? this.classroom : classroom as String?,
        notes: notes == _sentinel ? this.notes : notes as String?,
      );

  factory LectureBlock.fromMap(String id, Map<String, dynamic> m) {
    // Handle legacy period-indexed docs gracefully — treat them as "09:00" / 50 min
    final startTime = m['startTime'] as String? ?? '09:00';
    final durationMinutes = (m['durationMinutes'] as num?)?.toInt() ?? 50;
    return LectureBlock(
      id: id,
      day: m['day'] as String? ?? 'MON',
      subjectId: m['subjectId'] as String? ?? '',
      startTime: startTime,
      durationMinutes: durationMinutes,
      facultyName: m['facultyName'] as String?,
      classroom: m['classroom'] as String?,
      notes: m['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'day': day,
        'subjectId': subjectId,
        'startTime': startTime,
        'durationMinutes': durationMinutes,
        if (facultyName != null) 'facultyName': facultyName,
        if (classroom != null) 'classroom': classroom,
        if (notes != null) 'notes': notes,
      };

  static const _sentinel = Object();
}

// ─── ConflictInfo ─────────────────────────────────────────────────────────────

class ConflictInfo {
  final String lectureId;
  final String message;

  const ConflictInfo({required this.lectureId, required this.message});
}

// ─── TimetableEditorState ────────────────────────────────────────────────────

/// In-memory aggregate the TimetableGrid widget renders from.
/// Assembled from Firestore listeners via the Riverpod notifier.
class TimetableEditorState {
  final List<SubjectModel> subjects;
  final List<LectureBlock> lectures;
  final int defaultLectureDurationMinutes; // default 60
  final int gridStartHour;                 // grid visible range start (default 8)
  final int gridEndHour;                   // grid visible range end (default 22)
  final bool isLoading;
  final String? error;

  const TimetableEditorState({
    this.subjects = const [],
    this.lectures = const [],
    this.defaultLectureDurationMinutes = 60,
    this.gridStartHour = 8,
    this.gridEndHour = 22,
    this.isLoading = false,
    this.error,
  });

  TimetableEditorState copyWith({
    List<SubjectModel>? subjects,
    List<LectureBlock>? lectures,
    int? defaultLectureDurationMinutes,
    int? gridStartHour,
    int? gridEndHour,
    bool? isLoading,
    Object? error = _sentinel,
  }) =>
      TimetableEditorState(
        subjects: subjects ?? this.subjects,
        lectures: lectures ?? this.lectures,
        defaultLectureDurationMinutes:
            defaultLectureDurationMinutes ?? this.defaultLectureDurationMinutes,
        gridStartHour: gridStartHour ?? this.gridStartHour,
        gridEndHour: gridEndHour ?? this.gridEndHour,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
      );

  /// Returns lecture blocks for a specific day.
  List<LectureBlock> lecturesForDay(String day) =>
      lectures.where((l) => l.day == day).toList();

  /// Looks up a subject by ID; returns null if not found.
  SubjectModel? subjectById(String id) {
    try {
      return subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Finds a lecture that overlaps the given hour row for a day.
  /// A lecture overlaps hour H if it starts before H+1 and ends after H.
  LectureBlock? lectureAtHour(String day, int hour) {
    final hourStart = hour * 60; // minutes since midnight
    final hourEnd = hourStart + 60;
    try {
      return lectures.firstWhere((l) {
        if (l.day != day) return false;
        final lStart = l.startHour * 60 + l.startMinute;
        final lEnd = lStart + l.durationMinutes;
        // Overlap: lecture starts before hour ends AND lecture ends after hour starts
        return lStart < hourEnd && lEnd > hourStart;
      });
    } catch (_) {
      return null;
    }
  }

  /// Number of weekdays (MON-FRI) that have at least one lecture.
  int get filledWeekdayCount {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    return weekdays.where((d) => lectures.any((l) => l.day == d)).length;
  }

  /// Total weekly lecture count.
  int get totalWeeklyLectures => lectures.length;

  /// Ordered list of hour rows to display (from gridStartHour to gridEndHour - 1).
  List<int> get hourRows =>
      List.generate(gridEndHour - gridStartHour, (i) => gridStartHour + i);

  static const _sentinel = Object();
}

// ─── Day name helpers ─────────────────────────────────────────────────────────

/// Full weekday name → 3-letter abbreviation used as Firestore key.
const kDayAbbreviations = {
  'Monday': 'MON',
  'Tuesday': 'TUE',
  'Wednesday': 'WED',
  'Thursday': 'THU',
  'Friday': 'FRI',
  'Saturday': 'SAT',
  'Sunday': 'SUN',
};

/// 3-letter abbreviation → full weekday name.
const kDayFullNames = {
  'MON': 'Monday',
  'TUE': 'Tuesday',
  'WED': 'Wednesday',
  'THU': 'Thursday',
  'FRI': 'Friday',
  'SAT': 'Saturday',
  'SUN': 'Sunday',
};

/// Ordered list of day abbreviations (Mon-first).
const kDayOrder = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
