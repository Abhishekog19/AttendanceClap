import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/local/database.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/local_attendance_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';

part 'subjects_provider.g.dart';

// ── SubjectsNotifier ──────────────────────────────────────────────────────────
//
// All subject CRUD goes through LocalAttendanceRepository, which ensures:
//   - Color palette is respected on addSubject
//   - SQLite CASCADE FK handles deletion of dependent rows automatically
//   - No application-level cascade code is needed here
//
// Note: subjectsStreamProvider (from dashboard_provider.dart) is the single
// live-data source. This notifier reuses it so there is only ONE stream
// subscription to the subjects table.

@riverpod
class SubjectsNotifier extends _$SubjectsNotifier {
  @override
  AsyncValue<List<SubjectModel>> build() {
    // Watch the top-level stream provider — never recreated on rebuild.
    return ref.watch(subjectsStreamProvider);
  }

  LocalAttendanceRepository get _repo =>
      ref.read(localAttendanceRepositoryProvider);

  Future<void> addSubject({
    required String name,
    int attended = 0,
    int total = 0,
    String? faculty,
    String? colorHex,
    String? shortName,
  }) async {
    await AsyncValue.guard(
      () => _repo.addSubject(
        name: name,
        attendedClasses: attended,
        totalClasses: total,
        faculty: faculty,
        colorHex: colorHex,
        shortName: shortName,
      ),
    );
  }

  Future<void> updateSubject(SubjectModel model) async {
    // Convert SubjectModel → Drift Subject companion via the repo's updateSubject.
    // The repo accepts a Drift Subject directly so we build a synthetic one.
    final sub = Subject(
      id: model.id,
      name: model.name,
      attendedClasses: model.attendedClasses,
      totalClasses: model.totalClasses,
      faculty: model.faculty,
      attendanceTarget: model.attendanceTarget,
      colorHex: model.colorHex,
      shortName: model.shortName,
      createdAt: model.createdAt.millisecondsSinceEpoch,
      updatedAt: model.updatedAt.millisecondsSinceEpoch,
    );
    await _repo.updateSubject(sub);
  }

  Future<void> deleteSubject(String subjectId) async {
    // SQLite ON DELETE CASCADE removes timetable_entries, class_sessions,
    // and attendance_logs automatically. No manual cascade code needed.
    await _repo.deleteSubject(subjectId);
  }
}
