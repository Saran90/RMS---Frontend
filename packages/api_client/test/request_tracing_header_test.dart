// Feature: rms-flutter-frontend, Property 13: Request tracing header
//
// Validates: Requirements 18.8
//
// For any outgoing HTTP request made by ApiClient:
//   1. The request SHALL contain an `X-Request-ID` header.
//   2. The value SHALL match the UUID v4 format.
//   3. No two concurrent requests SHALL share the same value.

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fast_check.dart';

// ---------------------------------------------------------------------------
// Regex for UUID v4 (canonical lower-case hex, version=4, variant=8|9|a|b)
// ---------------------------------------------------------------------------

final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

// ---------------------------------------------------------------------------
// Minimal in-memory TokenRepository stub
// ---------------------------------------------------------------------------

class _StubTokenRepository implements TokenRepository {
  @override
  Future<void> saveBaseToken(String token) async {}
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> saveTenantToken(String token) async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<String?> getBaseToken() async => null;
  @override
  Future<String?> getTenantToken() async => null;
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> clearTenantToken() async {}
  @override
  bool isTenantTokenValid() => false;
}

// ---------------------------------------------------------------------------
// Mock HTTP adapter that records captured request headers.
// Using `implements` (not `extends`) because HttpClientAdapter is abstract
// and has no default unnamed constructor in Dio 5.x.
// ---------------------------------------------------------------------------

class _CapturingAdapter implements HttpClientAdapter {
  /// List of `X-Request-ID` values seen, in arrival order.
  final List<String> capturedIds = [];

  /// Completer list for controlling when each response is released.
  final _completers = <Completer<ResponseBody>>[];

  /// Enqueue a completer so the next request will wait until [releaseAll] is
  /// called.
  void queuePause() => _completers.add(Completer<ResponseBody>());

  /// Release all pending requests with a 200 OK empty body.
  void releaseAll() {
    for (final c in List<Completer<ResponseBody>>.from(_completers)) {
      if (!c.isCompleted) {
        c.complete(ResponseBody.fromString(
          '{}',
          200,
          headers: {
            'content-type': ['application/json']
          },
        ));
      }
    }
    _completers.clear();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final id = options.headers['X-Request-ID'];
    if (id is String) capturedIds.add(id);

    if (_completers.isNotEmpty) {
      // Each request consumes its own completer.
      final completer = _completers.removeAt(0);
      return completer.future;
    }

    // Default: respond immediately.
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Helper — build an ApiClient wired to the given adapter.
// ---------------------------------------------------------------------------

ApiClient _buildClient(_CapturingAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://test.local',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  dio.httpClientAdapter = adapter;

  return ApiClient(
    baseUrl: 'http://test.local',
    tokenRepository: _StubTokenRepository(),
    onTokenRefreshFailed: () {},
    dio: dio,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Feature: rms-flutter-frontend, Property 13: Request tracing header
  group('Property 13: Request Tracing Header', () {
    // Validates: Requirements 18.8

    test(
      'every sequential request carries a non-empty X-Request-ID '
      'matching UUID v4 format',
      () async {
        // Run 100 iterations; each iteration fires one GET and checks the header.
        await forAllAsync(
          Arbitrary.string(minLen: 1, maxLen: 20),
          (path) async {
            final adapter = _CapturingAdapter();
            final client = _buildClient(adapter);

            await client.get<dynamic>('/probe');

            expect(adapter.capturedIds.length, 1,
                reason: 'Expected exactly one request');

            final id = adapter.capturedIds.first;
            expect(id, isNotEmpty);
            expect(
              _uuidV4Pattern.hasMatch(id),
              isTrue,
              reason: 'X-Request-ID "$id" does not match UUID v4 pattern',
            );
          },
          iterations: 100,
        );
      },
    );

    test(
      'no two concurrent requests share the same X-Request-ID value',
      () async {
        // Property: for any N concurrent in-flight requests (1 ≤ N ≤ 20),
        // all N X-Request-ID values are distinct and each matches UUID v4.
        await forAllAsync(
          Arbitrary.positiveInt(max: 20), // N in [1..20]
          (n) async {
            final adapter = _CapturingAdapter();

            // Queue N pausers so all requests are in-flight simultaneously.
            for (var i = 0; i < n; i++) {
              adapter.queuePause();
            }

            final client = _buildClient(adapter);

            // Fire N concurrent requests.
            final futures = List.generate(
              n,
              (_) => client.get<dynamic>('/concurrent').catchError((_) => null),
            );

            // Give the event loop a turn so all requests enter the adapter.
            await Future<void>.delayed(Duration.zero);

            // Release all pending requests.
            adapter.releaseAll();

            // Wait for all to complete (ignore responses — only headers matter).
            await Future.wait(futures);

            // Assertions on the captured IDs.
            expect(
              adapter.capturedIds.length,
              n,
              reason: 'Expected $n requests but got '
                  '${adapter.capturedIds.length}',
            );

            for (final id in adapter.capturedIds) {
              expect(
                _uuidV4Pattern.hasMatch(id),
                isTrue,
                reason: 'X-Request-ID "$id" does not match UUID v4 pattern',
              );
            }

            // All values must be unique.
            final unique = adapter.capturedIds.toSet();
            expect(
              unique.length,
              adapter.capturedIds.length,
              reason: 'Duplicate X-Request-ID values found among concurrent '
                  'requests: ${adapter.capturedIds}',
            );
          },
          iterations: 100,
        );
      },
    );

    test(
      'X-Request-ID is present on GET, POST, PATCH, and DELETE requests',
      () async {
        final adapter = _CapturingAdapter();
        final client = _buildClient(adapter);

        await Future.wait([
          client.get<dynamic>('/get-path'),
          client.post<dynamic>('/post-path', body: {}),
          client.patch<dynamic>('/patch-path', body: {}),
          client.delete<dynamic>('/delete-path'),
        ]);

        expect(adapter.capturedIds.length, 4,
            reason: 'Expected 4 requests (GET/POST/PATCH/DELETE)');

        for (final id in adapter.capturedIds) {
          expect(
            _uuidV4Pattern.hasMatch(id),
            isTrue,
            reason: 'X-Request-ID "$id" is not a valid UUID v4',
          );
        }

        // All four must be distinct.
        expect(
          adapter.capturedIds.toSet().length,
          4,
          reason: 'Expected 4 distinct X-Request-ID values, got duplicates: '
              '${adapter.capturedIds}',
        );
      },
    );
  });
}
