import '../payments/razorpay_checkout_params.dart';

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
  RazorpayCheckoutParams checkout, {
  String? email,
  String? contact,
}) {
  return {
    'key': checkout.keyId,
    'amount': checkout.amountPaise,
    'currency': checkout.currency,
    'order_id': checkout.razorpayOrderId,
    'name': checkout.name,
    'description': checkout.description,
    'theme': {'color': '#BF4010'},
    'config': razorpayCheckoutDisplayConfig(),
    if (email != null || contact != null)
      'prefill': {
        if (email != null) 'email': email,
        if (contact != null) 'contact': contact,
      },
  };
}
