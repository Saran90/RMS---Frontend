import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys used to store tokens in [FlutterSecureStorage].
class _Keys {
  static const baseToken = 'rms_base_token';
  static const refreshToken = 'rms_refresh_token';
  static const tenantToken = 'rms_tenant_token';
}

/// Concrete implementation of [TokenRepository] backed by
/// [FlutterSecureStorage].
///
/// Tokens survive app restarts and are inaccessible to other apps, satisfying
/// Requirements 2.7, 2.8, 2.9.
///
/// JWT `exp` and `role` claims are decoded via manual base64 parsing — no
/// external JWT library needed for simple claim extraction.
class SecureTokenRepository implements TokenRepository {
  SecureTokenRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Cache the tenant token in memory so [isTenantTokenValid] can be
  // synchronous without an async storage read on every check.
  String? _cachedTenantToken;

  // ---------------------------------------------------------------------------
  // TokenRepository interface
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveBaseToken(String token) =>
      _storage.write(key: _Keys.baseToken, value: token);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _Keys.refreshToken, value: token);

  @override
  Future<void> saveTenantToken(String token) async {
    _cachedTenantToken = token;
    await _storage.write(key: _Keys.tenantToken, value: token);
  }

  @override
  Future<String?> getBaseToken() => _storage.read(key: _Keys.baseToken);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _Keys.refreshToken);

  @override
  Future<String?> getTenantToken() async {
    final token = await _storage.read(key: _Keys.tenantToken);
    _cachedTenantToken = token;
    return token;
  }

  /// Returns the tenant token when it exists and is not expired; otherwise
  /// falls back to the base token.
  ///
  /// This is used by [AuthInterceptor] to attach the correct Bearer token to
  /// every outgoing request (Requirements 2.8, 3.7).
  @override
  Future<String?> getAccessToken() async {
    // Ensure the cache is primed from persistent storage.
    if (_cachedTenantToken == null) {
      _cachedTenantToken = await _storage.read(key: _Keys.tenantToken);
    }
    if (isTenantTokenValid()) return _cachedTenantToken;
    return _storage.read(key: _Keys.baseToken);
  }

  /// Removes all stored tokens. Called on logout or token-refresh failure
  /// (Requirements 2.9, 18.2).
  @override
  Future<void> clearAll() async {
    _cachedTenantToken = null;
    await Future.wait([
      _storage.delete(key: _Keys.baseToken),
      _storage.delete(key: _Keys.refreshToken),
      _storage.delete(key: _Keys.tenantToken),
    ]);
  }

  /// Clears the tenant JWT so the user can pick another restaurant.
  @override
  Future<void> clearTenantToken() async {
    _cachedTenantToken = null;
    await _storage.delete(key: _Keys.tenantToken);
  }

  /// Returns `true` when the in-memory cached tenant token exists and its
  /// `exp` claim has not yet passed (Requirement 2.8, 2.9).
  ///
  /// This method is intentionally synchronous — it relies on the in-memory
  /// cache populated by [saveTenantToken] or [getTenantToken].
  @override
  bool isTenantTokenValid() {
    final token = _cachedTenantToken;
    if (token == null || token.isEmpty) return false;
    final exp = _extractExp(token);
    if (exp == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    return DateTime.now().toUtc().isBefore(expiry);
  }

  // ---------------------------------------------------------------------------
  // JWT claim extraction helpers
  // ---------------------------------------------------------------------------

  /// Decodes the JWT payload section and extracts the `exp` claim (Unix epoch
  /// seconds) without relying on any external JWT library.
  ///
  /// Returns `null` if the token is malformed or missing the `exp` field.
  static int? _extractExp(String token) {
    return _extractClaim<int>(token, 'exp');
  }

  /// Decodes the JWT payload section and extracts the `role` claim.
  ///
  /// Returns `null` if the token is malformed or missing the `role` field.
  static String? extractRole(String token) {
    return _extractClaim<String>(token, 'role');
  }

  /// Decodes the JWT payload section and extracts the `full_name` claim.
  static String? extractFullName(String token) {
    return _extractClaim<String>(token, 'full_name');
  }

  /// Decodes the JWT payload and extracts `restaurant_id`.
  static String? extractRestaurantId(String token) {
    return _extractClaim<String>(token, 'restaurant_id');
  }

  /// Generic helper — decodes the JWT payload and returns the value of
  /// [claimKey] cast to [T], or `null` on any failure.
  static T? _extractClaim<T>(String token, String claimKey) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // JWT uses base64url encoding without padding.
      var payload = parts[1];
      // Restore standard base64 padding.
      switch (payload.length % 4) {
        case 2:
          payload += '==';
        case 3:
          payload += '=';
      }
      // Replace URL-safe characters with standard base64 characters.
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final decoded = utf8.decode(base64Decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final value = map[claimKey];
      if (value is T) return value;
      // Handle numeric types that may be returned as num/double.
      if (T == int && value is num) return value.toInt() as T;
      return null;
    } catch (_) {
      return null;
    }
  }
}
