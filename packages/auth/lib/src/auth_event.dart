part of 'auth_bloc.dart';

/// Sealed base class for all authentication events.
///
/// Events drive the [AuthBloc] state machine (Requirements 2.1–2.5, 16.1).
sealed class AuthEvent {
  const AuthEvent();
}

/// Dispatched when the app first launches.
///
/// [AuthBloc] checks for an existing, valid Tenant_JWT and navigates to either
/// Dashboard (valid token) or Login (no/expired token) — Requirements 2.8, 2.9.
final class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Dispatched when the user submits the login form.
///
/// On success the Base_JWT is stored and [BaseAuthenticated] is emitted
/// (Requirement 2.2).
final class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;
}

/// Dispatched when the user submits the registration form.
///
/// On success navigates to Login (Requirement 2.1).
final class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  final String name;
  final String email;
  final String password;
  final String? phoneNumber;
}

/// Dispatched after the user selects a restaurant in the Restaurant Selector.
///
/// Exchanges the Base_JWT for a Tenant_JWT, extracts [StaffRole], and emits
/// [TenantAuthenticated] (Requirements 3.3, 16.1, 16.2).
final class RestaurantSelected extends AuthEvent {
  const RestaurantSelected({required this.restaurantId});

  final String restaurantId;
}

/// Dispatched when the user explicitly logs out.
///
/// Clears all stored tokens and emits [Unauthenticated] (Requirement 2.9).
final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Clears the tenant JWT and returns to restaurant selection (keeps login).
final class RestaurantSwitchRequested extends AuthEvent {
  const RestaurantSwitchRequested();
}

/// Dispatched by [AuthInterceptor] when a token refresh attempt fails.
///
/// Clears tokens and forces re-authentication (Requirements 18.1, 18.2).
final class TokenRefreshFailed extends AuthEvent {
  const TokenRefreshFailed();
}

/// Dispatched when the user submits the Change Password form.
///
/// On success emits [BaseAuthenticated]; on failure emits [AuthError]
/// (Requirements 2.4, 2.5).
final class ChangePasswordRequested extends AuthEvent {
  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}
