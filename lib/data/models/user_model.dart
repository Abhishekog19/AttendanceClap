import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final double attendanceGoal;
  final String themeMode; // 'system', 'light', 'dark'
  final bool notificationsEnabled;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.attendanceGoal = 75.0,
    this.themeMode = 'system',
    this.notificationsEnabled = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      attendanceGoal: (json['attendanceGoal'] as num?)?.toDouble() ?? 75.0,
      themeMode: json['themeMode'] as String? ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'attendanceGoal': attendanceGoal,
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    double? attendanceGoal,
    String? themeMode,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      attendanceGoal: attendanceGoal ?? this.attendanceGoal,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [uid, name, email, photoUrl, attendanceGoal, themeMode];
}
