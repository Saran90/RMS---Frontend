import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/redirect_interceptor.dart';
import 'interceptors/request_id_interceptor.dart';
import 'token_repository.dart';

/// Global 30-second timeout applied to all three Dio timeout settings.
const _kTimeout = Duration(seconds: 30);

/// Single Dio-backed HTTP client for the RMS Flutter monorepo.
///
/// Interceptors are added in order:
/// 1. [LogInterceptor]       — logs requests/responses (debug builds only)
/// 2. [RequestIdInterceptor] — injects `X-Request-ID: <UUID v4>` (Req 18.8)
/// 3. [AuthInterceptor]      — attaches Bearer token; handles 401 refresh
///                            (Req 18.1–18.2)
/// 4. [ErrorInterceptor]     — maps errors to [ApiException] (Req 18.3–18.6)
/// 5. [RedirectInterceptor]  — calls [onRedirect] for auth/subscription errors
///
/// The 30-second timeout satisfies Requirement 18.6.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenRepository tokenRepository,
    required OnTokenRefreshFailed onTokenRefreshFailed,
    OnRedirect? onRedirect,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: _kTimeout,
                receiveTimeout: _kTimeout,
                sendTimeout: _kTimeout,
                contentType: 'application/json',
              ),
            ) {
    // Log in debug builds only — use assert so tree-shaking removes it.
    assert(() {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (o) => _debugPrint(o.toString()),
        ),
      );
      return true;
    }());

    _dio.interceptors.addAll([
      RequestIdInterceptor(),
      AuthInterceptor(
        tokenRepository: tokenRepository,
        dio: _dio,
        onTokenRefreshFailed: onTokenRefreshFailed,
      ),
      ErrorInterceptor(),
      // RedirectInterceptor is optional — only added when onRedirect is given
      // so tests and headless usage are unaffected.
      if (onRedirect != null) RedirectInterceptor(onRedirect: onRedirect),
    ]);
  }

  // ignore: avoid_print
  static void _debugPrint(String msg) => print(msg);

  final Dio _dio;

  /// Exposes the underlying [Dio] instance for advanced usage (e.g. tests).
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Typed HTTP helpers
  // ---------------------------------------------------------------------------

  /// Performs a `GET` request and returns the decoded response data as [T].
  ///
  /// Throws [ApiException] on non-2xx responses, timeouts, or network errors.
  /// Pass a [cancelToken] to abort the request when the caller is superseded.
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
      return _unwrap<T>(response);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.error is ApiException) throw e.error as ApiException;
      throw _dioToApiException(e);
    }
  }

  /// Performs a `POST` request with an optional [body] and returns [T].
  Future<T> post<T>(String path, {dynamic body}) async {
    try {
      final response = await _dio.post<T>(path, data: body);
      return _unwrap<T>(response);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.error is ApiException) throw e.error as ApiException;
      throw _dioToApiException(e);
    }
  }

  /// Performs a `PATCH` request with an optional [body] and returns [T].
  Future<T> patch<T>(String path, {dynamic body}) async {
    try {
      final response = await _dio.patch<T>(path, data: body);
      return _unwrap<T>(response);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.error is ApiException) throw e.error as ApiException;
      throw _dioToApiException(e);
    }
  }

  /// Performs a `DELETE` request and returns [T].
  Future<T> delete<T>(String path) async {
    try {
      final response = await _dio.delete<T>(path);
      return _unwrap<T>(response);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.error is ApiException) throw e.error as ApiException;
      throw _dioToApiException(e);
    }
  }

  /// Performs a multipart `POST` request with the given [FormData] and
  /// returns [T].
  Future<T> postMultipart<T>(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return _unwrap<T>(response);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw _dioToApiException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  T _unwrap<T>(Response<T> response) {
    final data = response.data;
    if (data is T) return data;
    // Gracefully handle `null` for void responses when T == dynamic.
    return data as T;
  }

  /// Fallback converter for any [DioException] that was not caught by
  /// [ErrorInterceptor] (e.g. when the interceptor itself re-throws an
  /// [ApiException] that was not unwrapped properly).
  ApiException _dioToApiException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        statusCode: 0,
        message: 'Request timed out',
        errorCode: 'TIMEOUT',
      );
    }
    return const ApiException(
      statusCode: 0,
      message: 'An error occurred. Please try again.',
      errorCode: 'NETWORK_ERROR',
    );
  }
}
