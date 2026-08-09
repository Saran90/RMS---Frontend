import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../payments/razorpay_checkout_params.dart';
import 'razorpay_checkout_options.dart';

/// Razorpay Checkout.js integration for Flutter web.
///
/// Requires `checkout.js` in `web/index.html`.
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
    try {
      if (!_isCheckoutAvailable()) {
        onFailure(
          'Razorpay checkout is not loaded. '
          'Refresh the page and try again.',
        );
        return;
      }

      final successHandler = ((JSAny response) {
        final obj = response as JSObject;
        final paymentId = _readString(obj, 'razorpay_payment_id');
        final orderId = _readString(obj, 'razorpay_order_id');
        final signature = _readString(obj, 'razorpay_signature');
        if (paymentId == null || orderId == null || signature == null) {
          onFailure('Payment succeeded but response was incomplete.');
          return;
        }
        onSuccess(
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        );
      }).toJS;

      final dismissHandler = (() => onDismiss()).toJS;

      final failedHandler = ((JSAny event) {
        final response = (event as JSObject)['error'] as JSObject?;
        final description = response == null
            ? null
            : _readString(response, 'description');
        onFailure(description ?? 'Payment failed');
      }).toJS;

      final options = <String, Object?>{
        ...buildRazorpayBaseOptions(
          checkoutParams,
          email: email,
          contact: contact,
        ),
        'handler': successHandler,
        'modal': {'ondismiss': dismissHandler},
      }.jsify() as JSObject;

      final razorpayCtor = globalContext['Razorpay'] as JSFunction;
      final checkout = razorpayCtor.callAsConstructor(options) as JSObject;

      _callIfPresent(
        checkout,
        'on',
        'payment.failed'.toJS,
        failedHandler,
      );
      checkout.callMethod('open'.toJS);
    } catch (e) {
      onFailure('Could not open payment: $e');
    }
  }

  bool _isCheckoutAvailable() {
    final razorpay = globalContext['Razorpay'];
    return razorpay != null && !razorpay.isUndefinedOrNull;
  }

  void _callIfPresent(
    JSObject target,
    String method,
    JSAny? arg1,
    JSAny? arg2,
  ) {
    final fn = target[method];
    if (fn == null || fn.isUndefinedOrNull) return;
    target.callMethod(method.toJS, arg1, arg2);
  }

  String? _readString(JSObject object, String key) {
    final value = object[key];
    if (value == null || value.isUndefinedOrNull) return null;
    return value.dartify() as String?;
  }
}
