import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/app_notification_model.dart';
import '../providers/app_notification_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationCenterScreen
//
// Displays all user notifications grouped by:
//   • Today
//   • Yesterday
//   • Older
//
// Features:
//   - Mark as read on tap
//   - Swipe-to-dismiss to delete
//   - "Mark all as read" action
//   - Read/unread visual indicator
//   - Empty state
// ─────────────────────────────────────────────────────────────────────────────

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(appNotificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          'Notifications',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        actions: [
          notificationsAsync.whenOrNull(
                data: (notifications) {
                  final hasUnread = notifications.any((n) => !n.isRead);
                  if (!hasUnread) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () => ref
                        .read(appNotificationNotifierProvider.notifier)
                        .markAllAsRead(),
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.labelMd.copyWith(color: primary),
                    ),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load notifications.',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.error),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyNotificationsState(
              isDark: isDark,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            );
          }

          // Group notifications
          final grouped = _groupNotifications(notifications);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: _countItems(grouped),
            itemBuilder: (context, index) {
              final item = _getItem(grouped, index);

              if (item is String) {
                // Section header
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                  child: Text(
                    item.toUpperCase(),
                    style: AppTextStyles.labelCaps.copyWith(
                      color: onSurfaceVariant,
                    ),
                  ),
                );
              }

              final notification = item as AppNotificationModel;
              return _NotificationTile(
                notification: notification,
                isDark: isDark,
                primary: primary,
                onSurface: onSurface,
                onSurfaceVariant: onSurfaceVariant,
                onTap: () {
                  if (!notification.isRead) {
                    ref
                        .read(appNotificationNotifierProvider.notifier)
                        .markAsRead(notification.id);
                  }
                },
                onDismissed: () {
                  ref
                      .read(appNotificationNotifierProvider.notifier)
                      .deleteNotification(notification.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Grouping logic ──────────────────────────────────────────────────────────

  Map<String, List<AppNotificationModel>> _groupNotifications(
      List<AppNotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<AppNotificationModel>>{
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    for (final n in notifications) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        groups['Today']!.add(n);
      } else if (d == yesterday) {
        groups['Yesterday']!.add(n);
      } else {
        groups['Older']!.add(n);
      }
    }

    // Remove empty groups
    groups.removeWhere((_, list) => list.isEmpty);
    return groups;
  }

  int _countItems(Map<String, List<AppNotificationModel>> grouped) {
    int count = 0;
    for (final entry in grouped.entries) {
      count += 1 + entry.value.length; // 1 header + n items
    }
    return count;
  }

  Object _getItem(
      Map<String, List<AppNotificationModel>> grouped, int index) {
    int i = 0;
    for (final entry in grouped.entries) {
      if (i == index) return entry.key; // header
      i++;
      for (final n in entry.value) {
        if (i == index) return n;
        i++;
      }
    }
    throw RangeError('Index $index out of range');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotificationTile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final unreadBg =
        isDark ? primary.withAlpha(20) : primary.withAlpha(12);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error.withAlpha(200),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 3,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: notification.isRead ? cardBg : unreadBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: notification.isRead
                ? null
                : Border.all(
                    color: primary.withAlpha(60),
                    width: 1,
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor(notification.type).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(notification.type),
                  color: _typeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyLg.copyWith(
                              color: onSurface,
                              fontWeight: notification.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySm.copyWith(
                        color: onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: AppTextStyles.labelMd.copyWith(
                        color: onSurfaceVariant.withAlpha(150),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.attendanceWarning => Icons.warning_amber_rounded,
      AppNotificationType.classReminder => Icons.schedule_rounded,
      AppNotificationType.safeBunk => Icons.event_available_rounded,
      AppNotificationType.delay => Icons.update_rounded,
      AppNotificationType.subscription => Icons.workspace_premium_rounded,
      AppNotificationType.system => Icons.info_outline_rounded,
    };
  }

  Color _typeColor(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.attendanceWarning => AppColors.warning,
      AppNotificationType.classReminder => AppColors.primary,
      AppNotificationType.safeBunk => AppColors.success,
      AppNotificationType.delay => AppColors.tertiary,
      AppNotificationType.subscription => AppColors.tertiary,
      AppNotificationType.system => AppColors.onSurfaceVariant,
    };
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyNotificationsState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNotificationsState extends StatelessWidget {
  final bool isDark;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _EmptyNotificationsState({
    required this.isDark,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: onSurfaceVariant.withAlpha(120),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No notifications yet',
            style: AppTextStyles.headlineMd.copyWith(color: onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Attendance alerts and reminders\nwill appear here.',
            style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
