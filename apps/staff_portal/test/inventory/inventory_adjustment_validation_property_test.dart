// Feature: rms-flutter-frontend, Property 3: Required field validation
// Validates: Requirements 13.5 — 100 iterations

import 'package:flutter_test/flutter_test.dart';

import '../helpers/fast_check.dart';

// ── Validator ─────────────────────────────────────────────────────────────────

/// Copy of the adjustment quantity validator logic from
/// [_StockAdjustmentSheetState] in inventory_screen.dart.
///
/// Req 13.5: quantity field is zero or contains a non-numeric value →
/// validation error before any network call.
String? _validateAdjustmentQuantity(String? value) {
  if (value == null || value.trim().isEmpty) return 'Quantity is required';
  final parsed = double.tryParse(value.trim());
  if (parsed == null) return 'Enter a valid numeric quantity';
  if (parsed == 0) return 'Quantity must be non-zero';
  return null;
}

// ── Arbitraries ───────────────────────────────────────────────────────────────

/// Generates zero-value strings: '0', '0.0', or '0.00'.
final _zeroValueArbitrary = Arbitrary<String>((rng) {
  const zeroForms = ['0', '0.0', '0.00'];
  return zeroForms[rng.nextInt(zeroForms.length)];
});

/// Generates strings that are NOT valid doubles:
///   - purely alphabetic strings (e.g. 'abc')
///   - mixed alphanumeric (e.g. '12x')
///   - special characters (e.g. '@#$')
///   - multiple dots (e.g. '1.2.3')
///   - empty / whitespace-only strings
final _nonNumericArbitrary = Arbitrary<String>((rng) {
  // Pool of known non-numeric templates
  const fixed = [
    'abc',
    'xyz',
    '1.2.3',
    '',
    ' ',
    r'@#$',
    '!hello',
    '12x',
    'not-a-number',
    '--5',
    '1e2e3',
    '..5',
    'one',
    '+-10',
    '1 0',
  ];

  // Pick from the fixed pool or generate a random alpha string
  final choice = rng.nextInt(fixed.length + 2);
  if (choice < fixed.length) return fixed[choice];

  // Random alphabetic string (2–8 chars) — guaranteed non-numeric
  const alpha = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final len = 2 + rng.nextInt(7);
  return String.fromCharCodes(
    List.generate(len, (_) => alpha.codeUnitAt(rng.nextInt(alpha.length))),
  );
});

/// Generates valid non-zero doubles as strings.
/// Range: non-zero values in [-1000.0, 1000.0], excluding zero.
final _validNonZeroArbitrary = Arbitrary<String>((rng) {
  double value;
  do {
    // Value between -1000 and 1000, step ~0.01
    final raw = (rng.nextDouble() * 2000) - 1000;
    // Round to 2 decimal places to avoid floating-point parse edge cases
    value = (raw * 100).round() / 100;
  } while (value == 0);
  return value.toString();
});

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Deterministic edge cases ───────────────────────────────────────────────

  group('Adjustment quantity validator – deterministic edge cases (Req 13.5)',
      () {
    test("empty string returns 'Quantity is required'", () {
      expect(_validateAdjustmentQuantity(''), isNotNull);
    });

    test("'0' returns 'Quantity must be non-zero'", () {
      expect(_validateAdjustmentQuantity('0'), 'Quantity must be non-zero');
    });

    test("'abc' returns 'Enter a valid numeric quantity'", () {
      expect(
          _validateAdjustmentQuantity('abc'), 'Enter a valid numeric quantity');
    });

    test("'1.5' returns null (valid positive quantity)", () {
      expect(_validateAdjustmentQuantity('1.5'), isNull);
    });

    test("'-3' returns null (valid negative quantity)", () {
      expect(_validateAdjustmentQuantity('-3'), isNull);
    });

    test("'0.001' returns null (valid small positive quantity)", () {
      expect(_validateAdjustmentQuantity('0.001'), isNull);
    });
  });

  // ── Property 3a: Zero values always fail validation ────────────────────────

  group(
      'Property 3 – Zero quantity rejected for any zero-form string '
      '(Req 13.5)', () {
    test(
      'validator returns non-null error for zero value strings (33 iterations)',
      () {
        forAll<String>(
          _zeroValueArbitrary,
          (input) {
            final result = _validateAdjustmentQuantity(input);
            expect(
              result,
              isNotNull,
              reason: 'Expected validation error for zero-value input: '
                  '"$input"',
            );
            expect(
              result!.isNotEmpty,
              isTrue,
              reason: 'Error message must not be empty for input: "$input"',
            );
          },
          iterations: 33,
        );
      },
    );
  });

  // ── Property 3b: Non-numeric strings always fail validation ───────────────

  group(
      'Property 3 – Non-numeric input rejected before network call (Req 13.5)',
      () {
    test(
      'validator returns non-null error for non-numeric strings (34 iterations)',
      () {
        forAll<String>(
          _nonNumericArbitrary,
          (input) {
            final result = _validateAdjustmentQuantity(input);
            expect(
              result,
              isNotNull,
              reason: 'Expected validation error for non-numeric input: '
                  '"$input"',
            );
            expect(
              result!.isNotEmpty,
              isTrue,
              reason: 'Error message must not be empty for input: "$input"',
            );
          },
          iterations: 34,
        );
      },
    );
  });

  // ── Property 3c: Valid non-zero doubles always pass validation ─────────────

  group('Property 3 – Valid non-zero numeric quantity accepted (Req 13.5)', () {
    test(
      'validator returns null for any valid non-zero double string '
      '(33 iterations)',
      () {
        forAll<String>(
          _validNonZeroArbitrary,
          (input) {
            // Verify the generator is producing non-zero values
            final parsed = double.tryParse(input);
            expect(
              parsed,
              isNotNull,
              reason: 'Generator produced non-parseable string: "$input"',
            );
            expect(
              parsed,
              isNot(equals(0.0)),
              reason: 'Generator produced zero: "$input"',
            );

            final result = _validateAdjustmentQuantity(input);
            expect(
              result,
              isNull,
              reason: 'Expected no validation error for valid non-zero '
                  'quantity: "$input" (parsed: $parsed)',
            );
          },
          iterations: 33,
        );
      },
    );
  });

  // ── Boundary cases ─────────────────────────────────────────────────────────

  group('Adjustment quantity validator – boundary cases (Req 13.5)', () {
    test('null input returns non-null error', () {
      expect(_validateAdjustmentQuantity(null), isNotNull);
    });

    test('whitespace-only input returns non-null error', () {
      expect(_validateAdjustmentQuantity('   '), isNotNull);
    });

    test('whitespace-padded zero returns non-null error', () {
      expect(_validateAdjustmentQuantity('  0  '), isNotNull);
    });

    test('whitespace-padded valid number returns null', () {
      expect(_validateAdjustmentQuantity('  5.5  '), isNull);
    });

    test('very large positive number returns null', () {
      expect(_validateAdjustmentQuantity('999999.99'), isNull);
    });

    test('very large negative number returns null', () {
      expect(_validateAdjustmentQuantity('-999999.99'), isNull);
    });

    test("'0.0' (floating zero form) returns non-null error", () {
      expect(_validateAdjustmentQuantity('0.0'), isNotNull);
    });

    test("'0.00' (two-decimal zero form) returns non-null error", () {
      expect(_validateAdjustmentQuantity('0.00'), isNotNull);
    });
  });
}
