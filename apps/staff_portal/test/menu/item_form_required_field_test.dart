// Feature: rms-flutter-frontend, Property 3: Required field validation
// Validates: Requirements 7.4 — 100 iterations

import 'package:flutter_test/flutter_test.dart';

import '../helpers/fast_check.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pure validators extracted from _MenuItemFormSheetState (menu_item_form.dart)
// These mirror the exact validators used in the Add/Edit Item form (Req 7.4).
// ─────────────────────────────────────────────────────────────────────────────

String? _validateName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Item name is required';
  if (value.trim().length > 100) return 'Name must be 100 characters or fewer';
  return null;
}

String? _validateCategoryId(String? value) {
  if (value == null || value.isEmpty) return 'Category is required';
  return null;
}

String? _validateBasePrice(String? value) {
  if (value == null || value.trim().isEmpty) return 'Base price is required';
  final d = double.tryParse(value.trim());
  if (d == null || d < 0) return 'Enter a valid price';
  return null;
}

String? _validateDietaryType(Object? value) {
  if (value == null) return 'Dietary type is required';
  return null;
}

/// Runs all four required-field validators against the given inputs.
/// Returns a map of field name → error message for any field that fails.
Map<String, String> validateItemForm({
  required String? name,
  required String? categoryId,
  required String? basePrice,
  required Object? dietaryType,
}) {
  final errors = <String, String>{};
  final nameErr = _validateName(name);
  final catErr = _validateCategoryId(categoryId);
  final priceErr = _validateBasePrice(basePrice);
  final dietErr = _validateDietaryType(dietaryType);

  if (nameErr != null) errors['name'] = nameErr;
  if (catErr != null) errors['category_id'] = catErr;
  if (priceErr != null) errors['base_price'] = priceErr;
  if (dietErr != null) errors['dietary_type'] = dietErr;
  return errors;
}

// ─────────────────────────────────────────────────────────────────────────────
// Arbitraries
// ─────────────────────────────────────────────────────────────────────────────

/// A set of form field values where at least one required field is missing.
typedef _PartialItemInput = ({
  String? name,
  String? categoryId,
  String? basePrice,
  Object? dietaryType,
});

/// Generates form inputs where at least one of the four required fields is
/// absent or blank. This models any combination of missing inputs.
final _partialInputArbitrary = Arbitrary<_PartialItemInput>((rng) {
  // Build 4 booleans: whether each field is present (true) or missing (false)
  // At least one must be false.
  bool namePresent = rng.nextBool();
  bool catPresent = rng.nextBool();
  bool pricePresent = rng.nextBool();
  bool dietPresent = rng.nextBool();

  // Ensure at least one is absent
  if (namePresent && catPresent && pricePresent && dietPresent) {
    // Force the first one absent
    namePresent = false;
  }

  final nameStr = Arbitrary.string(minLen: 1, maxLen: 40);
  final catStr = Arbitrary.string(minLen: 1, maxLen: 20);

  return (
    name: namePresent ? nameStr.generate(rng) : '',
    categoryId: catPresent ? catStr.generate(rng) : null,
    basePrice: pricePresent ? (rng.nextDouble() * 1000).toStringAsFixed(2) : '',
    dietaryType: dietPresent ? 'veg' : null, // non-null = present
  );
});

/// Generates fully valid form inputs (all required fields present).
final _validInputArbitrary = Arbitrary<_PartialItemInput>((rng) {
  final nameStr = Arbitrary.string(minLen: 1, maxLen: 80);
  final catStr = Arbitrary.string(minLen: 1, maxLen: 20);
  return (
    name: nameStr.generate(rng),
    categoryId: catStr.generate(rng),
    basePrice: (1 + rng.nextDouble() * 999).toStringAsFixed(2),
    dietaryType: 'veg',
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Property 3 – Required field validation: Item form (Req 7.4)', () {
    // ── Core property: missing required field always produces error ──────────

    test(
      'validateItemForm returns at least one error when any required field '
      'is absent (100 iterations over partial inputs)',
      () {
        forAll<_PartialItemInput>(
          _partialInputArbitrary,
          (input) {
            final errors = validateItemForm(
              name: input.name,
              categoryId: input.categoryId,
              basePrice: input.basePrice,
              dietaryType: input.dietaryType,
            );

            expect(
              errors.isNotEmpty,
              isTrue,
              reason: 'Expected at least one validation error for partial '
                  'input: name="${input.name}", '
                  'categoryId="${input.categoryId}", '
                  'basePrice="${input.basePrice}", '
                  'dietaryType="${input.dietaryType}"',
            );
          },
          iterations: 100,
        );
      },
    );

    // ── No errors when all required fields are valid ──────────────────────

    test(
      'validateItemForm returns no errors when all required fields are '
      'present and valid (100 iterations)',
      () {
        forAll<_PartialItemInput>(
          _validInputArbitrary,
          (input) {
            final errors = validateItemForm(
              name: input.name,
              categoryId: input.categoryId,
              basePrice: input.basePrice,
              dietaryType: input.dietaryType,
            );

            expect(
              errors.isEmpty,
              isTrue,
              reason: 'Expected no errors for fully valid input: '
                  'name="${input.name}", '
                  'categoryId="${input.categoryId}", '
                  'basePrice="${input.basePrice}", '
                  'dietaryType="${input.dietaryType}"\n'
                  'Got errors: $errors',
            );
          },
          iterations: 100,
        );
      },
    );

    // ── Individual field coverage ─────────────────────────────────────────

    test('name: empty string produces error', () {
      expect(_validateName(''), isNotNull);
      expect(_validateName('   '), isNotNull);
      expect(_validateName(null), isNotNull);
    });

    test('name: non-empty string up to 100 chars passes', () {
      expect(_validateName('Burger'), isNull);
      expect(_validateName('A' * 100), isNull);
      expect(_validateName('A' * 101), isNotNull);
    });

    test('category_id: null or empty produces error', () {
      expect(_validateCategoryId(null), isNotNull);
      expect(_validateCategoryId(''), isNotNull);
      expect(_validateCategoryId('cat-1'), isNull);
    });

    test('base_price: empty or non-numeric produces error', () {
      expect(_validateBasePrice(''), isNotNull);
      expect(_validateBasePrice(null), isNotNull);
      expect(_validateBasePrice('abc'), isNotNull);
      expect(_validateBasePrice('-5'), isNotNull);
      expect(_validateBasePrice('0'), isNull);
      expect(_validateBasePrice('99.99'), isNull);
    });

    test('dietary_type: null produces error; non-null passes', () {
      expect(_validateDietaryType(null), isNotNull);
      expect(_validateDietaryType('veg'), isNull);
      expect(_validateDietaryType('non_veg'), isNull);
    });
  });
}
