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

/// Checks whether the **currently selected** restaurant (tenant JWT) has a
/// `pending_payment` subscription and drives router redirects on app reload.
///
/// Does not scan other restaurants the user may own.
class SubscriptionGuardCubit extends Cubit<SubscriptionGuardState> {
  SubscriptionGuardCubit({
    required OnboardingRepository onboardingRepository,
    required SecureTokenRepository tokenRepository,
  })  : _onboardingRepo = onboardingRepository,
        _tokenRepo = tokenRepository,
        super(const SubscriptionGuardInitial());

  final OnboardingRepository _onboardingRepo;
  final SecureTokenRepository _tokenRepo;

  Future<void>? _inFlightCheck;

  /// Clears the payment-required flag (after successful payment).
  void markPaymentComplete() {
    emit(const SubscriptionGuardClear());
  }

  void reset() {
    _inFlightCheck = null;
    emit(const SubscriptionGuardInitial());
  }

  /// Checks subscription status for the restaurant in the tenant JWT only.
  Future<void> checkPendingPayment() async {
    _inFlightCheck ??= _runCheck().whenComplete(() => _inFlightCheck = null);
    await _inFlightCheck;
  }

  Future<void> _runCheck() async {
    emit(const SubscriptionGuardLoading());
    try {
      final restaurantId = await _selectedRestaurantId();
      if (restaurantId == null) {
        emit(const SubscriptionGuardClear());
        return;
      }

      final sub = await _onboardingRepo.getSubscriptionForRestaurant(restaurantId);
      if (sub?.status == 'pending_payment') {
        emit(SubscriptionGuardPaymentRequired(restaurantId: restaurantId));
      } else {
        emit(const SubscriptionGuardClear());
      }
    } catch (_) {
      // Do not block the app if the check fails — tenant APIs will 403 anyway.
      emit(const SubscriptionGuardClear());
    }
  }

  /// Returns the selected restaurant id from a valid tenant JWT, or null when
  /// no restaurant is selected yet (e.g. restaurant selector screen).
  Future<String?> _selectedRestaurantId() async {
    if (!_tokenRepo.isTenantTokenValid()) return null;

    final tenantToken = await _tokenRepo.getTenantToken();
    if (tenantToken == null) return null;

    final restaurantId = SecureTokenRepository.extractRestaurantId(tenantToken);
    if (restaurantId == null || restaurantId.isEmpty) return null;

    return restaurantId;
  }
}
