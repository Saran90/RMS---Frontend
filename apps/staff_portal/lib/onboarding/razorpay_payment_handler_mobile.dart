import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../payments/razorpay_checkout_params.dart';
import 'razorpay_checkout_options.dart';

/// Native Razorpay checkout via [razorpay_flutter] (Android / iOS).
class RazorpayPaymentHandler {
  RazorpayPaymentHandler({
    required this.onSuccess,
    required this.onFailure,
    required this.onDismiss,
  });

  final void Function({
    required String paymentId,
    required String orderId,
    required String signature,
  }) onSuccess;

  final void Function(String message) onFailure;
  final void Function() onDismiss;

  Razorpay? _razorpay;

  void init() {
    _razorpay = Razorpay();
    _razorpay!
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void open(
    RazorpayCheckoutParams checkoutParams, {
    String? email,
    String? contact,
  }) {
    final rzp = _razorpay;
    if (rzp == null) {
      onFailure('Payment system is not ready. Please try again.');
      return;
    }

    final options = buildRazorpayBaseOptions(
      checkoutParams,
      email: email,
      contact: contact,
    );

    try {
      rzp.open(options);
    } on MissingPluginException {
      onFailure(
        'Payments are not available on this device. '
        'Use the Android or iOS app, or open the web app in a browser.',
      );
    } catch (e) {
      onFailure('Could not open payment: $e');
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId;
    final orderId = response.orderId;
    final signature = response.signature;
    if (paymentId == null || orderId == null || signature == null) {
      onFailure('Payment succeeded but response was incomplete.');
      return;
    }
    onSuccess(
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  void _handleError(PaymentFailureResponse response) {
    final message = response.message ?? 'Payment failed';
    final code = response.code;
    if (code == Razorpay.PAYMENT_CANCELLED) {
      onDismiss();
      return;
    }
    onFailure(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onFailure('External wallet selected: ${response.walletName ?? "unknown"}');
  }
}
