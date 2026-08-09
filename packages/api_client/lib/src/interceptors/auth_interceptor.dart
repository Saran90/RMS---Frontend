import 'package:dio/dio.dart';
import 'package:mutex/mutex.dart';

import '../token_repository.dart';

/// Callback invoked when the token-refresh flow fails permanently.
///
/// The `packages/auth` layer registers an [AuthBloc] event here so the user
/// is redirected to the Login screen.
typedef OnTokenRefreshFailed = void Function();

/// Attaches `Authorization: Bearer <token>` to every outgoing request and
/// silently refreshes the access token on HTTP 401.
///
/// Satisfies Requirements 18.1–18.2:
///
/// - **18.1**: On 401, acquires a [Mutex] lock so only one refresh is in
///   flight at a time; all concurrent 401 requests queue behind the lock and
///   reuse the new token once it is available.
/// - **18.2**: If refresh fails (no refresh token, or the refresh endpoint
///   itself returns an error), clears all stored tokens and calls
///   [onTokenRefreshFailed] so [AuthBloc] can emit [TokenRefreshFailed].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenRepository tokenRepository,
    required Dio dio,
    required OnTokenRefreshFailed onTokenRefreshFailed,
  })  : _tokenRepo = tokenRepository,
        _dio = dio,
        _onTokenRefreshFailed = onTokenRefreshFailed;

  final TokenRepository _tokenRepo;

  /// The same Dio instance used by [ApiClient].  We need it to call the
  /// refresh endpoint with a clean interceptor stack (no recursive 401 loops).
  final Dio _dio;

  final OnTokenRefreshFailed _onTokenRefreshFailed;

  /// Mutex that serialises concurrent refresh attempts.
  final _refreshMutex = Mutex();

  static const _refreshPath = '/api/v1/auth/refresh';

  // ---------------------------------------------------------------------------
  // Request phase — attach token
  // ---------------------------------------------------------------------------

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenRepo.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ---------------------------------------------------------------------------
  // Error phase — handle 401
  // ---------------------------------------------------------------------------

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response == null || response.statusCode != 401) {
      // Not a 401 — let ErrorInterceptor handle it.
      handler.next(err);
      return;
    }

    // Prevent retrying the refresh endpoint itself to avoid infinite loops.
    if (err.requestOptions.path.contains(_refreshPath)) {
      await _tokenRepo.clearAll();
      _onTokenRefreshFailed();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = await _acquireNewToken(err.requestOptions);
      if (retryOptions == null) {
        handler.next(err);
        return;
      }

      // Retry the original request with the fresh token.
      final retryResponse = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Acquires the mutex, refreshes the token if needed, and returns updated
  /// [RequestOptions] with the new `Authorization` header.
  ///
  /// Returns `null` when refresh has permanently failed.
  Future<RequestOptions?> _acquireNewToken(RequestOptions original) async {
    return _refreshMutex.protect(() async {
      // Another request already refreshed the token while we were waiting.
      final currentToken = await _tokenRepo.getAccessToken();
      final previousToken = original.headers['Authorization'];
      final previousBearerToken = previousToken is String
          ? previousToken.replaceFirst('Bearer ', '')
          : null;

      if (currentToken != null &&
          currentToken.isNotEmpty &&
          currentToken != previousBearerToken) {
        // Token was already refreshed by a concurrent request; just retry.
        return _cloneWithToken(original, currentToken);
      }

      // Attempt the refresh.
      final refreshed = await _refreshTokens();
      if (!refreshed) {
        return null;
      }

      final newToken = await _tokenRepo.getAccessToken();
      if (newToken == null || newToken.isEmpty) return null;

      return _cloneWithToken(original, newToken);
    });
  }

  /// Calls `POST /api/v1/auth/refresh`.
  ///
  /// Returns `true` on success, `false` when the call fails.
  Future<bool> _refreshTokens() async {
    final refreshToken = await _tokenRepo.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenRepo.clearAll();
      _onTokenRefreshFailed();
      return false;
    }

    try {
      final response = await _dio.post<dynamic>(
        _refreshPath,
        data: {'refresh_token': refreshToken},
        options: Options(
          // Skip auth header to avoid recursive attachment.
          headers: {'Authorization': null},
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final accessToken = data['jwt_token'] as String? ??
            data['access_token'] as String? ??
            data['token'] as String?;
        final newRefresh = data['refresh_token'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          await _tokenRepo.saveBaseToken(accessToken);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await _tokenRepo.saveRefreshToken(newRefresh);
          }
          return true;
        }
      }

      // Unexpected response shape.
      await _tokenRepo.clearAll();
      _onTokenRefreshFailed();
      return false;
    } catch (_) {
      await _tokenRepo.clearAll();
      _onTokenRefreshFailed();
      return false;
    }
  }

  /// Creates a copy of [original] with an updated `Authorization` header.
  RequestOptions _cloneWithToken(RequestOptions original, String token) {
    final opts = original.copyWith();
    opts.headers['Authorization'] = 'Bearer $token';
    return opts;
  }
}
