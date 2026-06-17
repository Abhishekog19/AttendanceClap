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
  }) async {
    final now = DateTime.now();
    final subject = SubjectModel(
      id: _uuid.v4(),
      name: name,
      attendedClasses: attendedClasses,
      totalClasses: totalClasses,
      faculty: faculty,
      createdAt: now,
      updatedAt: now,
    );
    await _db.addSubject(_uid, subject);
  }

  /// Updates a subject and propagates any name change to all dependent collections.
  ///
  /// TASK 2: Rename propagation via [SubjectCascadeService.propagateRename].
  Future<void> updateSubject(SubjectModel updated) async {
    // Fetch the current name BEFORE writing the update
    final existing = await _db.getSubjectById(_uid, updated.id);

    await _db.updateSubject(_uid, updated.copyWith(updatedAt: DateTime.now()));

    // If the name changed, propagate to all dependent collections
    if (existing != null && existing.name != updated.name) {
      await _cascade.propagateRename(_uid, updated.id, updated.name);
    }
  }

  /// Deletes a subject with full cascade — removes all dependent data.
  ///
  /// TASK 3: Delete cascade via [SubjectCascadeService.cascadeDelete].
  /// Cascade runs BEFORE the subject document is deleted so the subject
  /// can still be referenced during the cascade queries.
  Future<void> deleteSubject(String subjectId) async {
    // Run cascade first (removes sessions, archives logs, removes entries/overrides)
    await _cascade.cascadeDelete(_uid, subjectId);

    // Then delete the source-of-truth subject document
    await _db.deleteSubject(_uid, subjectId);
  }
}
