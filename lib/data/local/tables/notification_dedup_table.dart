import 'package:drift/drift.dart';

/// Table: notification_dedup
///
/// Unified deduplication table replacing three Firestore documents:
///   notification_alert_state/daily_warning
///   notification_alert_state/daily_critical
///   notification_alert_state/{subjectId}
///
/// OQ-1 resolution — Option A: single table, no FK on `key`.
/// The `key` column holds either a fixed string ('daily_warning',
/// 'daily_critical') or a subject UUID (per-subject alert state).
/// A FK cannot coexist for both kinds of keys in one column.
///
/// APPLICATION-LEVEL CONTRACT (Phase 2+ DAOs):
///   When a subject is deleted, the DAO MUST execute:
///     DELETE FROM notification_dedup WHERE key = <subject_uuid>
///   as part of the deletion transaction. This is NOT enforced by the schema.
///
/// No indexes needed — all reads are by primary key (WHERE key = ?).
class NotificationDedup extends Table {
  /// Dedup key.
  ///   Daily fixed keys: 'daily_warning' | 'daily_critical'
  ///   Per-subject: the subject UUID string.
  TextColumn get key => text()();

  /// ISO date string "YYYY-MM-DD" of the last fire date.
  TextColumn get lastFiredDate => text()();

  /// Unix timestamp (ms) of when the notification was fired.
  IntColumn get firedAt => integer()();

  /// Unix timestamp (ms) when the condition was resolved.
  /// NULL means the alert is still unresolved (for per-subject alerts).
  IntColumn get resolvedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
