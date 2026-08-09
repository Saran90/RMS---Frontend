// Feature: rms-flutter-frontend, Property 9: Modifier group validation
// Validates: Requirements 7.10 — 100 iterations

import 'package:flutter_test/flutter_test.dart';

import '../helpers/fast_check.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pure validation function extracted from _MenuItemFormSheetState._submit()
// This mirrors the exact check in menu_item_form.dart (Req 7.10).
// ─────────────────────────────────────────────────────────────────────────────

/// Returns null when the modifier group config is valid (saveable).
/// Returns a non-null error string when max_select < min_select.
///
/// Mirrors the validation in `_MenuItemFormSheetState._submit()`.
String? validateModifierGroup({
  required int minSelect,
  required int maxSelect,
}) {
  if (maxSelect < minSelect) {
    return 'max_select ($maxSelect) must be >= min_select ($minSelect)';
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Arbitraries
// ─────────────────────────────────────────────────────────────────────────────

typedef _SelectPair = ({int min, int max});

/// Generates arbitrary (min_select, max_select) pairs.
///
/// min_select range: 0–20 (per Req 7.9)
/// max_select range: 1–20 (per Req 7.9)
final _selectPairArbitrary = Arbitrary<_SelectPair>(
  (rng) => (
    min: rng.nextInt(21), // 0–20
    max: 1 + rng.nextInt(20), // 1–20
  ),
);

/// Generates pairs where max_select is strictly less than min_select.
/// Ensures the invalid case is always tested.
///
/// Strategy: min = 2..20, max = 1..(min-1)
final _invalidPairArbitrary = Arbitrary<_SelectPair>(
  (rng) {
    final min = 2 + rng.nextInt(19); // 2–20
    final max = 1 + rng.nextInt(min); // 1..(min) but we clamp to min-1
    final clampedMax = max >= min ? min - 1 : max;
    return (min: min, max: clampedMax);
  },
);

/// Generates pairs where max_select >= min_select (valid / saveable).
final _validPairArbitrary = Arbitrary<_SelectPair>(
  (rng) {
    final min = rng.nextInt(20); // 0–19
    final max = min + 1 + rng.nextInt(20 - min); // min+1..20 (always >= min)
    return (min: min, max: max.clamp(1, 20));
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Property 9 – Modifier group validation invariant (Req 7.10)', () {
    // ── Core property: saveable iff max >= min ────────────────────────────

    test(
      'validateModifierGroup returns null iff max_select >= min_select '
      '(100 iterations over arbitrary pairs)',
      () {
        forAll<_SelectPair>(
          _selectPairArbitrary,
          (pair) {
            final result = validateModifierGroup(
              minSelect: pair.min,
              maxSelect: pair.max,
            );

            if (pair.max >= pair.min) {
              // Valid: should be saveable (no error)
              expect(
                result,
                isNull,
                reason: 'Expected null (valid) for '
                    'min=${pair.min}, max=${pair.max}',
              );
            } else {
              // Invalid: should be blocked with a non-empty error
              expect(
                result,
                isNotNull,
                reason: 'Expected error (invalid) for '
                    'min=${pair.min}, max=${pair.max}',
              );
              expect(
                result!.isNotEmpty,
                isTrue,
                reason: 'Error message should not be empty',
              );
            }
          },
          iterations: 100,
        );
      },
    );

    // ── Invalid pairs always produce an error ─────────────────────────────

    test(
      'validateModifierGroup always returns error when max_select < min_select '
      '(100 iterations over invalid pairs)',
      () {
        forAll<_SelectPair>(
          _invalidPairArbitrary,
          (pair) {
            expect(
              pair.max,
              lessThan(pair.min),
              reason: 'Generator should only produce invalid pairs',
            );

            final result = validateModifierGroup(
              minSelect: pair.min,
              maxSelect: pair.max,
            );

            expect(
              result,
              isNotNull,
              reason: 'Expected a validation error for '
                  'min=${pair.min}, max=${pair.max}',
            );
            expect(result!.isNotEmpty, isTrue);
          },
          iterations: 100,
        );
      },
    );

    // ── Valid pairs are always saveable ───────────────────────────────────

    test(
      'validateModifierGroup always returns null when max_select >= min_select '
      '(100 iterations over valid pairs)',
      () {
        forAll<_SelectPair>(
          _validPairArbitrary,
          (pair) {
            expect(
              pair.max,
              greaterThanOrEqualTo(pair.min),
              reason: 'Generator should only produce valid pairs',
            );

            final result = validateModifierGroup(
              minSelect: pair.min,
              maxSelect: pair.max,
            );

            expect(
              result,
              isNull,
              reason: 'Expected no error for '
                  'min=${pair.min}, max=${pair.max}',
            );
          },
          iterations: 100,
        );
      },
    );

    // ── Boundary: max == min is valid ─────────────────────────────────────

    test('max_select == min_select is valid (boundary check)', () {
      for (var n = 0; n <= 20; n++) {
        expect(
          validateModifierGroup(minSelect: n, maxSelect: n.clamp(1, 20)),
          isNull,
          reason: 'min==max should be valid at n=$n',
        );
      }
    });

    // ── Boundary: max = min - 1 is always invalid ─────────────────────────

    test('max_select == min_select - 1 is always invalid (boundary check)', () {
      for (var min = 1; min <= 20; min++) {
        expect(
          validateModifierGroup(minSelect: min, maxSelect: min - 1),
          isNotNull,
          reason: 'max=min-1 should be invalid at min=$min',
        );
      }
    });
  });
}
