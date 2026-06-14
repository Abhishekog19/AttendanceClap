import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/subject_progress_bar.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../profile/providers/profile_provider.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final goal = ref.watch(attendanceGoalProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'My Subjects',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/subjects/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: subjectsAsync.when(
        loading: () => const SubjectCardSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              subtitle: 'Tap the + button to add your first subject',
              actionLabel: 'Add Subject',
              onAction: () => context.push('/subjects/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 100,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, i) {
              final subject = subjects[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: GestureDetector(
                  onTap: () => context.push('/subjects/detail', extra: subject),
                  child: _SubjectListTile(
                    subject: subject,
                    goal: goal,
                    onEdit: () => context.push('/subjects/edit', extra: subject),
                    onDelete: () => _confirmDelete(context, ref, subject),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(subjectRepositoryProvider).deleteSubject(subject.id);
    }
  }
}

class _SubjectListTile extends StatelessWidget {
  final SubjectModel subject;
  final double goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectListTile({
    required this.subject,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = subject.attendancePercentage;
    final cardBg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final safeBunks = AttendanceCalculator.getSafeBunks(
      attended: subject.attendedClasses,
      total: subject.totalClasses,
      targetPercent: goal,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name,
                        style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
                    if (subject.faculty != null)
                      Text(subject.faculty!,
                          style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: AppTextStyles.headlineMd.copyWith(color: onSurface),
              ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: onSurfaceVariant),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${subject.attendedClasses} of ${subject.totalClasses} classes • $safeBunks safe bunks left',
            style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          SubjectProgressBar(percentage: pct, targetPercent: goal),
        ],
      ),
    );
  }
}
