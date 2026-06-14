import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../data/models/subject_model.dart';
import '../../../shared/widgets/subject_progress_bar.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final double targetPercent;
  final VoidCallback? onTap;

  const SubjectCard({
    super.key,
    required this.subject,
    this.targetPercent = 75.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = subject.attendancePercentage;
    final status = AttendanceCalculator.getStatus(pct, target: targetPercent);
    final cardBg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: AppTextStyles.headlineMd.copyWith(color: onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${subject.attendedClasses} of ${subject.totalClasses} classes attended',
                        style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: AppTextStyles.headlineMd.copyWith(color: onSurface),
                    ),
                    const SizedBox(height: 2),
                    StatusChip(status: status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SubjectProgressBar(percentage: pct, targetPercent: targetPercent),
          ],
        ),
      ),
    );
  }
}
