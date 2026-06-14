import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, late, cancelled }

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

  const AttendanceLogModel({
    required this.id,
    required this.subjectId,
    this.subjectName,
    required this.status,
    required this.date,
    this.startTime,
    this.endTime,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        if (subjectName != null) 'subjectName': subjectName,
        'status': status.name,
        'date': Timestamp.fromDate(date),
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
      };

  AttendanceLogModel copyWith({
    String? subjectName,
    AttendanceStatus? status,
    DateTime? date,
    String? startTime,
    String? endTime,
  }) =>
      AttendanceLogModel(
        id: id,
        subjectId: subjectId,
        subjectName: subjectName ?? this.subjectName,
        status: status ?? this.status,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );

  @override
  List<Object?> get props =>
      [id, subjectId, subjectName, status, date, startTime, endTime];
}
