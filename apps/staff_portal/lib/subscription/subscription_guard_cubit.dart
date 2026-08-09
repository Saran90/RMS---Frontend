import 'package:auth/auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_portal/onboarding/onboarding_repository.dart';

// ── States ────────────────────────────────────────────────────────────────────

sealed class SubscriptionGuardState {
  const SubscriptionGuardState();
}

/// Guard has not run yet (app boot).
final class SubscriptionGuardInitial extends SubscriptionGuardState {
  const SubscriptionGuardInitial();
}

final class SubscriptionGuardLoading extends SubscriptionGuardState {
  const SubscriptionGuardLoading();
}

/// No subscription awaiting payment.
final class SubscriptionGuardClear extends SubscriptionGuardState {
  const SubscriptionGuardClear();
}

/// User must complete payment before using tenant features.
final class SubscriptionGuardPaymentRequired extends SubscriptionGuardState {
  const SubscriptionGuardPaymentRequired({required this.restaurantId});
  final String restaurantId;
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Checks whether the **selected** restaurant has a `pending_payment`
/// subscription and drives router redirects on app reload.
class SubscriptionGuardCubit extends Cubit<SubscriptionGuardState> {
  SubscriptionGuardCubit({
    required OnboardingRepository onboardingRepository,
    required SecureTokenRepository tokenRepository,
  })  : _onboardingRepo = onboardingRepository,
        _tokenRepo = tokenRepository,
        super(const SubscriptionGuardInitial());

  final OnboardingRepository _onboardingRepo;
  final SecureTokenRepository _tokenRepo;

  /// Clears the payment-required flag (after successful payment).
  void markPaymentComplete() {
    emit(const SubscriptionGuardClear());
  }

  void reset() {
    emit(const SubscriptionGuardInitial());
  }

  /// Checks subscription status for the restaurant in the tenant JWT only.
  Future<void> checkPendingPayment() async {
    emit(const SubscriptionGuardLoading());
    try {
      final restaurantId = await _selectedRestaurantPendingPaymentId();
      if (restaurantId != null) {
        emit(SubscriptionGuardPaymentRequired(restaurantId: restaurantId));
      } else {
        emit(const SubscriptionGuardClear());
      }
    } catch (_) {
      // Do not block the app if the check fails — tenant APIs will 403 anyway.
      emit(const SubscriptionGuardClear());
    }
  }

  Future<String?> _selectedRestaurantPendingPaymentId() async {
    if (!_tokenRepo.isTenantTokenValid()) return null;

    final tenantToken = await _tokenRepo.getTenantToken();
    if (tenantToken == null) return null;

    final restaurantId = SecureTokenRepository.extractRestaurantId(tenantToken);
    if (restaurantId == null || restaurantId.isEmpty) return null;

    final sub = await _onboardingRepo.getSubscriptionForRestaurant(restaurantId);
    if (sub?.status == 'pending_payment') return restaurantId;
    return null;
  }
}
