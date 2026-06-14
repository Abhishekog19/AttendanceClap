import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Skeleton loading card matching subject card dimensions
class SubjectCardSkeleton extends StatelessWidget {
  const SubjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ShimmerWrapper(
      isDark: isDark,
      child: Column(
        children: List.generate(3, (_) => _buildCard(isDark)),
      ),
    );
  }

  Widget _buildCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _box(width: 140, height: 20, isDark: isDark),
              _box(width: 40, height: 20, isDark: isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _box(width: 100, height: 14, isDark: isDark),
          const SizedBox(height: AppSpacing.sm),
          _box(width: double.infinity, height: 8, isDark: isDark),
        ],
      ),
    );
  }

  Widget _box({required double width, required double height, required bool isDark}) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ShimmerWrapper extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _ShimmerWrapper({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
      highlightColor: isDark ? const Color(0xFF3A3D4A) : AppColors.surfaceContainerLowest,
      child: child,
    );
  }
}

/// Full-page loading skeleton for dashboard
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ShimmerWrapper(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Hero card skeleton
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // CTA button skeleton
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SubjectCardSkeleton(),
          ],
        ),
      ),
    );
  }
}
