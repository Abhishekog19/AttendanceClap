import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/subject_model.dart';
import '../../../data/repositories/subject_repository.dart';

part 'subjects_provider.g.dart';

@riverpod
class SubjectsNotifier extends _$SubjectsNotifier {
  @override
  AsyncValue<List<SubjectModel>> build() {
    final stream = ref.watch(subjectRepositoryProvider).watchSubjects();
    return ref.watch(
      StreamProvider((ref) => stream).select((v) => v),
    );
  }

  Future<void> addSubject({
    required String name,
    int attended = 0,
    int total = 0,
    String? faculty,
  }) async {
    await AsyncValue.guard(
      () => ref.read(subjectRepositoryProvider).addSubject(
            name: name,
            attendedClasses: attended,
            totalClasses: total,
            faculty: faculty,
          ),
    );
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await ref.read(subjectRepositoryProvider).updateSubject(subject);
  }

  Future<void> deleteSubject(String subjectId) async {
    await ref.read(subjectRepositoryProvider).deleteSubject(subjectId);
  }
}
