import 'dart:convert';

import 'package:auth/src/secure_token_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// ---------------------------------------------------------------------------
// Helpers for building JWTs with known claims
// ---------------------------------------------------------------------------

String _buildJwt({required int expOffsetSeconds, String role = 'owner'}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(
    utf8.encode(
      '{"sub":"1","exp":${nowEpoch + expOffsetSeconds},"role":"$role"}',
    ),
  );
  const sig = 'fakesig';
  return '$header.$payload.$sig';
}

String _buildJwtNoRole({required int expOffsetSeconds}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(
    utf8.encode('{"sub":"1","exp":${nowEpoch + expOffsetSeconds}}'),
  );
  const sig = 'fakesig';
  return '$header.$payload.$sig';
}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureTokenRepository repo;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repo = SecureTokenRepository(storage: mockStorage);
  });

  group('saveBaseToken / getBaseToken', () {
    test('writes and reads back the base token', () async {
      const token = 'base_token_abc';
      when(() => mockStorage.write(key: 'rms_base_token', value: token))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: 'rms_base_token'))
          .thenAnswer((_) async => token);

      await repo.saveBaseToken(token);
      final result = await repo.getBaseToken();

      expect(result, token);
    });
  });

  group('saveRefreshToken / getRefreshToken', () {
    test('writes and reads back the refresh token', () async {
      const token = 'refresh_token_xyz';
      when(() => mockStorage.write(key: 'rms_refresh_token', value: token))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: 'rms_refresh_token'))
          .thenAnswer((_) async => token);

      await repo.saveRefreshToken(token);
      final result = await repo.getRefreshToken();

      expect(result, token);
    });
  });

  group('saveTenantToken / getTenantToken', () {
    test('writes and reads back the tenant token', () async {
      final token = _buildJwt(expOffsetSeconds: 3600);
      when(() => mockStorage.write(key: 'rms_tenant_token', value: token))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: 'rms_tenant_token'))
          .thenAnswer((_) async => token);

      await repo.saveTenantToken(token);
      final result = await repo.getTenantToken();

      expect(result, token);
    });
  });

  group('clearAll', () {
    test('deletes all three token keys', () async {
      when(() => mockStorage.delete(key: 'rms_base_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'rms_refresh_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'rms_tenant_token'))
          .thenAnswer((_) async {});

      await repo.clearAll();

      verify(() => mockStorage.delete(key: 'rms_base_token')).called(1);
      verify(() => mockStorage.delete(key: 'rms_refresh_token')).called(1);
      verify(() => mockStorage.delete(key: 'rms_tenant_token')).called(1);
    });

    test('clears the in-memory cache so isTenantTokenValid returns false',
        () async {
      final validToken = _buildJwt(expOffsetSeconds: 3600);
      when(() => mockStorage.write(key: 'rms_tenant_token', value: validToken))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await repo.saveTenantToken(validToken);
      expect(repo.isTenantTokenValid(), isTrue);

      await repo.clearAll();
      expect(repo.isTenantTokenValid(), isFalse);
    });
  });

  group('isTenantTokenValid', () {
    test('returns false when no token has been cached', () {
      expect(repo.isTenantTokenValid(), isFalse);
    });

    test('returns true for a non-expired token (1 hour from now)', () async {
      final token = _buildJwt(expOffsetSeconds: 3600);
      when(() => mockStorage.write(key: 'rms_tenant_token', value: token))
          .thenAnswer((_) async {});

      await repo.saveTenantToken(token);
      expect(repo.isTenantTokenValid(), isTrue);
    });

    test('returns false for an already-expired token (-1 second)', () async {
      final token = _buildJwt(expOffsetSeconds: -1);
      when(() => mockStorage.write(key: 'rms_tenant_token', value: token))
          .thenAnswer((_) async {});

      await repo.saveTenantToken(token);
      expect(repo.isTenantTokenValid(), isFalse);
    });

    test('returns false for a malformed JWT', () async {
      const malformed = 'not.a.jwt';
      when(() => mockStorage.write(key: 'rms_tenant_token', value: malformed))
          .thenAnswer((_) async {});

      await repo.saveTenantToken(malformed);
      expect(repo.isTenantTokenValid(), isFalse);
    });
  });

  group('getAccessToken', () {
    test('returns tenant token when it is valid', () async {
      final tenantToken = _buildJwt(expOffsetSeconds: 3600);
      when(() => mockStorage.write(key: 'rms_tenant_token', value: tenantToken))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: 'rms_tenant_token'))
          .thenAnswer((_) async => tenantToken);

      await repo.saveTenantToken(tenantToken);
      final access = await repo.getAccessToken();
      expect(access, tenantToken);
    });

    test('falls back to base token when tenant token is expired', () async {
      final expiredTenant = _buildJwt(expOffsetSeconds: -10);
      const baseToken = 'base_abc';

      when(() => mockStorage.write(
            key: 'rms_tenant_token',
            value: expiredTenant,
          )).thenAnswer((_) async {});
      when(() => mockStorage.read(key: 'rms_tenant_token'))
          .thenAnswer((_) async => expiredTenant);
      when(() => mockStorage.read(key: 'rms_base_token'))
          .thenAnswer((_) async => baseToken);

      await repo.saveTenantToken(expiredTenant);
      final access = await repo.getAccessToken();
      expect(access, baseToken);
    });

    test('returns null when both tokens are absent', () async {
      when(() => mockStorage.read(key: 'rms_tenant_token'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.read(key: 'rms_base_token'))
          .thenAnswer((_) async => null);

      // Fresh repo — cache is null, storage returns null.
      final access = await repo.getAccessToken();
      expect(access, isNull);
    });
  });

  group('extractRole (static helper)', () {
    test('returns role string from a valid JWT', () {
      final token = _buildJwt(expOffsetSeconds: 3600, role: 'manager');
      expect(SecureTokenRepository.extractRole(token), 'manager');
    });

    test('returns null when role claim is absent', () {
      final token = _buildJwtNoRole(expOffsetSeconds: 3600);
      expect(SecureTokenRepository.extractRole(token), isNull);
    });

    test('returns null for malformed JWT', () {
      expect(SecureTokenRepository.extractRole('bad'), isNull);
    });
  });
}
