/// Parses plan/subscription amounts from API responses into paise.
///
/// Backend `plan_amount` is in rupees ([int], [num], or [String] e.g. `"999.00"`).
int parseRupeesToPaise(dynamic raw) {
  if (raw == null) return 0;
  if (raw is int) return raw * 100;
  if (raw is num) return (raw * 100).round();
  if (raw is String) {
    final value = double.tryParse(raw.trim());
    if (value == null) return 0;
    return (value * 100).round();
  }
  return 0;
}

/// Parses Razorpay payment amounts — already in paise per Razorpay API.
int parsePaiseAmount(dynamic raw) {
  if (raw == null) return 0;
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) {
    final value = double.tryParse(raw.trim());
    if (value == null) return 0;
    return value.round();
  }
  return 0;
}

/// Formats paise as rupees for display (e.g. 99900 → "999", 999 → "9.99").
String formatRupeesFromPaise(int paise) {
  final rupees = paise / 100;
  if (rupees == rupees.truncateToDouble()) {
    return rupees.toStringAsFixed(0);
  }
  return rupees.toStringAsFixed(2);
}
