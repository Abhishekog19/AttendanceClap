import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, cancelled, notMarked }

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
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isPast => date.isBefore(DateTime.now());

  ClassSession copyWith({AttendanceStatus? status}) => ClassSession(
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
      );

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
      );
}
