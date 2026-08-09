import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'onboarding_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

sealed class OnboardingEvent {
  const OnboardingEvent();
}

final class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

final class RestaurantDetailsSubmitted extends OnboardingEvent {
  const RestaurantDetailsSubmitted({
    required this.name,
    required this.address,
    required this.gstNumber,
    required this.contactEmail,
    required this.contactPhone,
  });
  final String name;
  final String address;
  final String gstNumber;
  final String contactEmail;
  final String contactPhone;
}

final class PlanSelected extends OnboardingEvent {
  const PlanSelected({required this.planId});
  final String planId;
}

/// Razorpay checkout reported success — verify on backend.
final class PaymentSucceeded extends OnboardingEvent {
  const PaymentSucceeded({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
  final String paymentId;
  final String orderId;
  final String signature;
}

final class PaymentFailed extends OnboardingEvent {
  const PaymentFailed({required this.message});
  final String message;
}

/// User closed the Razorpay modal without paying.
final class PaymentDismissed extends OnboardingEvent {
  const PaymentDismissed();
}

/// Retry payment for an existing pending_payment subscription.
final class PaymentRetryRequested extends OnboardingEvent {
  const PaymentRetryRequested();
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class OnboardingState {
  const OnboardingState();
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingLoading extends OnboardingState {
  const OnboardingLoading({this.message});

  /// Optional status message (e.g. "Verifying payment…").
  final String? message;
}

final class RestaurantDetailsStep extends OnboardingState {
  const RestaurantDetailsStep({this.errorMessage});
  final String? errorMessage;
}

final class PlanSelectionStep extends OnboardingState {
  const PlanSelectionStep({
    required this.restaurantId,
    required this.plans,
    required this.contactEmail,
    required this.contactPhone,
    this.errorMessage,
    this.pendingSubscriptionId,
  });
  final String restaurantId;
  final List<SubscriptionPlan> plans;
  final String contactEmail;
  final String contactPhone;
  final String? errorMessage;

  /// When set, user can resume payment instead of creating a new subscription.
  final String? pendingSubscriptionId;
}

/// Razorpay checkout should open — UI listens and calls [RazorpayPaymentHandler].
final class PaymentCheckoutReady extends OnboardingState {
  const PaymentCheckoutReady({
    required this.restaurantId,
    required this.plans,
    required this.contactEmail,
    required this.contactPhone,
    required this.subscriptionId,
    required this.payment,
  });
  final String restaurantId;
  final List<SubscriptionPlan> plans;
  final String contactEmail;
  final String contactPhone;
  final String subscriptionId;
  final InitiatePaymentResponse payment;
}

/// Subscription created — waiting for backend provisioning to finish.
final class ProvisioningStep extends OnboardingState {
  const ProvisioningStep({required this.restaurantId});
  final String restaurantId;
}

final class OnboardingComplete extends OnboardingState {
  const OnboardingComplete({required this.restaurantId});
  final String restaurantId;
}

final class OnboardingError extends OnboardingState {
  const OnboardingError({required this.message, required this.step});
  final String message;
  final int step;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

/// Drives the multi-step onboarding wizard with Razorpay payment.
///
/// Flow: Restaurant Details → Plan Selection → Payment → Provisioning → Done
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required OnboardingRepository repository})
      : _repo = repository,
        super(const OnboardingInitial()) {
    on<OnboardingStarted>(_onStarted);
    on<RestaurantDetailsSubmitted>(_onRestaurantDetailsSubmitted);
    on<PlanSelected>(_onPlanSelected);
    on<PaymentSucceeded>(_onPaymentSucceeded);
    on<PaymentFailed>(_onPaymentFailed);
    on<PaymentDismissed>(_onPaymentDismissed);
    on<PaymentRetryRequested>(_onPaymentRetryRequested);
  }

  final OnboardingRepository _repo;

  Future<void> _onStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const RestaurantDetailsStep());
  }

