import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppNotificationModel
//
// Represents a single persisted notification stored in Firestore under:
//   users/{uid}/notifications/{notificationId}
//
// Survives app restart, device restart, and logout/login cycles.
// ─────────────────────────────────────────────────────────────────────────────

enum AppNotificationType {
  attendanceWarning,
  classReminder,
  safeBunk,
  delay,
  subscription,
  system,
}

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
      };

  factory AppNotificationModel.fromFirestore(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: AppNotificationType.values.firstWhere(
        (t) => t.name == (map['type'] as String?),
        orElse: () => AppNotificationType.system,
      ),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
