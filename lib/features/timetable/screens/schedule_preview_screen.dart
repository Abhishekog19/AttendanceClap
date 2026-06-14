import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/semester_provider.dart';
import '../providers/timetable_ocr_provider.dart';

class SchedulePreviewScreen extends ConsumerWidget {
  const SchedulePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semState = ref.watch(semesterNotifierProvider);
    final schedule = ref.watch(editedTimetableProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final surface =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final subjects =
        schedule.values.expand((e) => e).map((e) => e.subject).toSet().toList()
          ..sort();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Schedule Created!',
          style: AppTextStyles.headlineMd.copyWith(color: onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Reset OCR state and go to root
              ref.read(timetableOcrProvider.notifier).reset();
              context.go('/dashboard');
            },
            child: Text('Done', style: TextStyle(color: primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Success banner ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '🎉 Semester Schedule Ready!',
                    style: AppTextStyles.headlineLg.copyWith(
                        color: onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${semState.generatedCount ?? 0} class sessions generated '
                    'and synced to your account.',
                    style: AppTextStyles.bodyLg.copyWith(
                        color: onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Summary stats ────────────────────────────────────────────
            Text(
              'Summary',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface),
            ),
            const SizedBox(height: AppSpacing.md),

            if (semState.startDate != null && semState.endDate != null)
              _SummaryRow(
                icon: Icons.date_range,
                label: 'Semester period',
                value:
                    '${DateFormat('MMM d').format(semState.startDate!)} – '
                    '${DateFormat('MMM d, yyyy').format(semState.endDate!)}',
                color: primary,
              ),
            _SummaryRow(
              icon: Icons.menu_book,
              label: 'Subjects created',
              value: '${subjects.length}',
              color: Colors.purple,
            ),
            _SummaryRow(
              icon: Icons.event_note,
              label: 'Total class sessions',
              value: '${semState.generatedCount ?? 0}',
              color: Colors.blue,
            ),
            _SummaryRow(
              icon: Icons.beach_access,
              label: 'Holidays excluded',
              value: '${semState.holidays.length}',
              color: Colors.orange,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Subject list ─────────────────────────────────────────────
            Text(
              'Subjects Added',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface),
            ),
            const SizedBox(height: AppSpacing.md),

            ...subjects.asMap().entries.map((e) {
              final idx = e.key;
              final subject = e.value;
              final color = _subjectColor(idx);
              final dayEntries = schedule.entries
                  .where((d) => d.value.any((entry) => entry.subject == subject))
                  .map((d) => d.key)
                  .toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Center(
                            child: Text(
                              subject.substring(0, 1).toUpperCase(),
                              style: AppTextStyles.headlineMd.copyWith(
                                  color: color),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject,
                                  style: AppTextStyles.bodyLg.copyWith(
                                      color: onSurface,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                dayEntries.join(' · '),
                                style: AppTextStyles.bodySm.copyWith(
                                    color: onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // ── Next steps ───────────────────────────────────────────────
            Text(
              'What\'s Next',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface),
            ),
            const SizedBox(height: AppSpacing.md),

            _NextStepCard(
              icon: Icons.how_to_reg,
              title: 'Mark Attendance',
              subtitle:
                  'Go to dashboard to see today\'s classes and mark attendance',
              color: primary,
              onTap: () => context.go('/dashboard'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NextStepCard(
              icon: Icons.analytics_outlined,
              title: 'View Analytics',
              subtitle:
                  'Track your attendance percentage per subject',
              color: Colors.purple,
              onTap: () => context.go('/analytics'),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(int index) {
    const colors = [
      Colors.blue, Colors.purple, Colors.teal,
      Colors.orange, Colors.pink, Colors.green,
      Colors.indigo, Colors.red, Colors.cyan,
    ];
    return colors[index % colors.length];
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant)),
          ),
          Text(value,
              style: AppTextStyles.bodyLg.copyWith(
                  color: onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Next Step Card ────────────────────────────────────────────────────────────

class _NextStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NextStepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLg.copyWith(
                            color: onSurface, fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: AppTextStyles.bodySm.copyWith(
                            color: onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}


