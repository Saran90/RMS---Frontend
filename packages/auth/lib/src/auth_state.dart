part of 'auth_bloc.dart';

/// Sealed base class for all authentication states.
///
/// States emitted by [AuthBloc] drive route guards and UI rendering
/// (Requirements 2.8, 2.9, 16.1, 16.2).
sealed class AuthState {
  const AuthState();
}

/// Initial state before [AppStarted] has been processed.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Transient loading state emitted while an async auth operation is in flight.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No valid session — the Router should redirect to `/login`.
///
/// Emitted after logout, token-refresh failure, or when no valid token is
/// found on launch (Requirements 2.9, 18.2).
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Base_JWT is stored but no Tenant_JWT exists yet.
///
/// The Router should redirect to `/restaurant-selector`
/// (Requirements 2.2, 3.x).
final class BaseAuthenticated extends AuthState {
  const BaseAuthenticated();
}

/// Tenant_JWT is stored and valid; [role] drives role-based navigation.
///
/// The Router should redirect to `/dashboard` (Requirements 2.8, 16.1, 16.2).
final class TenantAuthenticated extends AuthState {
  const TenantAuthenticated({required this.role});

  /// The [StaffRole] extracted from the Tenant_JWT `role` claim.
  final StaffRole role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenantAuthenticated &&
          runtimeType == other.runtimeType &&
          role == other.role;

  @override
  int get hashCode => role.hashCode;
}

/// Terminal error state carrying a human-readable [message].
///
/// Emitted when an auth operation fails or the Tenant_JWT contains a missing
/// or unrecognised role claim (Requirements 16.2, 2.3).
final class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