  Future<void> _onRestaurantDetailsSubmitted(
    RestaurantDetailsSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingLoading());
    try {
      final restaurantId = await _repo.createRestaurant(
        name: event.name,
        address: event.address,
        gstNumber: event.gstNumber,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
      );
      final plans = await _repo.getSubscriptionPlans();

      // Check for an existing pending_payment subscription to resume.
      final existing = await _repo.getSubscriptionForRestaurant(restaurantId);
      final pendingId = existing?.status == 'pending_payment'
          ? existing!.subscriptionId
          : null;

      emit(PlanSelectionStep(
        restaurantId: restaurantId,
        plans: plans,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        pendingSubscriptionId: pendingId,
      ));
    } on ApiException catch (e) {
      emit(RestaurantDetailsStep(errorMessage: e.message));
    } catch (e) {
      emit(RestaurantDetailsStep(errorMessage: e.toString()));
    }
  }

  Future<void> _onPlanSelected(
    PlanSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    final current = state;
    if (current is! PlanSelectionStep) return;

    emit(const OnboardingLoading(message: 'Preparing payment…'));
    try {
      final subscription = await _createOrResumeSubscription(
        current: current,
        planId: event.planId,
      );
      final payment = await _repo.initiatePayment(subscription.subscriptionId);
      emit(PaymentCheckoutReady(
        restaurantId: current.restaurantId,
        plans: current.plans,
        contactEmail: current.contactEmail,
        contactPhone: current.contactPhone,
        subscriptionId: subscription.subscriptionId,
        payment: payment,
      ));
    } on ApiException catch (e) {
      emit(_planStepWithError(current, e.message));
    } catch (e) {
      emit(_planStepWithError(current, e.toString()));
    }
  }

  Future<void> _onPaymentRetryRequested(
    PaymentRetryRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final current = state;
    if (current is! PlanSelectionStep) return;
    final subscriptionId = current.pendingSubscriptionId;
    if (subscriptionId == null) return;

    emit(const OnboardingLoading(message: 'Preparing payment…'));
    try {
      final payment = await _repo.initiatePayment(subscriptionId);
      emit(PaymentCheckoutReady(
        restaurantId: current.restaurantId,
        plans: current.plans,
        contactEmail: current.contactEmail,
        contactPhone: current.contactPhone,
        subscriptionId: subscriptionId,
        payment: payment,
      ));
    } on ApiException catch (e) {
      emit(_planStepWithError(current, e.message));
    } catch (e) {
      emit(_planStepWithError(current, e.toString()));
    }
  }

  Future<void> _onPaymentSucceeded(
    PaymentSucceeded event,
    Emitter<OnboardingState> emit,
  ) async {
    final checkout = state;
    if (checkout is! PaymentCheckoutReady) return;

    emit(const OnboardingLoading(message: 'Verifying payment…'));
    try {
      final result = await _repo.verifyPayment(
        subscriptionId: checkout.subscriptionId,
        razorpayPaymentId: event.paymentId,
        razorpayOrderId: event.orderId,
        razorpaySignature: event.signature,
      );

      emit(ProvisioningStep(restaurantId: result.restaurantId));
      await _repo.waitForProvisioning(result.restaurantId);
      emit(OnboardingComplete(restaurantId: result.restaurantId));
    } on ApiException catch (e) {
      emit(_planStepFromCheckout(checkout, e.message));
    } catch (e) {
      emit(_planStepFromCheckout(checkout, e.toString()));
    }
  }

  void _onPaymentFailed(
    PaymentFailed event,
    Emitter<OnboardingState> emit,
  ) {
    final checkout = state;
    if (checkout is! PaymentCheckoutReady) return;
    emit(_planStepFromCheckout(checkout, event.message));
  }

  void _onPaymentDismissed(
    PaymentDismissed event,
    Emitter<OnboardingState> emit,
  ) {
    final checkout = state;
    if (checkout is! PaymentCheckoutReady) return;
    emit(_planStepFromCheckout(
      checkout,
      'Payment cancelled. Please try again.',
    ));
  }

  PlanSelectionStep _planStepFromCheckout(
    PaymentCheckoutReady checkout,
    String message,
  ) {
    return PlanSelectionStep(
      restaurantId: checkout.restaurantId,
      plans: checkout.plans,
      contactEmail: checkout.contactEmail,
      contactPhone: checkout.contactPhone,
      errorMessage: message,
      pendingSubscriptionId: checkout.subscriptionId,
    );
  }

  PlanSelectionStep _planStepWithError(
    PlanSelectionStep current,
    String message,
  ) {
    return PlanSelectionStep(
      restaurantId: current.restaurantId,
      plans: current.plans,
      contactEmail: current.contactEmail,
      contactPhone: current.contactPhone,
      errorMessage: message,
      pendingSubscriptionId: current.pendingSubscriptionId,
    );
  }

  Future<SubscriptionRecord> _createOrResumeSubscription({
    required PlanSelectionStep current,
    required String planId,
  }) async {
    if (current.pendingSubscriptionId != null) {
      final existing = await _repo.getSubscriptionForRestaurant(
        current.restaurantId,
      );
      if (existing != null && existing.status == 'pending_payment') {
        if (existing.planId == planId) {
          return existing;
        }
        await _repo.cancelSubscription(existing.subscriptionId);
      }
    }
    return _repo.createSubscription(
      restaurantId: current.restaurantId,
      planId: planId,
    );
  }
}
