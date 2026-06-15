import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user-initiated override for a specific class session on a given day.
///
/// Daily overrides become the source of truth for that specific day's schedule.
/// They are stored at: users/{uid}/daily_overrides/{YYYY-MM-DD}/sessions/{sessionId}
enum OverrideType {
  changeSubject, // swap the subject for this day only
  reschedule,    // change the time slot for this day only
  cancel,        // mark the period as cancelled (no attendance required)
  addExtra,      // add an extra period not in the master timetable
}

class DailyScheduleOverride {
  final String id;
  final String sessionId;   // Firestore ID of the ClassSession being overridden
  final String uid;
  final DateTime date;      // The specific date of the override (day only)
  final OverrideType type;

  // ── Subject override fields ───────────────────────────────────────────────
  final String? newSubjectId;
  final String? newSubjectName;

  // ── Time override fields ──────────────────────────────────────────────────
  final String? newStartTime;
  final String? newEndTime;

  // ── Cancel / Extra period ─────────────────────────────────────────────────
  final bool isCancelled;
  final bool isExtraPeriod;

  final DateTime createdAt;

  const DailyScheduleOverride({
    required this.id,
    required this.sessionId,
    required this.uid,
    required this.date,
    required this.type,
    this.newSubjectId,
    this.newSubjectName,
    this.newStartTime,
    this.newEndTime,
    this.isCancelled = false,
    this.isExtraPeriod = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'uid': uid,
        'date': Timestamp.fromDate(date),
        'type': type.name,
        if (newSubjectId != null) 'newSubjectId': newSubjectId,
        if (newSubjectName != null) 'newSubjectName': newSubjectName,
        if (newStartTime != null) 'newStartTime': newStartTime,
        if (newEndTime != null) 'newEndTime': newEndTime,
        'isCancelled': isCancelled,
        'isExtraPeriod': isExtraPeriod,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory DailyScheduleOverride.fromMap(Map<String, dynamic> map) =>
      DailyScheduleOverride(
        id: map['id'] as String,
        sessionId: map['sessionId'] as String,
        uid: map['uid'] as String,
        date: (map['date'] as Timestamp).toDate(),
        type: OverrideType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => OverrideType.cancel,
        ),
        newSubjectId: map['newSubjectId'] as String?,
        newSubjectName: map['newSubjectName'] as String?,
        newStartTime: map['newStartTime'] as String?,
        newEndTime: map['newEndTime'] as String?,
        isCancelled: map['isCancelled'] as bool? ?? false,
        isExtraPeriod: map['isExtraPeriod'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  DailyScheduleOverride copyWith({
    String? newSubjectId,
    String? newSubjectName,
    String? newStartTime,
    String? newEndTime,
    bool? isCancelled,
  }) =>
      DailyScheduleOverride(
        id: id,
        sessionId: sessionId,
        uid: uid,
        date: date,
        type: type,
        newSubjectId: newSubjectId ?? this.newSubjectId,
        newSubjectName: newSubjectName ?? this.newSubjectName,
        newStartTime: newStartTime ?? this.newStartTime,
        newEndTime: newEndTime ?? this.newEndTime,
        isCancelled: isCancelled ?? this.isCancelled,
        isExtraPeriod: isExtraPeriod,
        createdAt: createdAt,
      );
}
