import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../notifications/models/app_notification_model.dart';
import '../../notifications/providers/app_notification_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecentNotificationsCard
//
// Shows the latest 3–5 persistent notifications on the Home page.
// Powered entirely by appNotificationsProvider (already streaming, zero
// additional Firestore reads). Hidden when no notifications exist.
// Tapping any row or "See All" navigates to the full Notification Center.
// ─────────────────────────────────────────────────────────────────────────────

class RecentNotificationsCard extends ConsumerWidget {
  const RecentNotificationsCard({super.key});

  static const _maxItems = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(appNotificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return streamAsync.when(
      loading: () => _buildSkeleton(isDark),
      error: (_, __) => const SizedBox.shrink(),
      data: (notifications) {
        if (notifications.isEmpty) return const SizedBox.shrink();
        final visible = notifications.take(_maxItems).toList();
        return _buildCard(context, visible, isDark, primary);
      },
    );
  }

  // ── Main card ─────────────────────────────────────────────────────────────

  Widget _buildCard(
    BuildContext context,
    List<AppNotificationModel> notifications,
    bool isDark,
    Color primary,
  ) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: AppTextStyles.headlineMd.copyWith(color: onSurface),
            ),
            TextButton(
              onPressed: () => context.push('/notifications/center'),
              child: Text(
                'See All',
                style: AppTextStyles.labelMd.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Notification rows ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < notifications.length; i++) ...[
                _NotificationRow(
                  notification: notifications[i],
                  isDark: isDark,
                  primary: primary,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  onTap: () => context.push('/notifications/center'),
                ),
                if (i < notifications.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    color: borderColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Loading skeleton (3 shimmer rows) ────────────────────────────────────

  Widget _buildSkeleton(bool isDark) {
    final shimmer = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerLow;
    final borderColor =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header placeholder
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 18,
              width: 160,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              height: 14,
              width: 50,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: List.generate(
              3,
              (i) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: shimmer,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: shimmer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 10,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: shimmer.withAlpha(160),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < 2)
                    Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      color: borderColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotificationRow — single row in the Recent Notifications card
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationRow extends StatelessWidget {
  final AppNotificationModel notification;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final VoidCallback onTap;

  const _NotificationRow({
    required this.notification,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _typeColor(notification.type).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _typeIcon(notification.type),
                color: _typeColor(notification.type),
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Title + body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: onSurface,
                      fontWeight: notification.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: AppTextStyles.bodySm.copyWith(
                        color: onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Timestamp + unread dot column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(notification.createdAt),
                  style: AppTextStyles.labelMd.copyWith(
                    color: onSurfaceVariant.withAlpha(150),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                if (!notification.isRead)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 7, height: 7),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(AppNotificationType type) => switch (type) {
        AppNotificationType.attendanceDanger => Icons.warning_amber_rounded,
        AppNotificationType.criticalAttendance => Icons.crisis_alert_rounded,
        AppNotificationType.nightlyBunkPlanner => Icons.event_available_rounded,
        AppNotificationType.system => Icons.info_outline_rounded,
      };

  Color _typeColor(AppNotificationType type) => switch (type) {
        AppNotificationType.attendanceDanger => AppColors.warning,
        AppNotificationType.criticalAttendance => AppColors.error,
        AppNotificationType.nightlyBunkPlanner => AppColors.success,
        AppNotificationType.system => AppColors.onSurfaceVariant,
      };

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
