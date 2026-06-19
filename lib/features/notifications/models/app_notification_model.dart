import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppNotificationType — V1 Final Enum
//
// Persistent types (written to Firestore notification center):
//   attendanceDanger    → attendance dropped below user target
//   criticalAttendance  → attendance dropped below critical threshold
//   nightlyBunkPlanner  → nightly consolidated safe-bunk summary
//   system              → reserved / fallback
//
// Device-only types (NOT stored here — handled by notification_scheduler.dart):
//   class reminders, attendance marking reminders
// ─────────────────────────────────────────────────────────────────────────────

enum AppNotificationType {
  attendanceDanger,   // was: attendanceWarning
  criticalAttendance, // new in V1
  nightlyBunkPlanner, // was: safeBunk
  system,             // fallback
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationPriority
//
// Controls display ordering within date groups in the Notification Center.
// Also stored to Firestore as the priority field string.
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationPriority {
  low,      // nightlyBunkPlanner
  normal,   // system
  high,     // attendanceDanger
  critical, // criticalAttendance
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNotificationModel
//
// Represents a single persisted notification stored in Firestore under:
//   users/{uid}/notifications/{notificationId}
//
// All notifications survive app restart, device restart, and logout/login cycles.
// userId field provides an additional safety guard against cross-account leakage.
// ─────────────────────────────────────────────────────────────────────────────

class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final NotificationPriority priority;
  final String? payload;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.priority = NotificationPriority.normal,
    this.payload,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'priority': priority.name,
        'payload': payload,
      };

  factory AppNotificationModel.fromFirestore(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: _parseType(map['type'] as String?),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      priority: _parsePriority(map['priority'] as String?),
      payload: map['payload'] as String?,
    );
  }

  // ── Type parsing — backward-compatible with V0 enum string values ──────────

  static AppNotificationType _parseType(String? raw) {
    return switch (raw) {
      'attendanceDanger' => AppNotificationType.attendanceDanger,
      'criticalAttendance' => AppNotificationType.criticalAttendance,
      'nightlyBunkPlanner' => AppNotificationType.nightlyBunkPlanner,
      'system' => AppNotificationType.system,
      // ── Legacy V0 names → mapped to closest V1 equivalent ──
      'attendanceWarning' => AppNotificationType.attendanceDanger,
      'safeBunk' => AppNotificationType.nightlyBunkPlanner,
      'classReminder' => AppNotificationType.system,
      'delay' => AppNotificationType.system,
      'subscription' => AppNotificationType.system,
      _ => AppNotificationType.system,
    };
  }

  static NotificationPriority _parsePriority(String? raw) {
    return NotificationPriority.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => NotificationPriority.normal,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  AppNotificationModel copyWith({
    bool? isRead,
    String? userId,
    NotificationPriority? priority,
    String? payload,
  }) {
    return AppNotificationModel(
      id: id,
      userId: userId ?? this.userId,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
    );
  }
}
