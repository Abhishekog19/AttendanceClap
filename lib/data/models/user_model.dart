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

  // ─── Onboarding ─────────────────────────────────────────────────────────────
  /// True once the user taps "Confirm" on the Review screen.
  /// The router gates the main app behind this flag.
  final bool onboardingComplete;

  /// Key of the last completed onboarding step, used for resume-after-interruption.
  /// Values: 'welcome' | 'college' | 'semester' | 'subjects' | 'timetable'
  ///         | 'holidays' | 'import' | 'review' | 'complete'
  final String? onboardingStep;

  /// College / institution name entered during College Details step.
  final String? collegeName;

  /// Course / programme entered during College Details step.
  final String? courseName;

  /// Human-readable semester label, e.g. "Semester 3" or "Fall 2025".
  final String? semesterName;

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
    this.onboardingComplete = false,
    this.onboardingStep,
    this.collegeName,
    this.courseName,
    this.semesterName,
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
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      onboardingStep: json['onboardingStep'] as String?,
      collegeName: json['collegeName'] as String?,
      courseName: json['courseName'] as String?,
      semesterName: json['semesterName'] as String?,
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
      'onboardingComplete': onboardingComplete,
      if (onboardingStep != null) 'onboardingStep': onboardingStep,
      if (collegeName != null) 'collegeName': collegeName,
      if (courseName != null) 'courseName': courseName,
      if (semesterName != null) 'semesterName': semesterName,
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
    bool? onboardingComplete,
    Object? onboardingStep = _sentinel,
    Object? collegeName = _sentinel,
    Object? courseName = _sentinel,
    Object? semesterName = _sentinel,
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
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      onboardingStep: onboardingStep == _sentinel ? this.onboardingStep : onboardingStep as String?,
      collegeName: collegeName == _sentinel ? this.collegeName : collegeName as String?,
      courseName: courseName == _sentinel ? this.courseName : courseName as String?,
      semesterName: semesterName == _sentinel ? this.semesterName : semesterName as String?,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props => [
        uid, name, email, photoUrl, attendanceGoal, themeMode,
        notificationsEnabled,
        isPremium, planType, premiumExpiresAt,
        onboardingComplete, onboardingStep, collegeName, courseName, semesterName,
      ];
}
