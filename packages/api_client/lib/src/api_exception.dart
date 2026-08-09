/// Typed exception thrown by [ApiClient] for non-2xx HTTP responses and
/// network-level failures (timeouts, connection errors, etc.).
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode = '',
    this.redirect,
  });

  /// The HTTP status code, or `0` for network-level errors (timeout, no
  /// connection).
  final int statusCode;

  /// A human-readable description surfaced in the UI.
  final String message;

  /// Optional machine-readable error code returned by the server.
  final String errorCode;

  /// Optional redirect hint from the server — one of:
  /// `login`, `payment`, `billing`, `support`, `restaurant_setup`.
  /// When present the app should navigate to the corresponding screen.
  final String? redirect;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, errorCode: $errorCode, '
      'redirect: $redirect, message: $message)';
}
