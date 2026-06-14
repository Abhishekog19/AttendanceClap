import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    const features = [
      'Unlimited subjects tracking',
      'AI-powered bunk predictions',
      'Advanced analytics & charts',
      'Attendance heatmap',
      'Export attendance reports',
      'Priority customer support',
      'Custom attendance goals',
      'Offline mode support',
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('Go Premium',
            style: AppTextStyles.headlineMd.copyWith(color: primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // ─── Hero ────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'AttendanceAI Premium',
                    style: AppTextStyles.headlineLgMobile.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Unlock the full power of AI-driven attendance tracking',
                    style: AppTextStyles.bodyLg.copyWith(color: Colors.white.withAlpha(220)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ─── Features List ───────────────────────────────────────────────
            Text('Everything You Get', style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
            const SizedBox(height: AppSpacing.md),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer.withAlpha(80)
                          : AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 14, color: primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(f, style: AppTextStyles.bodyLg.copyWith(color: onSurface)),
                ],
              ),
            )),
            const SizedBox(height: AppSpacing.xl),

            // ─── Pricing Plans ───────────────────────────────────────────────
            Text('Choose Your Plan', style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
            const SizedBox(height: AppSpacing.md),

            // Monthly Plan
            _PlanCard(
              title: 'Monthly',
              price: '₹20',
              period: '/month',
              subtitle: 'Billed monthly',
              isHighlighted: false,
              isDark: isDark,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.md),

            // Yearly Plan (highlighted)
            Stack(
              children: [
                _PlanCard(
                  title: 'Annual',
                  price: '₹200',
                  period: '/year',
                  subtitle: 'Just ₹16.67/month • Save 17%',
                  isHighlighted: true,
                  isDark: isDark,
                  onTap: () {},
                ),
                Positioned(
                  top: -1,
                  right: AppSpacing.lg,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'BEST VALUE',
                      style: AppTextStyles.labelCaps.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Cancel anytime. No questions asked.',
              style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String subtitle;
  final bool isHighlighted;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.subtitle,
    required this.isHighlighted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final cardBg = isHighlighted
        ? (isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer)
        : (isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest);
    final borderColor = isHighlighted ? primary : (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant);
    final textColor = isHighlighted ? Colors.white : (isDark ? AppColors.darkOnSurface : AppColors.onSurface);
    final subtitleColor = isHighlighted ? Colors.white.withAlpha(200) : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: borderColor,
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.headlineMd.copyWith(color: textColor)),
                  Text(subtitle,
                      style: AppTextStyles.bodySm.copyWith(color: subtitleColor)),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: AppTextStyles.displayLg.copyWith(
                      color: textColor, fontSize: 36)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(period,
                      style: AppTextStyles.bodySm.copyWith(color: subtitleColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
