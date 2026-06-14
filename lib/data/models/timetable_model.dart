import 'package:equatable/equatable.dart';

class TimetableModel extends Equatable {
  final String id;
  final String subjectId;
  final String subjectName;
  final int day; // 0=Monday ... 6=Sunday
  final String startTime; // "HH:MM"
  final String endTime;   // "HH:MM"
  final String? faculty;
  final String? room;

  const TimetableModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.faculty,
    this.room,
  });

  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day.clamp(0, 6)];
  }

  factory TimetableModel.fromJson(Map<String, dynamic> json, String docId) {
    return TimetableModel(
      id: docId,
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? 0,
      startTime: json['startTime'] as String? ?? '09:00',
      endTime: json['endTime'] as String? ?? '10:00',
      faculty: json['faculty'] as String?,
      room: json['room'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'faculty': faculty,
      'room': room,
    };
  }

  TimetableModel copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    int? day,
    String? startTime,
    String? endTime,
    String? faculty,
    String? room,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      faculty: faculty ?? this.faculty,
      room: room ?? this.room,
    );
  }

  @override
  List<Object?> get props => [id, subjectId, subjectName, day, startTime, endTime, faculty, room];
}
