import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../features/premium/providers/premium_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  double _localGoal = 75.0;
  bool _goalDirty = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final premiumState = ref.watch(premiumNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final cardBg = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;

    final goal = profileAsync.valueOrNull?.attendanceGoal ?? 75.0;
    if (!_goalDirty) _localGoal = goal;

    final themeMode = profileAsync.valueOrNull?.themeMode ?? 'system';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Profile', style: AppTextStyles.headlineMd.copyWith(color: primary)),
        actions: [
          if (!premiumState.isPremium)
            IconButton(
              icon: Icon(Icons.workspace_premium_outlined, color: primary),
              tooltip: 'Go Premium',
              onPressed: () => context.push('/premium'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 100),
        children: [
          // ─── Avatar / Name / Email ─────────────────────────────────────────
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: isDark
                      ? AppColors.darkPrimaryContainer.withAlpha(80)
                      : AppColors.primaryFixed,
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ?? 'A',
                          style: AppTextStyles.headlineLg.copyWith(color: primary),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user?.displayName ?? profileAsync.valueOrNull?.name ?? 'Student',
                  style: AppTextStyles.headlineMd.copyWith(color: onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? profileAsync.valueOrNull?.email ?? '',
                  style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── Attendance Goal ───────────────────────────────────────────────
          _SectionLabel('Attendance Goal', isDark),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target Attendance',
                        style: AppTextStyles.bodyLg.copyWith(color: onSurface)),
                    Text(
                      '${_localGoal.round()}%',
                      style: AppTextStyles.headlineMd.copyWith(color: primary),
                    ),
                  ],
                ),
                Slider(
                  value: _localGoal,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  activeColor: primary,
                  inactiveColor: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.surfaceContainerHigh,
                  onChanged: (v) => setState(() {
                    _localGoal = v;
                    _goalDirty = true;
                  }),
                  onChangeEnd: (v) {
                    ref.read(profileNotifierProvider.notifier).updateGoal(v);
                    setState(() => _goalDirty = false);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Settings ─────────────────────────────────────────────────────
          _SectionLabel('Appearance', isDark),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _ThemeOptionTile(
                  title: 'System Default',
                  icon: Icons.brightness_auto_outlined,
                  value: 'system',
                  groupValue: themeMode,
                  primary: primary,
                  onSurface: onSurface,
                  onChanged: (v) => ref.read(profileNotifierProvider.notifier).updateTheme(v!),
                ),
                Divider(height: 1, indent: AppSpacing.md, color: borderColor),
                _ThemeOptionTile(
                  title: 'Light Mode',
                  icon: Icons.light_mode_outlined,
                  value: 'light',
                  groupValue: themeMode,
                  primary: primary,
                  onSurface: onSurface,
                  onChanged: (v) => ref.read(profileNotifierProvider.notifier).updateTheme(v!),
                ),
                Divider(height: 1, indent: AppSpacing.md, color: borderColor),
                _ThemeOptionTile(
                  title: 'Dark Mode',
                  icon: Icons.dark_mode_outlined,
                  value: 'dark',
                  groupValue: themeMode,
                  primary: primary,
                  onSurface: onSurface,
                  onChanged: (v) => ref.read(profileNotifierProvider.notifier).updateTheme(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── More ─────────────────────────────────────────────────────────
          _SectionLabel('More', isDark),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _PremiumSettingsTile(
                  premiumState: premiumState,
                  isDark: isDark,
                  primary: primary,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  onTap: () => context.push('/premium'),
                ),
                Divider(height: 1, indent: AppSpacing.md, color: borderColor),
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  iconColor: onSurfaceVariant,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  onTap: () {},
                ),
                Divider(height: 1, indent: AppSpacing.md, color: borderColor),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About AttendanceAI',
                  subtitle: 'Version 1.0.0',
                  iconColor: onSurfaceVariant,
                  onSurface: onSurface,
                  onSurfaceVariant: onSurfaceVariant,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── Sign Out ─────────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Sign Out',
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.error, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error.withAlpha(100)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profileNotifierProvider.notifier).signOut();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTextStyles.labelCaps.copyWith(
          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
        ),
      );
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String groupValue;
  final Color primary;
  final Color onSurface;
  final ValueChanged<String?> onChanged;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.primary,
    required this.onSurface,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ListTile(
      leading: Icon(icon, color: isSelected ? primary : onSurface),
      title: Text(title,
          style: AppTextStyles.bodyLg.copyWith(
            color: onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          )),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? primary : onSurface.withAlpha(100),
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : null,
      ),
      onTap: () => onChanged(value),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color onSurface;
  final Color onSurfaceVariant;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: AppTextStyles.bodyLg.copyWith(color: onSurface)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant))
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: onSurfaceVariant),
        onTap: onTap,
      );
}

// ─── Premium Settings Tile (3-state) ──────────────────────────────────────────

class _PremiumSettingsTile extends StatelessWidget {
  final PremiumState premiumState;
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final VoidCallback onTap;

  const _PremiumSettingsTile({
    required this.premiumState,
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ── Annual subscriber — show active status, no action needed ──────────
    if (premiumState.isPremium && premiumState.planType == 'annual') {
      return ListTile(
        leading: const Icon(Icons.verified_rounded, color: AppColors.success),
        title: Text(
          'Premium Active',
          style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.success, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Annual Plan — Best value',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.success.withAlpha(180)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.successContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'ACTIVE',
            style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.success, fontSize: 10),
          ),
        ),
        onTap: onTap, // still navigable to view plan details
      );
    }

    // ── Monthly subscriber — prompt annual upgrade ─────────────────────────
    if (premiumState.isPremium && premiumState.planType == 'monthly') {
      return ListTile(
        leading: const Icon(Icons.workspace_premium_rounded,
            color: AppColors.tertiary),
        title: Text(
          'Upgrade to Annual',
          style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.tertiary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Save ₹40/year vs monthly · Best value',
          style: AppTextStyles.bodySm.copyWith(
              color: AppColors.tertiary.withAlpha(180)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.tertiary.withAlpha(80)),
          ),
          child: Text(
            'UPGRADE',
            style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.tertiary, fontSize: 10),
          ),
        ),
        onTap: onTap,
      );
    }

    // ── Free user — standard upgrade CTA ──────────────────────────────────
    return ListTile(
      leading: Icon(Icons.workspace_premium_outlined, color: primary),
      title: Text(
        'Upgrade to Premium',
        style: AppTextStyles.bodyLg.copyWith(color: onSurface),
      ),
      subtitle: Text(
        'Unlock AI predictions & more',
        style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: onSurfaceVariant),
      onTap: onTap,
    );
  }
}
