import 'package:api_client/api_client.dart';
import 'package:auth/src/auth_repository.dart';
import 'package:auth/src/secure_token_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Authentication state machine for the RMS Staff Portal.
///
/// Manages the full auth lifecycle: app launch check, registration, login,
/// restaurant selection, logout, token-refresh failure, and password change.
///
/// Requirements satisfied: 2.1, 2.2, 2.3, 2.4, 2.5, 2.8, 2.9,
///                         16.1, 16.2.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required SecureTokenRepository tokenRepository,
  })  : _authRepo = authRepository,
        _tokenRepo = tokenRepository,
        super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<RestaurantSelected>(_onRestaurantSelected);
    on<LogoutRequested>(_onLogoutRequested);
    on<RestaurantSwitchRequested>(_onRestaurantSwitchRequested);
    on<TokenRefreshFailed>(_onTokenRefreshFailed);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
  }

  final AuthRepository _authRepo;
  final SecureTokenRepository _tokenRepo;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  /// Checks for a stored, valid Tenant_JWT on app launch.
  ///
  /// Navigates to Dashboard if found; otherwise navigates to Login
  /// (Requirements 2.8, 2.9).
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      // Prime the in-memory cache from secure storage.
      await _tokenRepo.getTenantToken();

      if (_tokenRepo.isTenantTokenValid()) {
        final tenantToken = await _tokenRepo.getTenantToken();
        final roleState = _resolveRoleState(tenantToken!);
        emit(roleState);
      } else {
        // Check whether a Base_JWT exists (user logged in but hasn't selected a
        // restaurant yet — e.g. they closed the app mid-flow).
        final baseToken = await _tokenRepo.getBaseToken();
        if (baseToken != null) {
          emit(const BaseAuthenticated());
        } else {
          emit(const Unauthenticated());
        }
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  /// Calls `POST /api/v1/auth/login`, saves tokens, and emits
  /// [BaseAuthenticated] so the GoRouter guard redirects the user to
  /// `/restaurant-selector` (Requirements 2.2, 2.3).
  ///
  /// Restaurant selection is always required after a fresh login so the user
  /// can pick which restaurant to operate in for this session.
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepo.login(
        email: event.email,
        password: event.password,
      );
      await _tokenRepo.saveRefreshToken(result.refreshToken);

      // Always require restaurant selection after login — store the access
      // token as a Base_JWT and emit BaseAuthenticated. The GoRouter guard
      // will redirect to /restaurant-selector.
      await _tokenRepo.saveBaseToken(result.accessToken);
      emit(const BaseAuthenticated());
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Calls `POST /api/v1/auth/register`; on success emits [Unauthenticated]
  /// so the Router navigates to `/login` (Requirement 2.1).
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepo.register(
        name: event.name,
        email: event.email,
        password: event.password,
        phoneNumber: event.phoneNumber,
      );
      // After registration the user must log in — clear any stale tokens and
      // emit Unauthenticated to direct the Router to /login.
      emit(const Unauthenticated());
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Calls `POST /api/v1/restaurants/:id/select`, stores the Tenant_JWT, and
  /// extracts the [StaffRole] claim.
  ///
  /// Emits [TenantAuthenticated(role)] on success, or [AuthError] when the
  /// role claim is absent/unrecognised (Requirements 3.3, 16.1, 16.2).
  Future<void> _onRestaurantSelected(
    RestaurantSelected event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final tenantToken = await _authRepo.selectRestaurant(
        restaurantId: event.restaurantId,
      );
      await _tokenRepo.saveTenantToken(tenantToken);
      final roleState = _resolveRoleState(tenantToken);
      emit(roleState);
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Clears all stored tokens and emits [Unauthenticated] (Requirement 2.9).
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _tokenRepo.clearAll();
    emit(const Unauthenticated());
  }

  /// Clears tenant scope only — user stays logged in and picks another venue.
  Future<void> _onRestaurantSwitchRequested(
    RestaurantSwitchRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _tokenRepo.clearTenantToken();
    emit(const BaseAuthenticated());
  }

  /// Clears all stored tokens and emits [Unauthenticated].
  ///
  /// Triggered by [AuthInterceptor] when a silent token-refresh fails
  /// (Requirements 18.1, 18.2).
  Future<void> _onTokenRefreshFailed(
    TokenRefreshFailed event,
    Emitter<AuthState> emit,
  ) async {
    await _tokenRepo.clearAll();
    emit(const Unauthenticated());
  }

  /// Calls `POST /api/v1/auth/change-password`.
  ///
  /// Emits [BaseAuthenticated] on success, or [AuthError] on failure
  /// (Requirements 2.4, 2.5).
  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepo.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(const BaseAuthenticated());
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Decodes the [StaffRole] from the Tenant_JWT `role` claim and returns the
  /// appropriate [AuthState].
  ///
  /// Returns [AuthError] when the claim is missing or unrecognised, satisfying
  /// Requirement 16.2.
  AuthState _resolveRoleState(String tenantToken) {
    final roleString = SecureTokenRepository.extractRole(tenantToken);
    if (roleString == null) {
      return const AuthError(
        message: 'Authentication token is missing the required role claim. '
            'Please log in again.',
      );
    }
    // Match the role string against StaffRole.jsonValue.
    final role =
        StaffRole.values.where((r) => r.jsonValue == roleString).firstOrNull;
    if (role == null) {
      return AuthError(
        message: 'Unrecognised role "$roleString" in authentication token. '
            'Please contact your administrator.',
      );
    }
    return TenantAuthenticated(role: role);
  }
}
