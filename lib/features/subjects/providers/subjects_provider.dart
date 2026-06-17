import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/subject_model.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';

part 'subjects_provider.g.dart';

// ── TASK 9 FIX: Removed the inline anonymous StreamProvider anti-pattern.
// SubjectsNotifier.build() now watches the top-level subjectsStreamProvider
// from dashboard_provider.dart — a single, stable Riverpod-managed listener.
// Previously, each rebuild of SubjectsNotifier instantiated a new StreamProvider
// inside build(), which could silently recreate the Firestore listener.

@riverpod
class SubjectsNotifier extends _$SubjectsNotifier {
  @override
  AsyncValue<List<SubjectModel>> build() {
    // Watch the top-level stream provider — never recreated on rebuild.
    return ref.watch(subjectsStreamProvider);
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
