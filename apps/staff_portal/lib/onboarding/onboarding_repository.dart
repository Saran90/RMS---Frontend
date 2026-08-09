import 'dart:async';

import 'package:api_client/api_client.dart';

import '../payments/razorpay_checkout_params.dart';
import '../utils/money_parser.dart';

/// A subscription plan available for selection during onboarding.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.amountPaise,
    required this.features,
    this.billingCycle = 'monthly',
  });

  final String id;
  final String name;

  /// Price in paise (99900 = ₹999).
  final int amountPaise;
  final String billingCycle;
  final List<String> features;

  /// Display price in rupees.
  double get amountRupees => amountPaise / 100;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['plan_id'] as String,
      name: _formatName(json['plan_id'] as String),
      amountPaise: parseRupeesToPaise(json['plan_amount']),
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static String _formatName(String planId) {
    return planId
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

/// Subscription record returned by create / verify endpoints.
class SubscriptionRecord {
  const SubscriptionRecord({
    required this.subscriptionId,
    required this.restaurantId,
    required this.planId,
    required this.planAmountPaise,
    required this.billingCycle,
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
  });

  final String subscriptionId;
  final String restaurantId;
  final String planId;
  final int planAmountPaise;
  final String billingCycle;
  final String status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;

  factory SubscriptionRecord.fromJson(
    Map<String, dynamic> json, {
    String? restaurantId,
  }) {
    return SubscriptionRecord(
      subscriptionId: json['subscription_id'] as String,
      restaurantId: (json['restaurant_id'] as String?) ??
          restaurantId ??
          '',
      planId: json['plan_id'] as String,
      planAmountPaise: parseRupeesToPaise(json['plan_amount']),
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      status: json['status'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
    );
  }
}

/// Response from POST /subscriptions/:id/payment/initiate.
class InitiatePaymentResponse {
  const InitiatePaymentResponse({
    required this.subscriptionId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  final String subscriptionId;
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String keyId;

  factory InitiatePaymentResponse.fromJson(Map<String, dynamic> json) {
    return InitiatePaymentResponse(
      subscriptionId: json['subscription_id'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String,
      amount: parsePaiseAmount(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['key_id'] as String,
    );
  }

  RazorpayCheckoutParams toCheckoutParams() => RazorpayCheckoutParams(
        keyId: keyId,
        amountPaise: amount,
        currency: currency,
        razorpayOrderId: razorpayOrderId,
        description: 'Subscription Payment',
      );
}

/// Response from POST /subscriptions/payment/verify.
class VerifyPaymentResponse {
  const VerifyPaymentResponse({
    required this.subscription,
    required this.restaurantId,
    required this.restaurantStatus,
  });

  final SubscriptionRecord subscription;
  final String restaurantId;
  final String restaurantStatus;

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    final restaurant =
        json['restaurant'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return VerifyPaymentResponse(
      subscription: SubscriptionRecord.fromJson(
        json['subscription'] as Map<String, dynamic>,
        restaurantId: restaurant['restaurant_id'] as String?,
      ),
      restaurantId: restaurant['restaurant_id'] as String? ?? '',
      restaurantStatus: restaurant['status'] as String? ?? 'pending',
    );
  }
}

/// Repository for the onboarding / subscription wizard.
///
/// Requirements: 4.1–4.9
class OnboardingRepository {
  const OnboardingRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  Future<String> createRestaurant({
    required String name,
    required String address,
    required String gstNumber,
    required String contactEmail,
    required String contactPhone,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/restaurants',
      body: {
        'restaurant_name': name,
        'address': address,
        'gst_number': gstNumber,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
      },
    );
    return data['restaurant_id'] as String;
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/subscriptions/plans');
    final list = data['plans'] as List<dynamic>? ?? [];
    return list
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionRecord> createSubscription({
    required String restaurantId,
    required String planId,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/subscriptions',
      body: {'restaurant_id': restaurantId, 'plan_id': planId},
    );
    return SubscriptionRecord.fromJson(
      data,
      restaurantId: restaurantId,
    );
  }

  Future<InitiatePaymentResponse> initiatePayment(String subscriptionId) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/subscriptions/$subscriptionId/payment/initiate',
    );
    return InitiatePaymentResponse.fromJson(data);
  }

  Future<VerifyPaymentResponse> verifyPayment({
    required String subscriptionId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/subscriptions/payment/verify',
      body: {
        'subscription_id': subscriptionId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return VerifyPaymentResponse.fromJson(data);
  }

  Future<SubscriptionRecord?> getSubscriptionForRestaurant(
    String restaurantId,
  ) async {
    try {
      final data = await _client.get<Map<String, dynamic>>(
        '/api/v1/subscriptions/restaurant/$restaurantId',
      );
      return SubscriptionRecord.fromJson(
        data,
        restaurantId: restaurantId,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    await _client.patch<dynamic>(
      '/api/v1/subscriptions/$subscriptionId/cancel',
    );
  }

  /// Polls restaurant + subscription until provisioning completes or fails.
  Future<void> waitForProvisioning(
    String restaurantId, {
    Duration interval = const Duration(seconds: 2),
    int maxAttempts = 30,
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(interval);

      final sub = await getSubscriptionForRestaurant(restaurantId);
      if (sub?.status == 'provisioning_failed') {
        throw const ApiException(
          statusCode: 400,
          errorCode: 'PROVISIONING_FAILED',
          message:
              'Restaurant setup failed. Please contact support.',
        );
      }

      final data = await _client.get<Map<String, dynamic>>(
        '/api/v1/restaurants/$restaurantId',
      );
      final status = data['status'] as String?;
      if (status == 'active') return;
    }
    throw TimeoutException(
      'Setup is taking longer than expected. Please try again.',
    );
  }
}
