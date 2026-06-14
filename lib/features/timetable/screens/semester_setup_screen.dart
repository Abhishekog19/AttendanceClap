import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../providers/semester_provider.dart';
import '../providers/timetable_ocr_provider.dart';

class SemesterSetupScreen extends ConsumerWidget {
  const SemesterSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semState = ref.watch(semesterNotifierProvider);
    final entries = ref.watch(editedTimetableProvider).values
        .expand((e) => e)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final surface =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final estimatedSessions =
        ref.read(semesterNotifierProvider.notifier).estimateSessions(entries);

    // Navigate on success
    ref.listen(semesterNotifierProvider, (prev, next) {
      if (prev?.generatedCount == null && next.generatedCount != null) {
        context.pushReplacement('/timetable/schedule-preview');
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Semester Setup',
          style: AppTextStyles.headlineMd.copyWith(color: onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.15),
                    primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-generate your semester',
                          style: AppTextStyles.bodyLg.copyWith(
                              color: onSurface, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Set the date range and we\'ll create all recurring '
                          'class sessions automatically.',
                          style: AppTextStyles.bodySm.copyWith(
                              color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Date pickers ─────────────────────────────────────────────
            Text(
              'Semester Duration',
              style: AppTextStyles.labelMd.copyWith(color: onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),

            _DatePickerCard(
              label: 'Semester Start Date',
              date: semState.startDate,
              icon: Icons.event_available,
              onTap: () => _pickDate(context, ref, isStart: true),
              surface: surface,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
              primary: primary,
            ),
            const SizedBox(height: AppSpacing.md),
            _DatePickerCard(
              label: 'Semester End Date',
              date: semState.endDate,
              icon: Icons.event_busy,
              onTap: () => _pickDate(context, ref, isStart: false),
              surface: surface,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
              primary: primary,
            ),

            // ── Duration preview ─────────────────────────────────────────
            if (semState.isValid) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${semState.estimatedWeeks} weeks · ~$estimatedSessions sessions '
                        'will be generated',
                        style: AppTextStyles.bodySm.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // ── Holidays ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Holidays (optional)',
                  style: AppTextStyles.labelMd.copyWith(
                      color: onSurfaceVariant),
                ),
                TextButton.icon(
                  onPressed: () => _pickHoliday(context, ref, semState),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(foregroundColor: primary),
                ),
              ],
            ),

            if (semState.holidays.isEmpty)
              Text(
                'No holidays added yet',
                style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: semState.holidays.map((holiday) {
                  return Chip(
                    label: Text(
                      DateFormat('MMM d').format(holiday),
                      style: AppTextStyles.bodySm,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      ref
                          .read(semesterNotifierProvider.notifier)
                          .removeHoliday(holiday);
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Generate button ──────────────────────────────────────────
            if (semState.isGenerating)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: semState.generationProgress > 0
                        ? semState.generationProgress
                        : null,
                    backgroundColor: primary.withValues(alpha: 0.1),
                    color: primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Generating ${(semState.generationProgress * 100).toInt()}% complete…',
                    style: AppTextStyles.bodySm.copyWith(
                        color: onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: semState.isValid
                      ? () => _generate(ref, entries)
                      : null,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Generate Semester Schedule'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : now.add(const Duration(days: 120)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      final notifier = ref.read(semesterNotifierProvider.notifier);
      if (isStart) {
        notifier.setStartDate(picked);
      } else {
        notifier.setEndDate(picked);
      }
    }
  }

  Future<void> _pickHoliday(
    BuildContext context,
    WidgetRef ref,
    SemesterFormState state,
  ) async {
    if (!state.isValid) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: state.startDate!,
      firstDate: state.startDate!,
      lastDate: state.endDate!,
    );
    if (picked != null) {
      ref.read(semesterNotifierProvider.notifier).addHoliday(picked);
    }
  }

  Future<void> _generate(WidgetRef ref, List<TimetableEntry> entries) async {
    final repo = ref.read(timetableRepositoryProvider);
    await ref.read(semesterNotifierProvider.notifier).generateSchedule(
          entries: entries,
          repo: repo,
        );
  }
}

// ── Date Picker Card ──────────────────────────────────────────────────────────

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, color: date != null ? primary : onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.bodySm.copyWith(
                            color: onSurfaceVariant)),
                    Text(
                      date != null
                          ? DateFormat('EEE, MMM d yyyy').format(date!)
                          : 'Tap to select',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: date != null ? onSurface : onSurfaceVariant,
                        fontWeight: date != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_calendar_outlined,
                  color: onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}


