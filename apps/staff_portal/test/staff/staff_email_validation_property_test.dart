// Feature: rms-flutter-frontend, Property 3: Required field validation
// Validates: Requirements 12.4 — 100 iterations

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/fast_check.dart';

// ── Email validator (mirrors _InviteStaffSheetState in staff_screen.dart) ─────

final _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');

/// Extracted standalone email validator — identical logic to the production
/// [_InviteStaffSheet] validator (Req 12.4).
String? _validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email is required';
  if (!_emailRegExp.hasMatch(value.trim()))
    return 'Enter a valid email address';
  return null;
}

// ── Arbitraries ───────────────────────────────────────────────────────────────

/// Characters safe for use in email local-parts and domains.
const _alphaNum = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// Generates a random alphanumeric segment of length [min]..[max].
String _segment(Random rng, {int min = 2, int max = 8}) {
  final len = min + rng.nextInt(max - min + 1);
  return String.fromCharCodes(
    List.generate(
        len, (_) => _alphaNum.codeUnitAt(rng.nextInt(_alphaNum.length))),
  );
}

/// Generates valid email strings matching `name@domain.tld`.
/// e.g. "user@example.com", "abc@foo.org"
final _validEmailArbitrary = Arbitrary<String>((rng) {
  final local = _segment(rng, min: 1, max: 10);
  final domain = _segment(rng, min: 2, max: 8);
  final tld = _segment(rng, min: 2, max: 4);
  return '$local@$domain.$tld';
});

/// Generates strings that are missing the `@` symbol entirely.
final _missingAtArbitrary = Arbitrary<String>((rng) {
  // Produce plain alphanumeric strings — no '@' character
  return _segment(rng, min: 3, max: 15);
});

/// Generates strings that have a `@` but no domain part (e.g. `"user@"`).
final _missingDomainArbitrary = Arbitrary<String>((rng) {
  final local = _segment(rng, min: 1, max: 10);
  return '$local@';
});

/// Generates strings with local-part and domain but no TLD
/// (e.g. `"user@domain"` — no dot after `@`-domain).
final _missingTldArbitrary = Arbitrary<String>((rng) {
  final local = _segment(rng, min: 1, max: 10);
  final domain = _segment(rng, min: 2, max: 8);
  return '$local@$domain';
});

/// Generates strings with nothing before the `@` (e.g. `"@domain.com"`).
final _emptyLocalArbitrary = Arbitrary<String>((rng) {
  final domain = _segment(rng, min: 2, max: 8);
  final tld = _segment(rng, min: 2, max: 4);
  return '@$domain.$tld';
});

