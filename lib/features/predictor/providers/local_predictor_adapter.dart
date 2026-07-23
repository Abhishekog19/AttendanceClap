/// Adapter that bridges [LocalAttendanceRepository.getAllSubjectStats()] to
/// the input shape expected by [PredictorService.computePredictions()].
///
/// ## What this replaces
///
/// The existing [predictorDataProvider] (predictor_provider.dart) currently
/// feeds [PredictorService] using three Firestore-backed sources:
///   1. [subjectsStreamProvider]           → Firestore subjects collection
///   2. [predictorSemesterProvider]        → Firestore semesters collection
///   3. [predictorEntriesStreamProvider]   → Firestore timetable_entries collection
///
/// This adapter replaces source (1) — the subjects data — by pulling
/// [attendedClasses] / [totalClasses] from the local SQLite database via
/// [LocalAttendanceRepository.getAllSubjectStats()], converting them into
/// [SubjectModel] instances that [PredictorService] already knows how to
/// consume.
///
/// Sources (2) and (3) (semester + entries) remain Firestore-backed in Phase 2.
/// They will be migrated in a later phase when the timetable layer moves local.

library;

import '../../../data/models/subject_model.dart';
import '../../../data/repositories/local_attendance_repository.dart';
import '../services/predictor_service.dart';

/// Converts [SubjectStats] rows (local SQLite) into [SubjectModel] instances
/// for consumption by [PredictorService.computePredictions()].
///
/// Call this adapter from the predictor provider INSTEAD OF reading subjects
/// directly from Firestore.
///
/// Example usage (Riverpod provider):
/// ```dart
/// final subjects = await ref.watch(localPredictorAdapterProvider.future);
/// ```
class LocalPredictorAdapter {
  final LocalAttendanceRepository _repo;

  const LocalPredictorAdapter(this._repo);

  /// Fetches all subject stats from the local database and converts them into
  /// the [SubjectModel] shape expected by [PredictorService.computePredictions].
  ///
  /// Fields mapped:
  ///   SubjectStats.subjectId        → SubjectModel.id
  ///   SubjectStats.name             → SubjectModel.name
  ///   SubjectStats.attendedClasses  → SubjectModel.attendedClasses
  ///   SubjectStats.totalClasses     → SubjectModel.totalClasses
  ///   SubjectStats.attendanceTarget → SubjectModel.attendanceTarget
  ///   SubjectStats.colorHex         → SubjectModel.colorHex
  ///   SubjectStats.shortName        → SubjectModel.shortName
  ///
  /// Fields that SubjectModel requires but SubjectStats does not have:
  ///   faculty    → null  (not needed by PredictorService)
  ///   createdAt  → epoch (PredictorService does not use this field)
  ///   updatedAt  → epoch (PredictorService does not use this field)
  Future<List<SubjectModel>> getSubjectsForPredictor() async {
    final stats = await _repo.getAllSubjectStats();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    return stats.map((s) {
      return SubjectModel(
        id: s.subjectId,
        name: s.name,
        attendedClasses: s.attendedClasses,
        totalClasses: s.totalClasses,
        faculty: null,
        createdAt: epoch,
        updatedAt: epoch,
        attendanceTarget: s.attendanceTarget,
        colorHex: s.colorHex,
        shortName: s.shortName,
      );
    }).toList();
  }
}

// ── Manual invocation (no Riverpod in this phase) ─────────────────────────────
//
// To wire this into the existing predictorDataProvider, replace:
//
//   final subjects = await ref.watch(subjectsStreamProvider.future);
//
// with:
//
//   final db = AppDatabase(); // or inject via provider
//   final repo = LocalAttendanceRepository(db);
//   final adapter = LocalPredictorAdapter(repo);
//   final subjects = await adapter.getSubjectsForPredictor();
//
// The rest of predictorDataProvider (semester, entries, PredictorService call)
// remains unchanged in Phase 2.
