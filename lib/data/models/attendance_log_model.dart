import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Attendance status for a class or attendance log.
/// ─ present   : student was present
/// ─ absent    : student was absent
/// ─ late      : student attended but was late
/// ─ cancelled : class was cancelled (does not count toward attendance)
/// ─ notMarked : session exists but attendance has not been logged yet
///              (used on ClassSession documents only — never stored in logs)
enum AttendanceStatus { present, absent, late, cancelled, notMarked }

class AttendanceLogModel extends Equatable {
  final String id;
  final String subjectId;

  /// Denormalised for display. May be null on old logs — fall back to a
  /// subjects-stream lookup by [subjectId] in those cases.
  final String? subjectName;
  final AttendanceStatus status;
  final DateTime date;

  /// Time-range stored at write-time from the class session.
  final String? startTime;
  final String? endTime;

  /// Links this log to the specific ClassSession it was created from.
  /// Used to detect duplicate markings and support History page edits.
  /// May be null on logs created before this field was added.
  final String? sessionId;

  /// Soft-archive flag set by SubjectCascadeService when a subject is deleted.
  /// Null on all logs created before this field was added — treated as false.
  /// Archived logs are excluded from History and Analytics but preserved for audit.
  final bool? isArchived;

  const AttendanceLogModel({
    required this.id,
    required this.subjectId,
    this.subjectName,
    required this.status,
    required this.date,
    this.startTime,
    this.endTime,
    this.sessionId,
    this.isArchived,
  });

  factory AttendanceLogModel.fromJson(Map<String, dynamic> json, String docId) {
    return AttendanceLogModel(
      id: docId,
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String?,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      sessionId: json['sessionId'] as String?,
      isArchived: json['isArchived'] as bool?, // null on old logs = not archived
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        if (subjectName != null) 'subjectName': subjectName,
        'status': status.name,
        'date': Timestamp.fromDate(date),
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (sessionId != null) 'sessionId': sessionId,
        if (isArchived == true) 'isArchived': true, // only write when true; keeps new docs clean
      };

  AttendanceLogModel copyWith({
    String? subjectId,
    String? subjectName,
    AttendanceStatus? status,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? sessionId,
    bool? isArchived,
  }) =>
      AttendanceLogModel(
        id: id,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        status: status ?? this.status,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        sessionId: sessionId ?? this.sessionId,
        isArchived: isArchived ?? this.isArchived,
      );

  @override
  List<Object?> get props =>
      [id, subjectId, subjectName, status, date, startTime, endTime, sessionId, isArchived];
}
