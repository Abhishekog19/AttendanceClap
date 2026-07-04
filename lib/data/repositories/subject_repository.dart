import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/subject_model.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/services/subject_cascade_service.dart';
import '../repositories/auth_repository.dart';

part 'subject_repository.g.dart';

@riverpod
SubjectRepository subjectRepository(Ref ref) {
  return SubjectRepository(
    datasource: ref.watch(firestoreDatasourceProvider),
    uid: ref.watch(currentUserProvider)?.uid ?? '',
  );
}

class SubjectRepository {
  final FirestoreDatasource _db;
  final String _uid;
  final _uuid = const Uuid();

  /// Cascade service — handles rename propagation and delete cascade.
  final _cascade = SubjectCascadeService();

  SubjectRepository({
    required FirestoreDatasource datasource,
    required String uid,
  })  : _db = datasource,
        _uid = uid;

  Stream<List<SubjectModel>> watchSubjects() => _db.watchSubjects(_uid);

  Future<List<SubjectModel>> getSubjects() => _db.getSubjects(_uid);

  Future<void> addSubject({
    required String name,
    int attendedClasses = 0,
    int totalClasses = 0,
    String? faculty,
    String? colorHex,
    String? shortName,
  }) async {
    final now = DateTime.now();
    // Auto-assign color from palette.
    // Query STORED colorHex only (not effectiveColorHex) so subjects that
    // haven't been backfilled yet don't falsely occupy palette slots.
    final existing = await _db.getSubjects(_uid);
    final usedColors = existing
        .where((s) => s.colorHex != null)
        .map((s) => s.colorHex!)
        .toList();
    final subject = SubjectModel(
      id: _uuid.v4(),
      name: name,
      attendedClasses: attendedClasses,
      totalClasses: totalClasses,
      faculty: faculty,
      createdAt: now,
      updatedAt: now,
      colorHex: colorHex ?? nextSubjectColor(usedColors),
      shortName: shortName ?? generateSubjectShortName(name),
    );
    await _db.addSubject(_uid, subject);
  }

  /// One-time backfill: patches any subject missing [colorHex] or [shortName].
  /// Safe to call repeatedly — only writes subjects that actually need patching.
  /// Call once after subjects first load to fix data created before this fix.
  Future<void> backfillSubjectMetadata() async {
    final subjects = await _db.getSubjects(_uid);
    final needsPatch = subjects
        .where((s) => s.colorHex == null || s.shortName == null)
        .toList();
    if (needsPatch.isEmpty) return;

    // Build a list of already-assigned colors so cycling still picks unique ones.
    final usedColors = subjects
        .where((s) => s.colorHex != null)
        .map((s) => s.colorHex!)
        .toList();

    for (final s in needsPatch) {
      final color = s.colorHex ?? nextSubjectColor(usedColors);
      if (s.colorHex == null) usedColors.add(color); // claim slot
      await _db.updateSubject(
        _uid,
        s.copyWith(
          colorHex: color,
          shortName: s.shortName ?? generateSubjectShortName(s.name),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Updates a subject and propagates any name change to all dependent collections.
  ///
  /// TASK 2: Rename propagation via [SubjectCascadeService.propagateRename].
  Future<void> updateSubject(SubjectModel updated) async {
    // Fetch the current subject BEFORE writing the update
    final existing = await _db.getSubjectById(_uid, updated.id);

    await _db.updateSubject(_uid, updated.copyWith(updatedAt: DateTime.now()));

    // If the name changed, propagate to all dependent collections.
    // Pass BOTH the old name (for legacy rows without subjectId) and new name.
    if (existing != null && existing.name != updated.name) {
      await _cascade.propagateRename(
        _uid,
        updated.id,
        oldName: existing.name,
        newName: updated.name,
      );
    }
  }

  /// Deletes a subject with full cascade — removes all dependent data.
  ///
  /// TASK 3: Delete cascade via [SubjectCascadeService.cascadeDelete].
  /// Cascade runs BEFORE the subject document is deleted so the subject
  /// can still be referenced during the cascade queries.
  Future<void> deleteSubject(String subjectId) async {
    // Fetch name before deletion so cascade can match legacy entries by name
    final subject = await _db.getSubjectById(_uid, subjectId);

    // Run cascade first (removes sessions, archives logs, removes entries/overrides)
    await _cascade.cascadeDelete(_uid, subjectId, subjectName: subject?.name);

    // Then delete the source-of-truth subject document
    await _db.deleteSubject(_uid, subjectId);
  }
}
