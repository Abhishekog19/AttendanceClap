import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../features/timetable_editor/models/timetable_editor_models.dart';
import '../../../features/timetable_editor/repository/timetable_editor_repository.dart';
import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

// Module-level provider so it can be watched reactively from build().
final _lecturesProvider =
    StreamProvider.autoDispose<List<LectureBlock>>((ref) {
  return ref.watch(timetableEditorRepositoryProvider).watchLectures();
});

class ObReviewScreen extends ConsumerWidget {
  const ObReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    // Read lecture blocks from the new canonical source
    final lecturesAsync = ref.watch(_lecturesProvider);

    final fmt = DateFormat('d MMM yyyy');

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.review),
      totalSteps: OnboardingStep.all.length,
      showSkip: true,
      skipLabel: 'Skip',
      onSkip: () => notifier.skipAllAndComplete(context),
      onBack: () => context.go(OnboardingStep.routeFor(OnboardingStep.import)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            'Review your plan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.onSurface,
              height: 1.28,
              letterSpacing: -0.28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Everything looks good? Hit Confirm to start tracking your attendance.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: OnboardingColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // ── College card ─────────────────────────────────────────
          _ReviewCard(
            icon: Icons.school_rounded,
            title: 'College',
            onEdit: () =>
                context.go(OnboardingStep.routeFor(OnboardingStep.college)),
            children: [
              if (state.collegeName.isNotEmpty)
                _ReviewRow('Institution', state.collegeName),
              if (state.courseName.isNotEmpty)
                _ReviewRow('Course', state.courseName),
              if (state.year.isNotEmpty) _ReviewRow('Year', state.year),
              if (state.section.isNotEmpty)
                _ReviewRow('Section', state.section),
              if (state.collegeName.isEmpty && state.courseName.isEmpty)
                const _EmptyChip('Not set'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Semester card ────────────────────────────────────────
          _ReviewCard(
            icon: Icons.calendar_month_rounded,
            title: 'Semester',
            onEdit: () =>
                context.go(OnboardingStep.routeFor(OnboardingStep.semester)),
            children: [
              if (state.semesterName.isNotEmpty)
                _ReviewRow('Name', state.semesterName),
              if (state.semesterStart != null)
                _ReviewRow('Starts', fmt.format(state.semesterStart!)),
              if (state.semesterEnd != null)
                _ReviewRow('Ends', fmt.format(state.semesterEnd!)),
              _ReviewRow('Goal', '${state.attendanceGoal.round()}%'),
              if (state.holidays.isNotEmpty)
                _ReviewRow('Holidays', '${state.holidays.length} marked'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Subjects card ────────────────────────────────────────
          _ReviewCard(
            icon: Icons.book_rounded,
            title: 'Subjects (${state.subjects.length})',
            onEdit: () =>
                context.go(OnboardingStep.routeFor(OnboardingStep.subjects)),
            children: state.subjects.isEmpty
                ? [const _EmptyChip('None added')]
                : state.subjects
                    .map((s) => _ReviewRow(s.name,
                        '${(s.attendanceTarget ?? state.attendanceGoal).round()}%'))
                    .toList(),
          ),
          const SizedBox(height: 12),

          // ── Timetable card ──────────────────────────────────────────────────
          _ReviewCard(
            icon: Icons.schedule_rounded,
            title: 'Timetable',
            onEdit: () =>
                context.go(OnboardingStep.routeFor(OnboardingStep.timetable)),
            children: [
              lecturesAsync.when(
                data: (lectures) => state.timetableSkipped
                    ? const _EmptyChip('Skipped')
                    : lectures.isEmpty
                        ? const _EmptyChip('Empty')
                        : _ReviewRow(
                            'Classes/week', '${lectures.length} slots'),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const _EmptyChip('Error loading'),
              ),  
            ],
          ),

          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OnboardingColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.error!,
                style: GoogleFonts.inter(
                    fontSize: 13, color: OnboardingColors.error),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
      cta: OnboardingCTAButton(
        label: 'Confirm & Launch',
        isLoading: state.isLoading,
        onPressed: () async {
          final ok = await notifier.confirmAndComplete();
          if (ok && context.mounted) {
            context.go('/onboarding/success');
          }
        },
      ),
    );
  }
}

// ─── Review card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.children,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OnboardingColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: OnboardingColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: OnboardingColors.onSurface),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: OnboardingColors.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: OnboardingColors.onSurfaceVariant,
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: OnboardingColors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: OnboardingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: OnboardingColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChip extends StatelessWidget {
  const _EmptyChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: OnboardingColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
