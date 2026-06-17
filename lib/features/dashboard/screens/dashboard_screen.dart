import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../features/notifications/providers/app_notification_provider.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/hero_attendance_card.dart';
import '../widgets/subject_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(subjectsStreamProvider),
        color: primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Sticky Top App Bar ──────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: bg.withAlpha(230),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isDark
                        ? AppColors.darkPrimaryContainer.withAlpha(80)
                        : AppColors.primaryFixed,
                    child: user?.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              user!.photoURL!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Text(user.displayName?.substring(0, 1).toUpperCase() ?? 'A',
                                      style: TextStyle(color: primary)),
                            ),
                          )
                        : Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ?? 'A',
                            style: AppTextStyles.bodyLg.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: AppTextStyles.labelMd.copyWith(color: onSurfaceVariant),
                      ),
                      Text(
                        user?.displayName?.split(' ').first ?? 'Student',
                        style: AppTextStyles.bodyLg.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                _NotificationBell(primary: primary),
              ],
            ),

            // ─── Main Content ────────────────────────────────────────────────
            dashboardAsync.when(
              loading: () => const SliverFillRemaining(child: DashboardSkeleton()),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Error: $e',
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.error)),
                ),
              ),
              data: (data) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero card
                    HeroAttendanceCard(
                      overallPercentage: data.overallPercentage,
                      safeBunks: data.safeBunks,
                      classesNeeded: data.classesNeeded,
                      targetPercent: data.attendanceGoal,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Can I Bunk Tomorrow CTA
                    _BunkTomorrowButton(bunkStatus: data.bunkStatus),
                    const SizedBox(height: AppSpacing.lg),

                    // Subject Overview Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subject Overview',
                          style: AppTextStyles.headlineMd.copyWith(color: onSurface),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => context.push('/attendance/history'),
                              child: Text(
                                'History',
                                style: AppTextStyles.labelMd.copyWith(
                                  color: onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/subjects'),
                              child: Text(
                                'View All',
                                style: AppTextStyles.labelMd.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (data.subjects.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.menu_book_outlined,
                        title: 'No subjects yet',
                        subtitle: 'Add your first subject to start tracking attendance',
                        actionLabel: 'Add Subject',
                        onAction: () => context.push('/subjects/add'),
                      )
                    else
                      ...data.subjects.take(5).map(
                            (subject) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: SubjectCard(
                                subject: subject,
                                targetPercent: data.attendanceGoal,
                                onTap: () => context.push('/subjects/detail', extra: subject),
                              ),
                            ),
                          ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Bell with Badge ─────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  final Color primary;
  const _NotificationBell({required this.primary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: primary),
          onPressed: () => context.push('/notifications/center'),
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: unreadCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: unreadCount > 9 ? BorderRadius.circular(9) : null,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BunkTomorrowButton extends StatelessWidget {
  final BunkStatus bunkStatus;

  const _BunkTomorrowButton({required this.bunkStatus});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bg, fg) = switch (bunkStatus) {
      BunkStatus.safe => (
          isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer,
          Colors.white,
        ),
      BunkStatus.risky => (AppColors.warningContainer, AppColors.onWarningContainer),
      BunkStatus.mustAttend => (AppColors.errorContainer, AppColors.onErrorContainer),
    };

    return GestureDetector(
      onTap: () => _showBunkSheet(context, bunkStatus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary).withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Can I Bunk Tomorrow?',
              style: AppTextStyles.headlineMd.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }

  void _showBunkSheet(BuildContext context, BunkStatus status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BunkResultSheet(status: status),
    );
  }
}

class _BunkResultSheet extends StatelessWidget {
  final BunkStatus status;
  const _BunkResultSheet({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;

    final (icon, title, subtitle, iconColor) = switch (status) {
      BunkStatus.safe => (
          Icons.check_circle_rounded,
          'Safe to Bunk!',
          'You have enough buffer. Enjoy your day off.',
          AppColors.success,
        ),
      BunkStatus.risky => (
          Icons.warning_rounded,
          'Risky Bunk',
          'You\'re close to the limit. Think twice before skipping.',
          AppColors.warning,
        ),
      BunkStatus.mustAttend => (
          Icons.cancel_rounded,
          'Must Attend!',
          'Missing this class will drop you below your target.',
          AppColors.error,
        ),
    };

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: iconColor),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.bodyLg.copyWith(
              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
