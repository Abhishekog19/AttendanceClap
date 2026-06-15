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

  // ─── Premium ────────────────────────────────────────────────────────────────
  final bool isPremium;
  final String? planType; // 'monthly' | 'annual' | null
  final DateTime? premiumExpiresAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.attendanceGoal = 75.0,
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    this.isPremium = false,
    this.planType,
    this.premiumExpiresAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    DateTime? expiresAt;
    final rawExpiry = json['premiumExpiresAt'];
    if (rawExpiry is Timestamp) {
      expiresAt = rawExpiry.toDate();
    }

    return UserModel(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      attendanceGoal: (json['attendanceGoal'] as num?)?.toDouble() ?? 75.0,
      themeMode: json['themeMode'] as String? ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
      planType: json['planType'] as String?,
      premiumExpiresAt: expiresAt,
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
      'isPremium': isPremium,
      'planType': planType,
      'premiumExpiresAt':
          premiumExpiresAt != null ? Timestamp.fromDate(premiumExpiresAt!) : null,
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
    bool? isPremium,
    String? planType,
    DateTime? premiumExpiresAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      attendanceGoal: attendanceGoal ?? this.attendanceGoal,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isPremium: isPremium ?? this.isPremium,
      planType: planType ?? this.planType,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
    );
  }

  @override
  List<Object?> get props => [
        uid, name, email, photoUrl, attendanceGoal, themeMode,
        isPremium, planType, premiumExpiresAt,
      ];
}
