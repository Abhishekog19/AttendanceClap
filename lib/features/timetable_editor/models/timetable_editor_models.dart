/// Timetable Editor — Model Classes
///
/// All models use plain Dart + toMap()/fromMap() to avoid build_runner overhead.
/// Times are stored as "HH:mm" 24-hour strings — never Timestamp — to avoid
/// timezone ambiguity (periods are day-of-week templates, not calendar dates).
///
/// Firestore layout:
///   /users/{uid}/timetable/config          ← single doc: defaultSchedule + daySchedules
///   /users/{uid}/timetable/subjects/{id}   ← TimetableSubject docs
///   /users/{uid}/timetable/lectures/{id}   ← LectureBlock docs

import 'dart:ui';

// ─── Subject Color Palette ────────────────────────────────────────────────────

/// Fixed 12-color palette for auto-assigning subject colors.
/// Colors are mid-saturation hues that look good as cell fills.
const kSubjectColorPalette = [
  '#E57373', // Red
  '#FF8A65', // Deep Orange
  '#FFB74D', // Orange
  '#FFD54F', // Amber
  '#81C784', // Green
  '#4DB6AC', // Teal
  '#4FC3F7', // Light Blue
  '#7986CB', // Indigo
  '#BA68C8', // Purple
  '#F06292', // Pink
  '#A1887F', // Brown
  '#90A4AE', // Blue Grey
];

/// Returns the next unused color from the palette given existing colors.
/// Cycles through the palette if all are used.
String nextSubjectColor(List<String> usedColors) {
  for (final c in kSubjectColorPalette) {
    if (!usedColors.contains(c)) return c;
  }
  // All colors used — cycle from start
  return kSubjectColorPalette[usedColors.length % kSubjectColorPalette.length];
}

/// Converts a hex color string (e.g. "#E57373") to a Flutter Color.
Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ─── Short Name Generator ─────────────────────────────────────────────────────

/// Auto-generates a short name from a full subject name.
/// Examples: "Data Structures" → "DS", "Operating System" → "OS", "Maths" → "MTH"
String generateShortName(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    // Acronym from first letter of each word, max 4 chars
    return words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join().substring(0, words.length.clamp(1, 4));
  }
  // Single word — take first 3-4 consonants/letters
  final upper = name.toUpperCase();
  return upper.length <= 4 ? upper : upper.substring(0, 4);
}

// ─── TimetableSubject ─────────────────────────────────────────────────────────

class TimetableSubject {
  final String id;
  final String name;           // full name, e.g. "Data Structures"
  final String shortName;      // auto-generated + editable, e.g. "DS"
  final String colorHex;       // from kSubjectColorPalette, e.g. "#E57373"
  final double? minAttendanceRequired; // percentage, optional

  const TimetableSubject({
    required this.id,
    required this.name,
    required this.shortName,
    required this.colorHex,
    this.minAttendanceRequired,
  });

  Color get color => hexToColor(colorHex);

  TimetableSubject copyWith({
    String? id,
    String? name,
    String? shortName,
    String? colorHex,
    Object? minAttendanceRequired = _sentinel,
  }) =>
      TimetableSubject(
        id: id ?? this.id,
        name: name ?? this.name,
        shortName: shortName ?? this.shortName,
        colorHex: colorHex ?? this.colorHex,
        minAttendanceRequired: minAttendanceRequired == _sentinel
            ? this.minAttendanceRequired
            : minAttendanceRequired as double?,
      );

