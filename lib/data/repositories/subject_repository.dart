import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/subject_model.dart';
import '../../data/datasources/firestore_datasource.dart';
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

  Future<void> updateSubject(SubjectModel subject) async {
    await _db.updateSubject(_uid, subject.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteSubject(String subjectId) async {
    await _db.deleteSubject(_uid, subjectId);
  }
}
