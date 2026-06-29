import 'package:cloud_firestore/cloud_firestore.dart';

class Semester {
  final String id;
  final String uid;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> holidays;
  final DateTime createdAt;

  /// Human-readable label for this semester (e.g. "Semester 3", "Fall 2025").
  /// Written during onboarding and displayed on the Review + Dashboard screens.
  final String? semesterName;

  /// Working weekdays for this semester (1=Monday … 7=Sunday).
  /// Derived from the timetable entries' day set during onboarding.
  /// Null on legacy semesters — treated as all days present in timetable.
  final List<int>? workingDays;

  const Semester({
    required this.id,
    required this.uid,
    required this.startDate,
    required this.endDate,
    this.holidays = const [],
    required this.createdAt,
    this.semesterName,
    this.workingDays,
  });

  int get totalWeeks {
    return endDate.difference(startDate).inDays ~/ 7;
  }

  bool isHoliday(DateTime date) {
    return holidays.any(
      (h) => h.year == date.year && h.month == date.month && h.day == date.day,
    );
  }

  /// Returns all dates in the semester for a given weekday (1=Mon … 7=Sun)
  List<DateTime> getDatesForWeekday(int weekday) {
    final dates = <DateTime>[];
    var current = startDate;
    while (!current.isAfter(endDate)) {
      if (current.weekday == weekday && !isHoliday(current)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'holidays': holidays.map((d) => Timestamp.fromDate(d)).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        if (semesterName != null) 'semesterName': semesterName,
        if (workingDays != null) 'workingDays': workingDays,
      };

  factory Semester.fromMap(Map<String, dynamic> map) => Semester(
        id: map['id'] as String,
        uid: map['uid'] as String,
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        holidays: ((map['holidays'] as List?)
                    ?.map((e) => (e as Timestamp).toDate())
                    .toList()) ??
                [],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        semesterName: map['semesterName'] as String?,
        workingDays: (map['workingDays'] as List?)?.map((e) => (e as num).toInt()).toList(),
      );
}
