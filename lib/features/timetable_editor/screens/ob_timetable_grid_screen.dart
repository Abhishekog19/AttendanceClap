/// Onboarding Timetable Grid Screen
///
/// Thin wrapper around TimetableGrid for the onboarding flow.
/// Bridges subjects from OnboardingNotifier → TimetableEditorNotifier on first load.
/// Calls advanceStep('timetable') when the user taps "Finish Setup".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/onboarding/providers/onboarding_notifier.dart';
import '../../../features/onboarding/providers/onboarding_state.dart';

import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';
import '../widgets/timetable_grid.dart';

class ObTimetableGridScreen extends ConsumerStatefulWidget {
  const ObTimetableGridScreen({super.key});

  @override
  ConsumerState<ObTimetableGridScreen> createState() =>
      _ObTimetableGridScreenState();
}

class _ObTimetableGridScreenState extends ConsumerState<ObTimetableGridScreen> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    // Seed subjects from onboarding into the timetable editor on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedSubjects());
  }

  Future<void> _seedSubjects() async {
    if (_seeded) return;
    _seeded = true;

    final obSubjects =
        ref.read(onboardingNotifierProvider).subjects;
    if (obSubjects.isEmpty) return;

    final usedColors = <String>[];
    final timetableSubjects = obSubjects.map((s) {
      final color = nextSubjectColor(usedColors);
      usedColors.add(color);
      return TimetableSubject(
        id: s.id,
        name: s.name,
        shortName: generateShortName(s.name),
        colorHex: color,
        minAttendanceRequired: s.attendanceTarget,
      );
    }).toList();

    await ref
        .read(timetableEditorNotifierProvider.notifier)
        .seedSubjectsIfEmpty(timetableSubjects);
  }

  Future<void> _onFinish() async {
    final obNotifier = ref.read(onboardingNotifierProvider.notifier);
    // Mark timetable step as complete — advances to holidays
    await obNotifier.advanceStep(OnboardingStep.timetable);
    if (mounted) {
      context.go(OnboardingStep.routeFor(OnboardingStep.holidays));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TimetableGrid(
      mode: TimetableGridMode.onboarding,
      onFinish: _onFinish,
    );
  }
}
