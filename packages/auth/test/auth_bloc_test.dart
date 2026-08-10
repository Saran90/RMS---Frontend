import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:auth/src/auth_bloc.dart';
import 'package:auth/src/auth_repository.dart';
import 'package:auth/src/secure_token_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:models/models.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// ---------------------------------------------------------------------------
// JWT helpers
// ---------------------------------------------------------------------------

String _buildJwt({
  required int expOffsetSeconds,
  String role = 'owner',
  String fullName = 'Test User',
}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(
    utf8.encode(
      '{"sub":"1","exp":${nowEpoch + expOffsetSeconds},"role":"$role","full_name":"$fullName"}',
    ),
  );
  return '$header.$payload.fakesig';
}

String _buildJwtNoRole({int expOffsetSeconds = 3600}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(
    utf8.encode('{"sub":"1","exp":${nowEpoch + expOffsetSeconds}}'),
  );
  return '$header.$payload.fakesig';
}

String _buildJwtBadRole({int expOffsetSeconds = 3600}) =>
    _buildJwt(expOffsetSeconds: expOffsetSeconds, role: 'superadmin');

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAuthRepository mockRepo;
  late MockFlutterSecureStorage mockStorage;
  late SecureTokenRepository tokenRepo;

  AuthBloc buildBloc() => AuthBloc(
        authRepository: mockRepo,
        tokenRepository: tokenRepo,
      );

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockFlutterSecureStorage();
    tokenRepo = SecureTokenRepository(storage: mockStorage);

    // Default stub: storage reads return null, writes/deletes are no-ops.
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    // Default: multiple restaurants → show selector after login.
    when(() => mockRepo.getRestaurants()).thenAnswer(
      (_) async => [
        const Restaurant(
          id: 'rest_1',
          name: 'Restaurant One',
          address: '',
          phone: '',
          gstNumber: '',
        ),
        const Restaurant(
          id: 'rest_2',
          name: 'Restaurant Two',
          address: '',
          phone: '',
          gstNumber: '',
        ),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // AppStarted
  // -------------------------------------------------------------------------

  group('AppStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no tokens are stored',
      build: buildBloc,
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, BaseAuthenticated] when base token exists but '
      'no tenant token is stored',
      build: buildBloc,
      setUp: () {
        when(() => mockStorage.read(key: 'rms_base_token'))
            .thenAnswer((_) async => 'base_tok');
        when(() => mockStorage.read(key: 'rms_tenant_token'))
            .thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthLoading(), const BaseAuthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, TenantAuthenticated(owner)] '
      'when a valid tenant JWT with role=owner is stored',
      build: buildBloc,
      setUp: () {
        final token = _buildJwt(expOffsetSeconds: 3600);
        when(() => mockStorage.read(key: 'rms_tenant_token'))
            .thenAnswer((_) async => token);
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => const [
        AuthLoading(),
        TenantAuthenticated(role: StaffRole.owner, displayName: 'Test User'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when the stored tenant JWT is expired',
      build: buildBloc,
      setUp: () {
        final token = _buildJwt(expOffsetSeconds: -10);
        when(() => mockStorage.read(key: 'rms_tenant_token'))
            .thenAnswer((_) async => token);
        when(() => mockStorage.read(key: 'rms_base_token'))
            .thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });

  // -------------------------------------------------------------------------
  // LoginRequested
  // -------------------------------------------------------------------------

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, TenantAuthenticated(waiter)] when login finds one restaurant',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.login(
            email: null,
            username: 'waiter1',
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async => const AuthTokens(
            accessToken: 'base_tok',
            refreshToken: 'refresh_tok',
          ),
        );
        when(() => mockRepo.getRestaurants()).thenAnswer(
          (_) async => [
            const Restaurant(
              id: 'rest_1',
              name: 'Single Venue',
              address: '',
              phone: '',
              gstNumber: '',
            ),
          ],
        );
        when(
          () => mockRepo.selectRestaurant(restaurantId: 'rest_1'),
        ).thenAnswer((_) async => _buildJwt(expOffsetSeconds: 3600, role: 'waiter'));
      },
      act: (bloc) => bloc.add(
        const LoginRequested(username: 'waiter1', password: 'password123'),
      ),
      expect: () => [
        const AuthLoading(),
        const TenantAuthenticated(
          role: StaffRole.waiter,
          displayName: 'Test User',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, BaseAuthenticated] on successful login',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.login(
            email: 'user@test.com',
            username: null,
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async => const AuthTokens(
            accessToken: 'base_tok',
            refreshToken: 'refresh_tok',
          ),
        );
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'user@test.com', password: 'password123'),
      ),
      expect: () => [const AuthLoading(), const BaseAuthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login returns 401',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.login(
            email: any(named: 'email'),
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          const ApiException(
            statusCode: 401,
            errorCode: 'UNAUTHORIZED',
            message: 'Invalid credentials',
          ),
        );
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'bad@test.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Invalid credentials'),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // RegisterRequested
  // -------------------------------------------------------------------------

  group('RegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on successful registration',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(
        const RegisterRequested(
          name: 'Alice',
          email: 'alice@test.com',
          password: 'Secure1234',
        ),
      ),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when registration fails',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          const ApiException(
            statusCode: 409,
            errorCode: 'EMAIL_EXISTS',
            message: 'Email already in use',
          ),
        );
      },
      act: (bloc) => bloc.add(
        const RegisterRequested(
          name: 'Alice',
          email: 'alice@test.com',
          password: 'Secure1234',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Email already in use'),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // RestaurantSelected
  // -------------------------------------------------------------------------

  group('RestaurantSelected', () {
    // Parameterised: one test per StaffRole value.
    for (final role in StaffRole.values) {
      blocTest<AuthBloc, AuthState>(
        'emits TenantAuthenticated(${role.name}) '
        'when tenant JWT contains role=${role.jsonValue}',
        build: buildBloc,
        setUp: () {
          final token = _buildJwt(
            expOffsetSeconds: 3600,
            role: role.jsonValue,
          );
          when(
            () => mockRepo.selectRestaurant(restaurantId: 'rest_1'),
          ).thenAnswer((_) async => token);
        },
        act: (bloc) => bloc.add(
          const RestaurantSelected(restaurantId: 'rest_1'),
        ),
        expect: () => [
          const AuthLoading(),
          TenantAuthenticated(role: role, displayName: 'Test User'),
        ],
      );
    }

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when tenant JWT has no role claim',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.selectRestaurant(
            restaurantId: any(named: 'restaurantId'),
          ),
        ).thenAnswer((_) async => _buildJwtNoRole());
      },
      act: (bloc) => bloc.add(
        const RestaurantSelected(restaurantId: 'rest_1'),
      ),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when tenant JWT has an unrecognised role',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.selectRestaurant(
            restaurantId: any(named: 'restaurantId'),
          ),
        ).thenAnswer((_) async => _buildJwtBadRole());
      },
      act: (bloc) => bloc.add(
        const RestaurantSelected(restaurantId: 'rest_1'),
      ),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when selectRestaurant API call fails',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.selectRestaurant(
            restaurantId: any(named: 'restaurantId'),
          ),
        ).thenThrow(
          const ApiException(
            statusCode: 403,
            errorCode: 'FORBIDDEN',
            message: 'Not authorised for this restaurant',
          ),
        );
      },
      act: (bloc) => bloc.add(
        const RestaurantSelected(restaurantId: 'rest_1'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Not authorised for this restaurant'),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // LogoutRequested
  // -------------------------------------------------------------------------

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] and deletes all token keys',
      build: buildBloc,
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [const Unauthenticated()],
      verify: (_) {
        verify(() => mockStorage.delete(key: 'rms_base_token')).called(1);
        verify(() => mockStorage.delete(key: 'rms_refresh_token')).called(1);
        verify(() => mockStorage.delete(key: 'rms_tenant_token')).called(1);
      },
    );
  });

  group('RestaurantSwitchRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [BaseAuthenticated] and deletes tenant token only',
      build: buildBloc,
      act: (bloc) => bloc.add(const RestaurantSwitchRequested()),
      expect: () => [const BaseAuthenticated()],
      verify: (_) {
        verify(() => mockStorage.delete(key: 'rms_tenant_token')).called(1);
        verifyNever(() => mockStorage.delete(key: 'rms_base_token'));
        verifyNever(() => mockStorage.delete(key: 'rms_refresh_token'));
      },
    );
  });

  // -------------------------------------------------------------------------
  // TokenRefreshFailed
  // -------------------------------------------------------------------------

  group('TokenRefreshFailed', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] and deletes all token keys',
      build: buildBloc,
      act: (bloc) => bloc.add(const TokenRefreshFailed()),
      expect: () => [const Unauthenticated()],
      verify: (_) {
        verify(() => mockStorage.delete(key: 'rms_base_token')).called(1);
        verify(() => mockStorage.delete(key: 'rms_refresh_token')).called(1);
        verify(() => mockStorage.delete(key: 'rms_tenant_token')).called(1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // ChangePasswordRequested
  // -------------------------------------------------------------------------

  group('ChangePasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, BaseAuthenticated] on success',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(
        const ChangePasswordRequested(
          currentPassword: 'OldPass1',
          newPassword: 'NewPass99',
        ),
      ),
      expect: () => [const AuthLoading(), const BaseAuthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when current password is wrong (401)',
      build: buildBloc,
      setUp: () {
        when(
          () => mockRepo.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenThrow(
          const ApiException(
            statusCode: 401,
            errorCode: 'WRONG_PASSWORD',
            message: 'Current password is incorrect',
          ),
        );
      },
      act: (bloc) => bloc.add(
        const ChangePasswordRequested(
          currentPassword: 'wrongpass',
          newPassword: 'NewPass99',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Current password is incorrect'),
      ],
    );
  });
}
