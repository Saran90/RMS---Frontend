import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// Data class holding the tokens returned by login/refresh endpoints.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Repository that wraps all authentication-related API calls.
///
/// Delegates to [ApiClient] for HTTP communication and returns plain Dart
/// objects so [AuthBloc] stays free of Dio/HTTP concerns.
class AuthRepository {
  const AuthRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

  /// Calls `POST /api/v1/auth/register`.
  ///
  /// Throws [ApiException] on failure. On success returns `void` — the caller
  /// should navigate to Login (Requirement 2.1).
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    await _client.post<dynamic>(
      '/api/v1/auth/register',
      body: {
        'full_name': name,
        'email': email,
        'password': password,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      },
    );
  }

  /// Calls `POST /api/v1/auth/login` and returns [AuthTokens].
  ///
  /// Provide either [email] (owners) or [username] (staff). Password is always
  /// required. Throws [ApiException] (status 401) on invalid credentials.
  Future<AuthTokens> login({
    String? email,
    String? username,
    required String password,
  }) async {
    final body = <String, dynamic>{'password': password};
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    } else if (username != null && username.trim().isNotEmpty) {
      body['username'] = username.trim();
    }

    final raw = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      body: body,
    );

    // Support both flat   { access_token, refresh_token }
    // and wrapped         { data: { access_token, refresh_token } }
    // response shapes.
    final data = (raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw);

    // Backend returns `jwt_token` (not `access_token`).
    final accessToken = (data['jwt_token'] ?? data['access_token']) as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw const ApiException(
        statusCode: 200,
        errorCode: 'UNEXPECTED_RESPONSE',
        message: 'Login succeeded but the server response was missing tokens. '
            'Check the API response shape.',
      );
    }

    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Calls `POST /api/v1/auth/change-password`.
  ///
  /// Throws [ApiException] on failure (Requirements 2.4, 2.5).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post<dynamic>(
      '/api/v1/auth/change-password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  /// Calls `POST /api/v1/restaurants/:id/select` and returns the raw Tenant_JWT
  /// string.
  ///
  /// Throws [ApiException] on failure (Requirement 3.3).
  Future<String> selectRestaurant({required String restaurantId}) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/restaurants/$restaurantId/select',
    );
    // Support both jwt_token and access_token field names.
    return (data['jwt_token'] ?? data['access_token']) as String;
  }

  /// Lists restaurants accessible with the current Base_JWT.
  Future<List<Restaurant>> getRestaurants() async {
    final raw = await _client.get<dynamic>('/api/v1/restaurants');

    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      final inner = raw['restaurants'] ?? raw['data'] ?? raw['items'] ?? [];
      list = inner is List ? inner : [];
    } else {
      list = [];
    }

    return list
        .map((e) => _parseRestaurant(e as Map<String, dynamic>))
        .whereType<Restaurant>()
        .toList();
  }

  Restaurant? _parseRestaurant(Map<String, dynamic> m) {
    final id = (m['restaurant_id'] ?? m['id'] ?? '') as String;
    if (id.isEmpty) return null;
    return Restaurant(
      id: id,
      name: (m['restaurant_name'] ?? m['name'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      phone: (m['contact_phone'] ?? m['phone'] ?? m['phone_number'] ?? '')
          as String,
      gstNumber: (m['gst_number'] ?? m['gst'] ?? m['gstin'] ?? '') as String,
      logoUrl: m['logo_url'] as String?,
    );
  }
}
