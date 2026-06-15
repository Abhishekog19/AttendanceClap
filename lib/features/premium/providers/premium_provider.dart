import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/datasources/firestore_datasource.dart';
import '../../profile/providers/profile_provider.dart';

part 'premium_provider.g.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class PremiumState {
  final bool isPremium;
  final String? planType; // 'monthly' | 'annual' | null
  final DateTime? expiresAt;
  final bool isLoading;
  final String? error;

  const PremiumState({
    this.isPremium = false,
    this.planType,
    this.expiresAt,
    this.isLoading = false,
    this.error,
  });

  PremiumState copyWith({
    bool? isPremium,
    String? planType,
    DateTime? expiresAt,
    bool? isLoading,
    String? error,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      planType: planType ?? this.planType,
      expiresAt: expiresAt ?? this.expiresAt,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the transient error field.
  PremiumState clearError() => PremiumState(
        isPremium: isPremium,
        planType: planType,
        expiresAt: expiresAt,
        isLoading: isLoading,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

@riverpod
class PremiumNotifier extends _$PremiumNotifier {
  @override
  PremiumState build() {
    // Seed premium status from the cached user profile if already loaded.
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.valueOrNull;
    return PremiumState(
      isPremium: user?.isPremium ?? false,
      planType: user?.planType,
      expiresAt: user?.premiumExpiresAt,
    );
  }

  /// Called after a successful Razorpay payment to persist premium status.
  Future<void> activatePremium({
    required String planType, // 'monthly' | 'annual'
    required String paymentId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final expiresAt = planType == 'annual'
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      await ref.read(firestoreDatasourceProvider).updatePremiumStatus(
            uid: uid,
            isPremium: true,
            planType: planType,
            expiresAt: expiresAt,
            lastPaymentId: paymentId,
          );

      state = state.copyWith(
        isPremium: true,
        planType: planType,
        expiresAt: expiresAt,
        isLoading: false,
      );

      // Refresh the user profile so rest of the app sees the updated state.
      ref.invalidate(userProfileProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  void clearError() {
    state = state.clearError();
  }
}

// ─── Simple read-only provider ─────────────────────────────────────────────

/// Convenience provider — returns true if the current user has an active
/// premium subscription.
@riverpod
bool isPremiumUser(Ref ref) {
  return ref.watch(premiumNotifierProvider).isPremium;
}
