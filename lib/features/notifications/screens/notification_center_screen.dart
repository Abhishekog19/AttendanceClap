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
// Displays notifications grouped by:
//   • Today
//   • This Week  (last 7 days, not today)
//   • This Month (current month, not this week)
//   • Older
//
// Pagination: initial 20 notifications + "Load more" button.
// First page is real-time (new notifications appear instantly).
// Older pages fetched on demand via Firestore cursor pagination.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(notificationPaginationProvider);
    // N4 FIX: watch the raw stream to distinguish "loading" from "empty".
    // Previously notifications.isEmpty triggered the empty state while the
    // stream was still fetching — causing a visible flash of the empty screen.
    final streamAsync = ref.watch(appNotificationsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final notifications = pageState.notifications;
    // N3 badge display: show ’99+’ when count is at the limit (100)
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
    final hasUnread = unreadCount > 0;

    Widget body;
    if (streamAsync.isLoading && notifications.isEmpty) {
      // Stream is still fetching — show skeleton, not empty state
      body = _NotificationLoadingSkeleton(isDark: isDark);
    } else if (notifications.isEmpty) {
      body = _EmptyNotificationsState(
        isDark: isDark,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      );
    } else {
      body = _NotificationList(
        notifications: notifications,
        pageState: pageState,
        isDark: isDark,
        primary: primary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(appNotificationNotifierProvider.notifier).markAllAsRead(),
              child: Text(
                unreadCount >= 100
                    ? 'Mark all read (99+)'
                    : 'Mark all read ($unreadCount)',
                style: AppTextStyles.labelMd.copyWith(color: primary),
              ),
            ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: onSurfaceVariant),
              tooltip: 'Clear all',
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: body,
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
            'This will permanently delete all notifications. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appNotificationNotifierProvider.notifier).clearAll();
    }
  }
} // end NotificationCenterScreen

// ─────────────────────────────────────────────────────────────────────────────
// _NotificationList — grouped + paginated list
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationList extends ConsumerWidget {
  final List<AppNotificationModel> notifications;
  final NotificationPageState pageState;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _NotificationList({
    required this.notifications,
    required this.pageState,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = _groupNotifications(notifications);
    // Build the flat items list: [String header, AppNotificationModel, ...]
    final items = <Object>[];
    for (final entry in grouped.entries) {
      items.add(entry.key); // header
      items.addAll(entry.value);
    }

    // Append footer: load-more or loading indicator
    final showFooter = pageState.hasMore || pageState.isLoadingMore;

    return ListView.builder(
      padding: const EdgeInsets.only(
          top: AppSpacing.xs, bottom: AppSpacing.xl),
      itemCount: items.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        // Footer
        if (index == items.length) {
          if (pageState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: OutlinedButton(
              onPressed: () =>
                  ref.read(notificationPaginationProvider.notifier).loadMore(),
              child: const Text('Load more'),
            ),
          );
        }

        final item = items[index];

        // Section header
        if (item is String) {
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

        // Notification tile
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
  }

  // ── Grouping + priority sort: Today / This Week / This Month / Older ──────

  Map<String, List<AppNotificationModel>> _groupNotifications(
      List<AppNotificationModel> notifications) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    final groups = <String, List<AppNotificationModel>>{
      'Today': [],
      'This Week': [],
      'This Month': [],
      'Older': [],
    };

    for (final n in notifications) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (!d.isBefore(todayStart)) {
        groups['Today']!.add(n);
      } else if (!d.isBefore(weekStart)) {
        groups['This Week']!.add(n);
      } else if (!d.isBefore(monthStart)) {
        groups['This Month']!.add(n);
      } else {
        groups['Older']!.add(n);
      }
    }

    // Within each group: sort by priority DESC (critical=3 first), then timestamp DESC
    for (final key in groups.keys) {
      groups[key]!.sort((a, b) {
        final pc = b.priority.index.compareTo(a.priority.index);
        if (pc != 0) return pc;
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    groups.removeWhere((_, list) => list.isEmpty);
    return groups;
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
              // Type icon badge
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
                        // CRITICAL priority badge
                        if (notification.priority == NotificationPriority.critical)
                          Container(
                            margin: const EdgeInsets.only(left: AppSpacing.xs),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CRITICAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        // Unread dot (shown when not critical)
                        else if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets.only(left: AppSpacing.xs),
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
                      maxLines: 5,
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
      AppNotificationType.attendanceDanger  => Icons.warning_amber_rounded,
      AppNotificationType.criticalAttendance => Icons.crisis_alert_rounded,
      AppNotificationType.nightlyBunkPlanner => Icons.event_available_rounded,
      AppNotificationType.system             => Icons.info_outline_rounded,
    };
  }

  Color _typeColor(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.attendanceDanger   => AppColors.warning,
      AppNotificationType.criticalAttendance => AppColors.error,
      AppNotificationType.nightlyBunkPlanner => AppColors.success,
      AppNotificationType.system             => AppColors.onSurfaceVariant,
    };
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotificationLoadingSkeleton
// Shown while the Firestore stream is fetching on first open (N4 fix).
// Prevents the empty-state from flashing before data arrives.
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationLoadingSkeleton extends StatefulWidget {
  final bool isDark;
  const _NotificationLoadingSkeleton({required this.isDark});

  @override
  State<_NotificationLoadingSkeleton> createState() =>
      _NotificationLoadingSkeletonState();
}

class _NotificationLoadingSkeletonState
    extends State<_NotificationLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmer = widget.isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerLow;

    return FadeTransition(
      opacity: _anim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shimmer.withAlpha(180),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmer.withAlpha(200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 180,
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
      ),
    );
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