// ─────────────────────────────────────────────────────────────────────────────
// Property tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Property 3 – Required field validation: staff invite email (Req 12.4)',
      () {
    // ── Section 1: Blank / empty / null inputs ──────────────────────────────

    group('1. Blank, empty, and null inputs produce a non-null error', () {
      test('null value returns error', () {
        expect(_validateEmail(null), isNotNull);
        expect(_validateEmail(null), equals('Email is required'));
      });

      test('empty string returns error', () {
        expect(_validateEmail(''), isNotNull);
        expect(_validateEmail(''), equals('Email is required'));
      });

      test('whitespace-only string returns error', () {
        expect(_validateEmail('   '), isNotNull);
        expect(_validateEmail('   '), equals('Email is required'));
      });

      test(
        'all blank/whitespace variants return non-null error (100 iterations)',
        () {
          final rng = Random(42);
          // Generate strings of 0–10 spaces
          for (var i = 0; i < 100; i++) {
            final spaces = ' ' * rng.nextInt(11); // 0..10 spaces
            final result = _validateEmail(spaces);
            expect(
              result,
              isNotNull,
              reason:
                  'Expected error for blank input: "${spaces.length} spaces"',
            );
          }
        },
      );
    });

    // ── Section 2: Invalid format inputs ────────────────────────────────────

    group('2. Invalid format strings produce a non-null error', () {
      test('missing @ — "notanemail" returns error', () {
        expect(_validateEmail('notanemail'), isNotNull);
      });

      test('missing domain — "user@" returns error', () {
        expect(_validateEmail('user@'), isNotNull);
      });

      test('empty local-part — "@domain.com" returns error', () {
        expect(_validateEmail('@domain.com'), isNotNull);
      });

      test('missing TLD — "user@domain" returns error', () {
        expect(_validateEmail('user@domain'), isNotNull);
      });

      test(
        'strings missing @ return non-null error (100 iterations)',
        () {
          forAll<String>(
            _missingAtArbitrary,
            (input) {
              expect(
                input.contains('@'),
                isFalse,
                reason: 'Generator should produce strings without @',
              );
              final result = _validateEmail(input);
              expect(
                result,
                isNotNull,
                reason: 'Expected error for input missing @: "$input"',
              );
            },
            iterations: 100,
          );
        },
      );

      test(
        'strings with @ but no domain ("local@") return non-null error (100 iterations)',
        () {
          forAll<String>(
            _missingDomainArbitrary,
            (input) {
              final result = _validateEmail(input);
              expect(
                result,
                isNotNull,
                reason:
                    'Expected error for input with missing domain: "$input"',
              );
            },
            iterations: 100,
          );
        },
      );

      test(
        'strings with local@domain but no TLD return non-null error (100 iterations)',
        () {
          forAll<String>(
            _missingTldArbitrary,
            (input) {
              expect(
                input.contains('@'),
                isTrue,
                reason: 'Generator should produce strings with @',
              );
              expect(
                input.split('@').last.contains('.'),
                isFalse,
                reason:
                    'Generator should produce strings without a dot after @',
              );
              final result = _validateEmail(input);
              expect(
                result,
                isNotNull,
                reason: 'Expected error for input missing TLD: "$input"',
              );
            },
            iterations: 100,
          );
        },
      );

      test(
        'strings with empty local-part ("@domain.tld") return non-null error (100 iterations)',
        () {
          forAll<String>(
            _emptyLocalArbitrary,
            (input) {
              expect(
                input.startsWith('@'),
                isTrue,
                reason: 'Generator should produce strings starting with @',
              );
              final result = _validateEmail(input);
              expect(
                result,
                isNotNull,
                reason: 'Expected error for empty local-part: "$input"',
              );
            },
            iterations: 100,
          );
        },
      );
    });

    // ── Section 3: Valid email inputs ────────────────────────────────────────

    group('3. Valid email strings return null (no error)', () {
      test('"user@domain.com" returns null', () {
        expect(_validateEmail('user@domain.com'), isNull);
      });

      test('"user.name+tag@sub.domain.org" returns null', () {
        expect(_validateEmail('user.name+tag@sub.domain.org'), isNull);
      });

      test(
        'generated valid emails return null (100 iterations)',
        () {
          forAll<String>(
            _validEmailArbitrary,
            (email) {
              final result = _validateEmail(email);
              expect(
                result,
                isNull,
                reason: 'Expected no error for valid email: "$email"',
              );
            },
            iterations: 100,
          );
        },
      );

      test(
          'valid emails with leading/trailing whitespace return null after trim',
          () {
        // The validator trims before matching — ensure whitespace-padded valid
        // emails are still accepted (the trim is applied internally)
        expect(_validateEmail('  user@domain.com  '), isNull);
        expect(_validateEmail('\tname@example.org\t'), isNull);
      });
    });

    // ── Section 4: Deterministic edge cases ─────────────────────────────────

    group('4. Deterministic edge cases', () {
      final cases = <({String? input, bool expectError, String description})>[
        (input: null, expectError: true, description: 'null'),
        (input: '', expectError: true, description: 'empty string'),
        (input: '   ', expectError: true, description: 'whitespace only'),
        (input: 'notanemail', expectError: true, description: 'missing @'),
        (
          input: 'user@',
          expectError: true,
          description: 'missing domain after @'
        ),
        (
          input: '@domain.com',
          expectError: true,
          description: 'empty local-part'
        ),
        (input: 'user@domain', expectError: true, description: 'missing TLD'),
        (
          input: 'user@domain.com',
          expectError: false,
          description: 'standard valid email'
        ),
        (
          input: 'user.name+tag@sub.domain.org',
          expectError: false,
          description: 'valid with plus and subdomain'
        ),
      ];

      for (final c in cases) {
        test(
            '${c.expectError ? "error" : "null"} for: ${c.description} ("${c.input}")',
            () {
          final result = _validateEmail(c.input);
          if (c.expectError) {
            expect(
              result,
              isNotNull,
              reason:
                  'Expected non-null error for ${c.description}: "${c.input}"',
            );
          } else {
            expect(
              result,
              isNull,
              reason:
                  'Expected null (no error) for ${c.description}: "${c.input}"',
            );
          }
        });
      }
    });
  });
}
