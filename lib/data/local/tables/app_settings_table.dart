import 'package:drift/drift.dart';
import 'semesters_table.dart';

/// Table: app_settings
///
/// Singleton table — always contains exactly one row with id = 1.
/// Replaces two separate storage mechanisms:
///   1. UserModel non-auth fields stored in Firestore
///   2. LocalCacheDatasource (SharedPreferences) — entirely removed
///
/// Auth-related fields (uid, email, name, photoUrl, isPremium, etc.)
/// are explicitly excluded.
///
/// FK: active_semester_id → semesters.id ON DELETE SET NULL
///   If the active semester is deleted, the app reverts to "no active
///   semester" state rather than crashing. The user must then select or
///   create a new semester.
///
/// No indexes — singleton table, always fetched by primary key.
class AppSettings extends Table {
  /// Singleton PK — always 1.
  IntColumn get id => integer()();

  /// BOOLEAN (0/1). Router gates main app behind this.
  IntColumn get onboardingComplete =>
      integer().withDefault(const Constant(0))();

  /// Onboarding resume key:
  ///   welcome / college / semester / subjects / timetable /
  ///   holidays / import / review / complete
  TextColumn get onboardingStep => text().nullable()();

  /// Theme mode: 'system' / 'light' / 'dark'.
  TextColumn get themeMode =>
      text().withDefault(const Constant('system'))();

  /// Global attendance goal percentage (0–100).
  /// Per-subject override lives on subjects.attendance_target.
  RealColumn get attendanceGoal =>
      real().withDefault(const Constant(75.0))();

  /// BOOLEAN (0/1). Global notification on/off switch.
  /// Mirrors NotificationPreferences.notificationsEnabled for quick access.
  IntColumn get notificationsEnabled =>
      integer().withDefault(const Constant(1))();

  /// College name entered during onboarding.
  TextColumn get collegeName => text().nullable()();

  /// Course name entered during onboarding.
  TextColumn get courseName => text().nullable()();

  /// FK → semesters.id, ON DELETE SET NULL.
  /// NULL means no active semester is set.
  TextColumn get activeSemesterId =>
      text().nullable().references(Semesters, #id,
          onDelete: KeyAction.setNull)();

  /// Last-modified timestamp — Unix timestamp (ms).
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
