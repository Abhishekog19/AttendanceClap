import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/dashboard'),
    _NavTab(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Schedule', path: '/timetable'),
    _NavTab(icon: Icons.query_stats_outlined, activeIcon: Icons.query_stats, label: 'Predictor', path: '/predictor'),
    _NavTab(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: 'Analytics', path: '/analytics'),
    _NavTab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withAlpha(230)
              : AppColors.surface.withAlpha(230),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppSpacing.bottomNavHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == current;
                final color = isActive
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : (isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant);

                return GestureDetector(
                  onTap: () => context.go(tab.path),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            key: ValueKey(isActive),
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: AppTextStyles.labelMd.copyWith(
                            color: color,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
