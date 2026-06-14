import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final String id;
  final String name;
  final int attendedClasses;
  final int totalClasses;
  final String? faculty;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.attendedClasses,
    required this.totalClasses,
    this.faculty,
    required this.createdAt,
    required this.updatedAt,
  });

  double get attendancePercentage =>
      totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;

  factory SubjectModel.fromJson(Map<String, dynamic> json, String docId) {
    return SubjectModel(
      id: docId,
      name: json['name'] as String? ?? '',
      attendedClasses: (json['attendedClasses'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      faculty: json['faculty'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'attendedClasses': attendedClasses,
      'totalClasses': totalClasses,
      'faculty': faculty,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SubjectModel copyWith({
    String? id,
    String? name,
    int? attendedClasses,
    int? totalClasses,
    String? faculty,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      attendedClasses: attendedClasses ?? this.attendedClasses,
      totalClasses: totalClasses ?? this.totalClasses,
      faculty: faculty ?? this.faculty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        attendedClasses,
        totalClasses,
        faculty,
        createdAt,
        updatedAt,
      ];
}
