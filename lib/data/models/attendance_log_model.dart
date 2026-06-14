import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, late, cancelled }

class AttendanceLogModel extends Equatable {
  final String id;
  final String subjectId;
  final AttendanceStatus status;
  final DateTime date;

  const AttendanceLogModel({
    required this.id,
    required this.subjectId,
    required this.status,
    required this.date,
  });

  factory AttendanceLogModel.fromJson(Map<String, dynamic> json, String docId) {
    return AttendanceLogModel(
      id: docId,
      subjectId: json['subjectId'] as String? ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'status': status.name,
      'date': Timestamp.fromDate(date),
    };
  }

  @override
  List<Object?> get props => [id, subjectId, status, date];
}
