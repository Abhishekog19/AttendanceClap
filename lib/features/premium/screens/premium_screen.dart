import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../providers/premium_provider.dart';
import '../services/razorpay_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  late final RazorpayService _razorpayService;
  StreamSubscription<PaymentResult>? _paymentSub;

  // Track which plan is currently being purchased
  String? _purchasingPlan;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _paymentSub = _razorpayService.results.listen(_onPaymentResult);
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    _razorpayService.dispose();
    super.dispose();
  }

  // ─── Payment Result Handlers ─────────────────────────────────────────────

  Future<void> _onPaymentResult(PaymentResult result) async {
    if (!mounted) return;

    switch (result) {
      case PaymentSuccess(:final response):
        final planType = _purchasingPlan ?? 'monthly';
        setState(() => _purchasingPlan = null);

        // Activate premium in Firestore
        await ref
            .read(premiumNotifierProvider.notifier)
            .activatePremium(planType: planType, paymentId: response.paymentId ?? '');

        if (!mounted) return;
        _showSuccessSnackbar(planType);
        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();

      case PaymentFailure(:final response):
        setState(() => _purchasingPlan = null);
        if (!mounted) return;
        _showErrorSnackbar(
          response.message ?? 'Payment failed. Please try again.',
        );

      case PaymentExternalWallet(:final response):
        setState(() => _purchasingPlan = null);
        if (!mounted) return;
        _showInfoSnackbar('Redirecting to ${response.walletName}…');
    }
  }

  void _openCheckout(String planType) {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;

    final amountInPaise = planType == 'annual' ? 20000 : 2000; // ₹200 or ₹20
    final description = planType == 'annual'
        ? 'AttendanceAI Premium — Annual Plan'
        : 'AttendanceAI Premium — Monthly Plan';

    setState(() => _purchasingPlan = planType);

    _razorpayService.openCheckout(
      amountInPaise: amountInPaise,
      description: description,
      userName: profile?.name ?? user?.displayName,
      userEmail: profile?.email ?? user?.email,
    );
  }

  // ─── Snackbars ───────────────────────────────────────────────────────────

  void _showSuccessSnackbar(String planType) {
    final label = planType == 'annual' ? 'Annual' : 'Monthly';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🎉 Welcome to Premium! $label plan activated.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final premiumState = ref.watch(premiumNotifierProvider);
    final alreadyPremium = premiumState.isPremium;
    final isMonthly = alreadyPremium && premiumState.planType == 'monthly';
    final isAnnual  = alreadyPremium && premiumState.planType == 'annual';

    const features = [
      ('Unlimited subjects tracking', Icons.book_rounded),
      ('AI-powered bunk predictions', Icons.auto_awesome_rounded),
      ('Advanced analytics & charts', Icons.bar_chart_rounded),
      ('Attendance heatmap', Icons.grid_view_rounded),
      ('Export attendance reports', Icons.download_rounded),
      ('Priority customer support', Icons.support_agent_rounded),
      ('Custom attendance goals', Icons.track_changes_rounded),
      ('Offline mode support', Icons.offline_bolt_rounded),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _appBarTitle(premiumState),
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // ─── Hero ────────────────────────────────────────────────────
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
                  if (alreadyPremium) ...[
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Active — ${_formatPlan(premiumState.planType)} Plan',
                            style: AppTextStyles.labelMd
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    if (premiumState.expiresAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Renews on ${_formatDate(premiumState.expiresAt!)}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: Colors.white.withAlpha(180)),
                        ),
                      ),
                  ] else
                    Text(
                      'Unlock the full power of AI-driven attendance tracking',
                      style:
                          AppTextStyles.bodyLg.copyWith(color: Colors.white.withAlpha(220)),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ─── Features List ───────────────────────────────────────────
            Text('Everything You Get',
                style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
            const SizedBox(height: AppSpacing.md),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimaryContainer.withAlpha(80)
                              : AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(f.$2, size: 18, color: primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(f.$1,
                          style: AppTextStyles.bodyLg.copyWith(color: onSurface)),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.xl),

            if (!alreadyPremium) ...[
              // ─── Pricing Plans (free user) ─────────────────────────────
              Text('Choose Your Plan',
                  style: AppTextStyles.headlineMd.copyWith(color: onSurface)),
              const SizedBox(height: AppSpacing.md),

              // Monthly Plan
              _PlanCard(
                title: 'Monthly',
                price: '₹20',
                period: '/month',
                subtitle: 'Billed monthly • Cancel anytime',
                isHighlighted: false,
                isDark: isDark,
                isLoading: _purchasingPlan == 'monthly',
                isDisabled: _purchasingPlan != null,
                onTap: () => _openCheckout('monthly'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Annual Plan (highlighted)
              Stack(
                children: [
                  _PlanCard(
                    title: 'Annual',
                    price: '₹200',
                    period: '/year',
                    subtitle: 'Just ₹16.67/month • Save 17%',
                    isHighlighted: true,
                    isDark: isDark,
                    isLoading: _purchasingPlan == 'annual',
                    isDisabled: _purchasingPlan != null,
                    onTap: () => _openCheckout('annual'),
                  ),
                  Positioned(
                    top: -1,
                    right: AppSpacing.lg,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'BEST VALUE',
                        style:
                            AppTextStyles.labelCaps.copyWith(color: Colors.white),
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

            ] else if (isMonthly) ...[
              // ─── Monthly subscriber: current plan + upgrade option ────────

              // Current plan chip
              _CurrentPlanChip(
                planType: 'monthly',
                expiresAt: premiumState.expiresAt,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Upgrade prompt
              Text(
                'Upgrade & Save More',
                style: AppTextStyles.headlineMd.copyWith(color: onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Switch to Annual and save ₹40 a year.',
                style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),

              // Annual upgrade card
              Stack(
                children: [
                  _PlanCard(
                    title: 'Annual',
                    price: '₹200',
                    period: '/year',
                    subtitle: 'Just ₹16.67/month • Save ₹40/year',
                    isHighlighted: true,
                    isDark: isDark,
                    isLoading: _purchasingPlan == 'annual',
                    isDisabled: _purchasingPlan != null,
                    onTap: () => _openCheckout('annual'),
                  ),
                  Positioned(
                    top: -1,
                    right: AppSpacing.lg,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'UPGRADE',
                        style:
                            AppTextStyles.labelCaps.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Upgrade now and your remaining monthly days are credited.',
                style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

            ] else if (isAnnual) ...[
              // ─── Annual subscriber: fully settled ───────────────────────
              _CurrentPlanChip(
                planType: 'annual',
                expiresAt: premiumState.expiresAt,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.lg),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.successContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.success.withAlpha(80),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: AppColors.success, size: 40),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'You\'re on the best plan!',
                      style: AppTextStyles.headlineMd
                          .copyWith(color: AppColors.success),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enjoy all premium features of AttendanceAI for the whole year.',
                      style: AppTextStyles.bodySm.copyWith(color: onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  String _appBarTitle(PremiumState state) {
    if (!state.isPremium) return 'Go Premium';
    return switch (state.planType) {
      'monthly' => 'Monthly Plan',
      'annual'  => 'Annual Plan',
      _         => 'Your Premium Plan',
    };
  }

  String _formatPlan(String? planType) {
    return switch (planType) {
      'annual'  => 'Annual',
      'monthly' => 'Monthly',
      _         => 'Premium',
    };
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── Current Plan Chip ───────────────────────────────────────────────

class _CurrentPlanChip extends StatelessWidget {
  final String planType; // 'monthly' | 'annual'
  final DateTime? expiresAt;
  final bool isDark;

  const _CurrentPlanChip({
    required this.planType,
    required this.expiresAt,
    required this.isDark,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isAnnual = planType == 'annual';
    final label = isAnnual ? 'Annual Plan' : 'Monthly Plan';
    final color = isAnnual ? AppColors.success : AppColors.primary;
    final bgColor = isAnnual
        ? AppColors.successContainer
        : (isDark ? AppColors.darkPrimaryContainer.withAlpha(60) : AppColors.primaryFixed);
    final borderColor = isAnnual
        ? AppColors.success.withAlpha(80)
        : AppColors.primary.withAlpha(80);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnnual ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyLg.copyWith(
                        color: color, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: AppTextStyles.labelCaps
                            .copyWith(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                if (expiresAt != null)
                  Text(
                    'Renews on ${_formatDate(expiresAt!)}',
                    style: AppTextStyles.bodySm.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String subtitle;
  final bool isHighlighted;
  final bool isDark;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.subtitle,
    required this.isHighlighted,
    required this.isDark,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final cardBg = isHighlighted
        ? (isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer)
        : (isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest);
    final borderColor = isHighlighted
        ? primary
        : (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant);
    final textColor = isHighlighted
        ? Colors.white
        : (isDark ? AppColors.darkOnSurface : AppColors.onSurface);
    final subtitleColor = isHighlighted
        ? Colors.white.withAlpha(200)
        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: isDisabled && !isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
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
              if (isLoading)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isHighlighted ? Colors.white : primary,
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: AppTextStyles.displayLg.copyWith(
                          color: textColor, fontSize: 36),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(period,
                          style:
                              AppTextStyles.bodySm.copyWith(color: subtitleColor)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
