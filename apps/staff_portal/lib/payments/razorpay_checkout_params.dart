/// Parameters for opening Razorpay Checkout (subscription or bill payment).
class RazorpayCheckoutParams {
  const RazorpayCheckoutParams({
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.razorpayOrderId,
    required this.description,
    this.name = 'TableFlow',
  });

  final String keyId;
  final int amountPaise;
  final String currency;
  final String razorpayOrderId;
  final String description;
  final String name;
}
