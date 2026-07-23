import 'package:drift/drift.dart';

/// Table: app_notifications
///
/// Stores persistent in-app notification center entries (what the user
/// sees in the Notification Center screen). Does NOT store OS notification
/// state.
///
/// OQ-3 resolution: age-based pruning, 90-day cutoff, run on app startup.
///   DELETE FROM app_notifications WHERE created_at < (now_ms - 90 * 86400000)
///
/// The stable date-keyed id format (e.g. 'attendanceDanger_2026-07-22')
/// is preserved as PK for O(1) dedup checks (SELECT 1 WHERE id = ? before insert).
@TableIndex(name: 'idx_an_created_at', columns: {#createdAt})
@TableIndex(name: 'idx_an_is_read', columns: {#isRead})
@TableIndex(name: 'idx_an_type', columns: {#type})
class AppNotifications extends Table {
  /// Stable string ID, e.g. 'attendanceDanger_2026-07-22'.
  TextColumn get id => text()();

  /// Notification title.
  TextColumn get title => text()();

  /// Full notification body text.
  TextColumn get message => text()();

  /// Enum string: attendanceDanger / criticalAttendance /
  ///              nightlyBunkPlanner / system.
  TextColumn get type => text()();

  /// Enum string: low / normal / high / critical.
  TextColumn get priority => text().withDefault(const Constant('normal'))();

  /// BOOLEAN (0/1). Whether the user has read this notification.
  IntColumn get isRead => integer().withDefault(const Constant(0))();

  /// Optional JSON payload for tap handling.
  TextColumn get payload => text().nullable()();

  /// Creation timestamp — Unix timestamp (ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
