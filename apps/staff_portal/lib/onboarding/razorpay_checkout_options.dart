import 'onboarding_repository.dart';

/// Razorpay Checkout `config.display` — puts UPI first and lists common methods.
Map<String, dynamic> razorpayCheckoutDisplayConfig() => {
      'display': {
        'blocks': {
          'upi': {
            'name': 'Pay via UPI',
            'instruments': [
              {'method': 'upi'},
            ],
          },
          'card': {
            'name': 'Pay using Card',
            'instruments': [
              {'method': 'card'},
            ],
          },
          'netbanking': {
            'name': 'Netbanking',
            'instruments': [
              {'method': 'netbanking'},
            ],
          },
        },
        'sequence': [
          'block.upi',
          'block.card',
          'block.netbanking',
        ],
        'preferences': {
          // Keep Razorpay defaults (wallets, etc.) if enabled on the account.
          'show_default_blocks': true,
        },
      },
    };

/// Base Checkout options shared by web and mobile handlers.
Map<String, dynamic> buildRazorpayBaseOptions(
  InitiatePaymentResponse payment, {
  String? email,
  String? contact,
}) {
  return {
    'key': payment.keyId,
    'amount': payment.amount,
    'currency': payment.currency,
    'order_id': payment.razorpayOrderId,
    'name': 'TableFlow',
    'description': 'Subscription Payment',
    'theme': {'color': '#BF4010'},
    'config': razorpayCheckoutDisplayConfig(),
    if (email != null || contact != null)
      'prefill': {
        if (email != null) 'email': email,
        if (contact != null) 'contact': contact,
      },
  };
}
