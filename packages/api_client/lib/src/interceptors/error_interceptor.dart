import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Maps non-2xx HTTP responses and network failures to [ApiException].
///
/// Error mapping rules (Requirements 18.3–18.6):
/// - 4xx (≠ 401): uses the server `message` field if present, otherwise
///   falls back to "An error occurred. Please try again."
/// - 5xx: always "Server error, please try again"
/// - Timeout (connect / send / receive): "Request timed out"
/// - Other DioExceptions: "An error occurred. Please try again."
///
/// Note: 401 errors are handled upstream by [AuthInterceptor] and are only
/// forwarded here when the refresh flow has already failed.
class ErrorInterceptor extends Interceptor {
  static const _genericMessage = 'An error occurred. Please try again.';
  static const _serverErrorMessage = 'Server error, please try again';
  static const _timeoutMessage = 'Request timed out';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _toDioError(err);
    // Attach the ApiException to the DioException so downstream interceptors
    // (e.g. RedirectInterceptor) can read it, then forward through the chain.
    handler.next(err.copyWith(error: apiException));
  }

  ApiException _toDioError(DioException err) {
    // ---------- Timeout handling ----------
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        statusCode: 0,
        message: _timeoutMessage,
        errorCode: 'TIMEOUT',
      );
    }

    // ---------- HTTP response errors ----------
    final response = err.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;

      if (statusCode >= 500) {
        return ApiException(
          statusCode: statusCode,
          message: _serverErrorMessage,
          errorCode: 'SERVER_ERROR',
        );
      }

      // 4xx (including 401 that slipped through after refresh failure)
      if (statusCode >= 400) {
        final body = response.data;
        final message = _extractMessage(body) ?? _genericMessage;
        final errorCode = _extractErrorCode(body);
        final redirect = _normalizeSubscriptionRedirect(body);
        return ApiException(
          statusCode: statusCode,
          message: message,
          errorCode: errorCode,
          redirect: redirect,
        );
      }
    }

    // ---------- All other network/connection errors ----------
    return const ApiException(
      statusCode: 0,
      message: _genericMessage,
      errorCode: 'NETWORK_ERROR',
    );
  }

  /// Extracts the `message` field from the response body, if present.
  /// When a `details` array is present (validation errors), builds a
  /// human-readable summary like:
  ///   "restaurant_name: Required; contact_email: Required"
  String? _extractMessage(dynamic body) {
    if (body is! Map<String, dynamic>) return null;

    final details = body['details'];
    if (details is List && details.isNotEmpty) {
      final parts = details
          .whereType<Map<String, dynamic>>()
          .map((d) {
            final field = d['field'] as String? ?? '';
            final msg = d['message'] as String? ?? '';
            return field.isNotEmpty ? '$field: $msg' : msg;
          })
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join('; ');
    }

    final msg = body['message'];
    if (msg is String && msg.isNotEmpty) return msg;
    return null;
  }

  /// Extracts the `errorCode` field from the response body, if present.
  String _extractErrorCode(dynamic body) {
    if (body is Map<String, dynamic>) {
      final code = body['errorCode'] ??
          body['error_code'] ??
          body['code'] ??
          body['error'];
      if (code is String && code.isNotEmpty) return code;
    }
    return '';
  }

  /// Maps subscription inactive / pending_payment to the payment redirect.
  ///
  /// Backend may return `redirect: "billing"` for inactive subscriptions;
  /// the subscription payment screen is the correct destination.
  String? _normalizeSubscriptionRedirect(dynamic body) {
    if (body is! Map<String, dynamic>) return _extractRedirect(body);

    final redirect = _extractRedirect(body);
    final errorCode = _extractErrorCode(body);
    final subStatus = body['subscription_status'];

    final needsPayment = errorCode == 'SUBSCRIPTION_INACTIVE' ||
        errorCode == 'PAYMENT_REQUIRED' ||
        _subscriptionStatusIsPendingPayment(subStatus);

    if (needsPayment) {
      return 'payment';
    }

    return redirect;
  }

  bool _subscriptionStatusIsPendingPayment(dynamic subStatus) {
    if (subStatus is String) {
      return subStatus.contains('pending_payment');
    }
    if (subStatus is Map<String, dynamic>) {
      return subStatus['status'] == 'pending_payment';
    }
    return false;
  }

  /// Extracts the `redirect` hint from the response body, if present.
  String? _extractRedirect(dynamic body) {
    if (body is Map<String, dynamic>) {
      final r = body['redirect'];
      if (r is String && r.isNotEmpty) return r;
    }
    return null;
  }
}
