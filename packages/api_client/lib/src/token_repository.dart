/// Abstract interface for token storage.
///
/// The concrete implementation lives in `packages/auth` (SecureTokenRepository).
/// Defining the interface here breaks the circular dependency:
/// api_client depends on the interface; auth depends on api_client and
/// provides the implementation.
abstract class TokenRepository {
  /// Persist the base (login) access token.
  Future<void> saveBaseToken(String token);

  /// Persist the base refresh token.
  Future<void> saveRefreshToken(String token);

  /// Persist the tenant-scoped access token.
  Future<void> saveTenantToken(String token);

  /// Retrieve the current access token (tenant token if available, else base).
  ///
  /// Returns `null` when no token is stored.
  Future<String?> getAccessToken();

  /// Retrieve the stored refresh token.
  ///
  /// Returns `null` when no refresh token is stored.
  Future<String?> getRefreshToken();

  /// Retrieve the base (login) access token.
  Future<String?> getBaseToken();

  /// Retrieve the tenant-scoped access token.
  Future<String?> getTenantToken();

  /// Remove all stored tokens (called on logout / refresh failure).
  Future<void> clearAll();

  /// Removes only the tenant-scoped token (switch restaurant without logout).
  Future<void> clearTenantToken();

  /// Returns `true` when the currently stored tenant token exists and
  /// its `exp` claim has not yet passed.
  bool isTenantTokenValid();
}
