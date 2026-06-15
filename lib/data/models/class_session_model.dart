import 'package:cloud_firestore/cloud_firestore.dart';

import 'attendance_log_model.dart' show AttendanceStatus;
export 'attendance_log_model.dart' show AttendanceStatus;

class ClassSession {
  final String id;
  final String subjectId;
  final String subjectName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? faculty;
  final String? room;
  final AttendanceStatus status;
  final String uid;

  // ── Daily override fields ────────────────────────────────────────────────────
  /// When set, the class subject has been overridden for this day only.
  final String? overrideSubjectId;
  final String? overrideSubjectName;

  /// When set, the class times have been rescheduled for this day only.
  final String? overrideStartTime;
  final String? overrideEndTime;

  /// True when the class has been cancelled for this day.
  final bool isCancelled;

  /// True when this session was added as an extra period (not in the timetable).
  final bool isExtraPeriod;

  const ClassSession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.faculty,
    this.room,
    this.status = AttendanceStatus.notMarked,
    required this.uid,
    this.overrideSubjectId,
    this.overrideSubjectName,
    this.overrideStartTime,
    this.overrideEndTime,
    this.isCancelled = false,
    this.isExtraPeriod = false,
  });

  // ── Computed display values (override-aware) ──────────────────────────────

  String get displaySubjectName => overrideSubjectName ?? subjectName;
  String get displaySubjectId => overrideSubjectId ?? subjectId;
  String get displayStartTime => overrideStartTime ?? startTime;
  String get displayEndTime => overrideEndTime ?? endTime;

  // ── Time helpers ──────────────────────────────────────────────────────────

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isPast => date.isBefore(DateTime.now());

  /// True if the class is currently in progress (based on phone clock).
  bool get isCurrentlyInProgress {
    final now = DateTime.now();
    if (!isToday) return false;
    final start = _parseTime(displayStartTime);
    final end = _parseTime(displayEndTime);
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= start && nowMinutes < end;
  }

  /// True if the class has fully ended (end time has passed today).
  bool get hasEnded {
    if (!isToday) return true;
    final now = DateTime.now();
    final end = _parseTime(displayEndTime);
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= end;
  }

  /// True if the class hasn't started yet today.
  bool get hasNotStarted {
    if (!isToday) return false;
    final now = DateTime.now();
    final start = _parseTime(displayStartTime);
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes < start;
  }

  static int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // ── Copy ──────────────────────────────────────────────────────────────────

  ClassSession copyWith({
    AttendanceStatus? status,
    String? overrideSubjectId,
    String? overrideSubjectName,
    String? overrideStartTime,
    String? overrideEndTime,
    bool? isCancelled,
    bool? isExtraPeriod,
  }) =>
      ClassSession(
        id: id,
        subjectId: subjectId,
        subjectName: subjectName,
        date: date,
        startTime: startTime,
        endTime: endTime,
        faculty: faculty,
        room: room,
        status: status ?? this.status,
        uid: uid,
        overrideSubjectId: overrideSubjectId ?? this.overrideSubjectId,
        overrideSubjectName: overrideSubjectName ?? this.overrideSubjectName,
        overrideStartTime: overrideStartTime ?? this.overrideStartTime,
        overrideEndTime: overrideEndTime ?? this.overrideEndTime,
        isCancelled: isCancelled ?? this.isCancelled,
        isExtraPeriod: isExtraPeriod ?? this.isExtraPeriod,
      );

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'date': Timestamp.fromDate(date),
        'startTime': startTime,
        'endTime': endTime,
        'faculty': faculty,
        'room': room,
        'status': status.name,
        'uid': uid,
        if (overrideSubjectId != null) 'overrideSubjectId': overrideSubjectId,
        if (overrideSubjectName != null)
          'overrideSubjectName': overrideSubjectName,
        if (overrideStartTime != null) 'overrideStartTime': overrideStartTime,
        if (overrideEndTime != null) 'overrideEndTime': overrideEndTime,
        'isCancelled': isCancelled,
        'isExtraPeriod': isExtraPeriod,
      };

  factory ClassSession.fromMap(Map<String, dynamic> map) => ClassSession(
        id: map['id'] as String,
        subjectId: map['subjectId'] as String,
        subjectName: map['subjectName'] as String,
        date: (map['date'] as Timestamp).toDate(),
        startTime: map['startTime'] as String,
        endTime: map['endTime'] as String,
        faculty: map['faculty'] as String?,
        room: map['room'] as String?,
        status: AttendanceStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => AttendanceStatus.notMarked,
        ),
        uid: map['uid'] as String,
        overrideSubjectId: map['overrideSubjectId'] as String?,
        overrideSubjectName: map['overrideSubjectName'] as String?,
        overrideStartTime: map['overrideStartTime'] as String?,
        overrideEndTime: map['overrideEndTime'] as String?,
        isCancelled: map['isCancelled'] as bool? ?? false,
        isExtraPeriod: map['isExtraPeriod'] as bool? ?? false,
      );
}
