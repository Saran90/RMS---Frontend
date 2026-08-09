import '../payments/razorpay_checkout_params.dart';

/// Fallback when Razorpay is not available on the current platform.
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

  void init() {}

  void dispose() {}

  void open(
    RazorpayCheckoutParams checkoutParams, {
    String? email,
    String? contact,
  }) {
    onFailure(
      'Payments are not supported on this platform. '
      'Use the Android or iOS app, or open the web app in a browser.',
    );
  }
}
