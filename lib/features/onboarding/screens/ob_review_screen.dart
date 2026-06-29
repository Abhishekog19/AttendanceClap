import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/timetable_entry_model.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

// Module-level provider so it can be watched reactively from build().
final _timetableEntriesProvider =
    StreamProvider.autoDispose<List<TimetableEntry>>((ref) {
  return ref.watch(timetableRepositoryProvider).watchTimetableEntries();
});

class ObReviewScreen extends ConsumerWidget {
  const ObReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    // Read timetable entries from Firestore for the review cards
    final timetableAsync = ref.watch(_timetableEntriesProvider);

    final fmt = DateFormat('d MMM yyyy');

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.review),
      totalSteps: OnboardingStep.all.length,
      onBack: () => context.go(OnboardingStep.routeFor(OnboardingStep.import)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Review your\nsetup',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Everything looks good? Hit Confirm to start tracking your attendance.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

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
                _EmptyChip('Not set'),
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
                ? [_EmptyChip('None added')]
                : state.subjects
                    .map((s) => _ReviewRow(s.name,
                        '${(s.attendanceTarget ?? state.attendanceGoal).round()}%'))
                    .toList(),
          ),
          const SizedBox(height: 12),

          // ── Timetable card ───────────────────────────────────────
          _ReviewCard(
            icon: Icons.schedule_rounded,
            title: 'Timetable',
            onEdit: () =>
                context.go(OnboardingStep.routeFor(OnboardingStep.timetable)),
            children: [
              timetableAsync.when(
                data: (entries) => entries.isEmpty
                    ? _EmptyChip(state.timetableSkipped ? 'Skipped' : 'Empty')
                    : _ReviewRow(
                        'Classes/week', '${entries.length} slots'),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => _EmptyChip('Error loading'),
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
        color: OnboardingColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OnboardingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 18, color: OnboardingColors.textPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: OnboardingColors.textPrimary,
                      )),
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: OnboardingColors.textSecondary,
                  ),
                  child: Text('Edit',
                      style: GoogleFonts.inter(fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: OnboardingColors.divider),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: OnboardingColors.textSecondary,
              )),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: OnboardingColors.textPrimary,
              )),
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
        color: OnboardingColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: OnboardingColors.textSecondary,
          )),
    );
  }
}