  factory TimetableSubject.fromMap(String id, Map<String, dynamic> m) =>
      TimetableSubject(
        id: id,
        name: m['name'] as String? ?? '',
        shortName: m['shortName'] as String? ?? '',
        colorHex: m['colorHex'] as String? ?? kSubjectColorPalette[0],
        minAttendanceRequired:
            (m['minAttendanceRequired'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'shortName': shortName,
        'colorHex': colorHex,
        if (minAttendanceRequired != null)
          'minAttendanceRequired': minAttendanceRequired,
      };

  static const _sentinel = Object();
}

// ─── PeriodType ───────────────────────────────────────────────────────────────

enum PeriodType { lecture, breakPeriod, lunch }

// ─── PeriodSlot ───────────────────────────────────────────────────────────────

class PeriodSlot {
  final String id;
  final String label;      // "Period 1", "Break", "Lunch"
  final String startTime;  // "09:00" — 24hr string, no Timestamp
  final String endTime;    // "09:50"
  final PeriodType type;

  const PeriodSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  PeriodSlot copyWith({
    String? id,
    String? label,
    String? startTime,
    String? endTime,
    PeriodType? type,
  }) =>
      PeriodSlot(
        id: id ?? this.id,
        label: label ?? this.label,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        type: type ?? this.type,
      );

  factory PeriodSlot.fromMap(Map<String, dynamic> m) => PeriodSlot(
        id: m['id'] as String,
        label: m['label'] as String,
        startTime: m['startTime'] as String,
        endTime: m['endTime'] as String,
        type: PeriodType.values.byName(m['type'] as String? ?? 'lecture'),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'startTime': startTime,
        'endTime': endTime,
        'type': type.name,
      };

  /// Duration in minutes between startTime and endTime.
  int get durationMinutes {
    final s = _parseTime(startTime);
    final e = _parseTime(endTime);
    return e - s;
  }

  static int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

// ─── DaySchedule ─────────────────────────────────────────────────────────────

/// One entry per day-of-week; handles irregular days (Saturday half-days, etc.)
class DaySchedule {
  final String day;               // "MON".."SUN"
  final List<PeriodSlot> periods;
  final bool usesGlobalSchedule;  // true = inherits config.defaultSchedule

  const DaySchedule({
    required this.day,
    required this.periods,
    required this.usesGlobalSchedule,
  });

  DaySchedule copyWith({
    String? day,
    List<PeriodSlot>? periods,
    bool? usesGlobalSchedule,
  }) =>
      DaySchedule(
        day: day ?? this.day,
        periods: periods ?? this.periods,
        usesGlobalSchedule: usesGlobalSchedule ?? this.usesGlobalSchedule,
      );

  factory DaySchedule.fromMap(String day, Map<String, dynamic> m) =>
      DaySchedule(
        day: day,
        periods: (m['periods'] as List<dynamic>? ?? [])
            .map((p) => PeriodSlot.fromMap(p as Map<String, dynamic>))
            .toList(),
        usesGlobalSchedule: m['usesGlobalSchedule'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'periods': periods.map((p) => p.toMap()).toList(),
        'usesGlobalSchedule': usesGlobalSchedule,
      };
}

// ─── LectureBlock ─────────────────────────────────────────────────────────────

class LectureBlock {
  final String id;
  final String day;           // "MON".."SUN"
  final String subjectId;
  final String startPeriodId;
  final int spanPeriods;      // 1 = single period, 2+ = multi-period/lab
  final String? facultyName;
  final String? classroom;
  final String? notes;
  final bool isLab;

  const LectureBlock({
    required this.id,
    required this.day,
    required this.subjectId,
    required this.startPeriodId,
    required this.spanPeriods,
    this.facultyName,
    this.classroom,
    this.notes,
    required this.isLab,
  });

  LectureBlock copyWith({
    String? id,
    String? day,
    String? subjectId,
    String? startPeriodId,
    int? spanPeriods,
    Object? facultyName = _sentinel,
    Object? classroom = _sentinel,
    Object? notes = _sentinel,
    bool? isLab,
  }) =>
      LectureBlock(
        id: id ?? this.id,
        day: day ?? this.day,
        subjectId: subjectId ?? this.subjectId,
        startPeriodId: startPeriodId ?? this.startPeriodId,
        spanPeriods: spanPeriods ?? this.spanPeriods,
        facultyName: facultyName == _sentinel
            ? this.facultyName
            : facultyName as String?,
        classroom:
            classroom == _sentinel ? this.classroom : classroom as String?,
        notes: notes == _sentinel ? this.notes : notes as String?,
        isLab: isLab ?? this.isLab,
      );

  factory LectureBlock.fromMap(String id, Map<String, dynamic> m) =>
      LectureBlock(
        id: id,
        day: m['day'] as String,
        subjectId: m['subjectId'] as String,
        startPeriodId: m['startPeriodId'] as String,
        spanPeriods: (m['spanPeriods'] as num?)?.toInt() ?? 1,
        facultyName: m['facultyName'] as String?,
        classroom: m['classroom'] as String?,
        notes: m['notes'] as String?,
        isLab: m['isLab'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'subjectId': subjectId,
        'startPeriodId': startPeriodId,
        'spanPeriods': spanPeriods,
        if (facultyName != null) 'facultyName': facultyName,
        if (classroom != null) 'classroom': classroom,
        if (notes != null) 'notes': notes,
        'isLab': isLab,
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
/// Assembled from three Firestore listeners via the Riverpod notifier.
class TimetableEditorState {
  final List<TimetableSubject> subjects;
  final List<PeriodSlot> defaultSchedule;
  final Map<String, DaySchedule> daySchedules; // keyed by "MON".."SUN"
  final List<LectureBlock> lectures;
  final bool isLoading;
  final String? error;

  const TimetableEditorState({
    this.subjects = const [],
    this.defaultSchedule = const [],
    this.daySchedules = const {},
    this.lectures = const [],
    this.isLoading = false,
    this.error,
  });

  TimetableEditorState copyWith({
    List<TimetableSubject>? subjects,
    List<PeriodSlot>? defaultSchedule,
    Map<String, DaySchedule>? daySchedules,
    List<LectureBlock>? lectures,
    bool? isLoading,
    Object? error = _sentinel,
  }) =>
      TimetableEditorState(
        subjects: subjects ?? this.subjects,
        defaultSchedule: defaultSchedule ?? this.defaultSchedule,
        daySchedules: daySchedules ?? this.daySchedules,
        lectures: lectures ?? this.lectures,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
      );

  /// Returns the effective period list for a given day abbreviation.
  /// Respects per-day overrides; falls back to defaultSchedule.
  List<PeriodSlot> periodsForDay(String day) {
    final daySchedule = daySchedules[day];
    if (daySchedule != null && !daySchedule.usesGlobalSchedule) {
      return daySchedule.periods;
    }
    return defaultSchedule;
  }

  /// Returns lecture blocks for a specific day.
  List<LectureBlock> lecturesForDay(String day) =>
      lectures.where((l) => l.day == day).toList();

  /// Looks up a subject by ID; returns null if not found.
  TimetableSubject? subjectById(String id) {
    try {
      return subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Number of weekdays (MON-FRI) that have at least one lecture.
  int get filledWeekdayCount {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    return weekdays.where((d) => lectures.any((l) => l.day == d)).length;
  }

  /// Total weekly lecture count (non-break slots only).
  int get totalWeeklyLectures =>
      lectures.where((l) => !l.isLab).length + lectures.where((l) => l.isLab).length;

  /// Lab session count.
  int get labSessionCount => lectures.where((l) => l.isLab).length;

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
const kDayOrder = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
