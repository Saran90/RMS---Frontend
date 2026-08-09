import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

import '../payments/razorpay_checkout_params.dart';
import '../utils/money_parser.dart';

/// Response from POST /billing/bills/:id/payment/qr.
class BillPaymentQrResponse {
  const BillPaymentQrResponse({
    required this.billId,
    required this.amountPaise,
    required this.currency,
    required this.shortUrl,
    required this.paymentLinkUrl,
    this.razorpayOrderId,
    this.razorpayPaymentLinkId,
  });

  final String billId;
  final int amountPaise;
  final String currency;
  final String shortUrl;
  final String paymentLinkUrl;
  final String? razorpayOrderId;
  final String? razorpayPaymentLinkId;

  /// URL encoded into the on-screen QR (prefers [shortUrl]).
  String get qrPayload => shortUrl;

  double get amountRupees => amountPaise / 100;

  factory BillPaymentQrResponse.fromJson(Map<String, dynamic> json) {
    final shortUrl = json['short_url'] as String?;
    final paymentLinkUrl = json['payment_link_url'] as String?;
    final qrUrl = (shortUrl != null && shortUrl.isNotEmpty)
        ? shortUrl
        : paymentLinkUrl;

    if (qrUrl == null || qrUrl.isEmpty) {
      throw const FormatException(
        'Payment QR response missing short_url or payment_link_url',
      );
    }

    return BillPaymentQrResponse(
      billId: json['bill_id'] as String,
      amountPaise: parsePaiseAmount(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      shortUrl: shortUrl ?? qrUrl,
      paymentLinkUrl: paymentLinkUrl ?? qrUrl,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentLinkId: json['razorpay_payment_link_id'] as String?,
    );
  }
}

/// Response from POST /billing/bills/:id/payment/initiate (Checkout fallback).
class BillPaymentInitiateResponse {
  const BillPaymentInitiateResponse({
    required this.billId,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
  });

  final String billId;
  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String keyId;

  factory BillPaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    return BillPaymentInitiateResponse(
      billId: json['bill_id'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String,
      amountPaise: parsePaiseAmount(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['key_id'] as String,
    );
  }

  RazorpayCheckoutParams toCheckoutParams({
    required String description,
    String name = 'TableFlow',
  }) =>
      RazorpayCheckoutParams(
        keyId: keyId,
        amountPaise: amountPaise,
        currency: currency,
        razorpayOrderId: razorpayOrderId,
        description: description,
        name: name,
      );
}

/// Thrown when POST /payment/qr is unavailable — use Checkout fallback.
class BillPaymentQrUnavailableException implements Exception {
  const BillPaymentQrUnavailableException();
}

/// Requirements: 11.1–11.13
class BillingRepository {
  const BillingRepository({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  Future<Bill> generateBill(String orderId) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills',
      body: {'order_id': orderId},
    );
    return Bill.fromJson(data);
  }

  Future<Bill> recordPayment({
    required String billId,
    required String mode,
    required double amount,
    String? reference,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/payments',
      body: {
        'mode': mode,
        'amount': amount,
        if (reference != null && reference.trim().isNotEmpty)
          'reference': reference.trim(),
      },
    );
    return Bill.fromJson(data);
  }

  /// Creates a Razorpay payment link for customer scan-to-pay.
  Future<BillPaymentQrResponse> createBillPaymentQr(String billId) async {
    try {
      final data = await _client.post<Map<String, dynamic>>(
        '/api/v1/tenant/billing/bills/$billId/payment/qr',
      );
      return BillPaymentQrResponse.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw const BillPaymentQrUnavailableException();
      }
      rethrow;
    }
  }

  /// Checkout fallback when /payment/qr is unavailable.
  Future<BillPaymentInitiateResponse> initiateBillPayment(String billId) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/payment/initiate',
    );
    return BillPaymentInitiateResponse.fromJson(data);
  }

  Future<Bill> verifyBillPayment({
    required String billId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/payment/verify',
      body: {
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return Bill.fromJson(data);
  }

  Future<List<Bill>> splitBill(
      {required String billId, required int diners}) async {
    final data = await _client.post<List<dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/split',
      body: {'diners': diners},
    );
    return data.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bill> voidBill(
      {required String billId, required String reason}) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/void',
      body: {'reason': reason},
    );
    return Bill.fromJson(data);
  }

  Future<Bill> getBill(String billId) async {
    final data = await _client
        .get<Map<String, dynamic>>('/api/v1/tenant/billing/bills/$billId');
    return Bill.fromJson(data);
  }

  Future<List<Bill>> listBills({String? status}) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills',
      queryParams: {
        if (status != null) 'status': status,
        'limit': 100,
      },
    );
    final bills = data['bills'] as List<dynamic>? ?? [];
    return bills.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }
}
