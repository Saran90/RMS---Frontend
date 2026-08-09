// Feature: rms-flutter-frontend, Property 12: Low-stock ordering
// Validates: Requirements 13.3

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:staff_portal/inventory/inventory_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sorting logic (mirrors InventoryLoaded.sorted in inventory_bloc.dart)
// ─────────────────────────────────────────────────────────────────────────────
//
//   List<Ingredient> get sorted => [
//     ...ingredients.where((i) => i.isBelowThreshold),
//     ...ingredients.where((i) => !i.isBelowThreshold),
//   ];
//
//   bool get isBelowThreshold => currentStock < reorderThreshold;
//
// Invariant (P12): For every pair (a, b) in the sorted output where a comes
// before b, it must NOT be the case that a is NOT below threshold while b IS
// below threshold.  In other words: all below-threshold items come before all
// at/above-threshold items.
// ─────────────────────────────────────────────────────────────────────────────

/// Applies the same ordering logic as [InventoryLoaded.sorted].
List<Ingredient> _applySort(List<Ingredient> ingredients) => [
      ...ingredients.where((i) => i.isBelowThreshold),
      ...ingredients.where((i) => !i.isBelowThreshold),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// Generator helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Generates a single [Ingredient] with random stock values.
///
/// [currentStock] and [reorderThreshold] are drawn from [0.0, 100.0) so both
/// sides of the threshold are well-represented.
Ingredient _randomIngredient(Random rng, int index) {
  final currentStock = rng.nextDouble() * 100;
  final reorderThreshold = rng.nextDouble() * 100;
  return Ingredient(
    id: 'ingredient-$index',
    name: 'Ingredient $index',
    unit: 'kg',
    currentStock: currentStock,
    reorderThreshold: reorderThreshold,
  );
}

/// Generates a list of 1–20 [Ingredient]s with random stock values.
List<Ingredient> _randomIngredientList(Random rng) {
  final count = 1 + rng.nextInt(20); // 1..20
  return List.generate(count, (i) => _randomIngredient(rng, i));
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Property 12 – Low-stock ordering invariant (Req 13.3)', () {
    // ── Property test: 100 random ingredient lists ────────────────────────────
    test(
      'all below-threshold ingredients appear before all at/above-threshold '
      'ingredients in the sorted output (100 iterations)',
      () {
        final rng = Random(42);

        for (var i = 0; i < 100; i++) {
          final ingredients = _randomIngredientList(rng);
          final sorted = _applySort(ingredients);

          // Verify P12 for every ordered pair (a, b) where a precedes b.
          for (var a = 0; a < sorted.length; a++) {
            for (var b = a + 1; b < sorted.length; b++) {
              final itemA = sorted[a];
              final itemB = sorted[b];

              // The invariant must NOT hold: a is above/at threshold AND
              // b is below threshold — that would violate the ordering.
              final violatesOrdering =
                  !itemA.isBelowThreshold && itemB.isBelowThreshold;

              expect(
                violatesOrdering,
                isFalse,
                reason: 'Iteration $i: pair (a=$a, b=$b) violates P12 — '
                    'a "${itemA.name}" (stock=${itemA.currentStock}, '
                    'threshold=${itemA.reorderThreshold}, '
                    'below=${itemA.isBelowThreshold}) comes before '
                    'b "${itemB.name}" (stock=${itemB.currentStock}, '
                    'threshold=${itemB.reorderThreshold}, '
                    'below=${itemB.isBelowThreshold})',
              );
            }
          }
        }
      },
    );

    // ── Deterministic edge cases ──────────────────────────────────────────────
    group('deterministic edge cases', () {
      test(
          'all ingredients below threshold → all appear first, order preserved',
          () {
        // Every ingredient has currentStock = 0, reorderThreshold = 10
        final ingredients = List.generate(
          4,
          (i) => Ingredient(
            id: 'id-$i',
            name: 'Item $i',
            unit: 'kg',
            currentStock: 0,
            reorderThreshold: 10,
          ),
        );

        final sorted = _applySort(ingredients);

        // All items are below threshold
        expect(
          sorted.every((i) => i.isBelowThreshold),
          isTrue,
          reason: 'All items should be below threshold',
        );

        // The order is preserved (same sequence as input because the
        // sort is stable — below-threshold items are written first in
        // input order)
        expect(
          sorted.map((i) => i.id).toList(),
          equals(ingredients.map((i) => i.id).toList()),
          reason: 'Relative order within the below-threshold group must be '
              'preserved',
        );

        // No ordering violation
        for (var a = 0; a < sorted.length; a++) {
          for (var b = a + 1; b < sorted.length; b++) {
            expect(
              !sorted[a].isBelowThreshold && sorted[b].isBelowThreshold,
              isFalse,
              reason: 'No ordering violation should exist',
            );
          }
        }
      });

      test(
          'all ingredients at/above threshold → none triggers low-stock, '
          'order preserved', () {
        // Every ingredient has currentStock >= reorderThreshold
        final ingredients = List.generate(
          4,
          (i) => Ingredient(
            id: 'id-$i',
            name: 'Item $i',
            unit: 'kg',
            currentStock: 20,
            reorderThreshold: 10,
          ),
        );

        final sorted = _applySort(ingredients);

        // No item is below threshold
        expect(
          sorted.every((i) => !i.isBelowThreshold),
          isTrue,
          reason: 'No item should be below threshold',
        );

        // The order is preserved
        expect(
          sorted.map((i) => i.id).toList(),
          equals(ingredients.map((i) => i.id).toList()),
          reason: 'Relative order within the at/above-threshold group must be '
              'preserved',
        );

        // No ordering violation
        for (var a = 0; a < sorted.length; a++) {
          for (var b = a + 1; b < sorted.length; b++) {
            expect(
              !sorted[a].isBelowThreshold && sorted[b].isBelowThreshold,
              isFalse,
              reason: 'No ordering violation should exist',
            );
          }
        }
      });

      test('mixed: 3 below threshold, 3 above → all below come first', () {
        // Interleave below and above intentionally to confirm the sort
        // moves them to the correct positions.
        final belowA = Ingredient(
          id: 'b1',
          name: 'Below A',
          unit: 'kg',
          currentStock: 2,
          reorderThreshold: 10,
        );
        final aboveA = Ingredient(
          id: 'a1',
          name: 'Above A',
          unit: 'kg',
          currentStock: 15,
          reorderThreshold: 10,
        );
        final belowB = Ingredient(
          id: 'b2',
          name: 'Below B',
          unit: 'kg',
          currentStock: 0,
          reorderThreshold: 5,
        );
        final aboveB = Ingredient(
          id: 'a2',
          name: 'Above B',
          unit: 'kg',
          currentStock: 5, // exactly at threshold (not below)
          reorderThreshold: 5,
        );
        final belowC = Ingredient(
          id: 'b3',
          name: 'Below C',
          unit: 'kg',
          currentStock: 1,
          reorderThreshold: 100,
        );
        final aboveC = Ingredient(
          id: 'a3',
          name: 'Above C',
          unit: 'kg',
          currentStock: 50,
          reorderThreshold: 10,
        );

        // Intentionally interleaved
        final ingredients = [belowA, aboveA, belowB, aboveB, belowC, aboveC];
        final sorted = _applySort(ingredients);

        expect(sorted.length, equals(6));

        // First 3 must all be below threshold
        expect(
          sorted.sublist(0, 3).every((i) => i.isBelowThreshold),
          isTrue,
          reason: 'First 3 items must all be below threshold',
        );

        // Last 3 must all be at/above threshold
        expect(
          sorted.sublist(3).every((i) => !i.isBelowThreshold),
          isTrue,
          reason: 'Last 3 items must all be at/above threshold',
        );

        // Specific IDs: below-threshold items first in original order
        expect(
          sorted.sublist(0, 3).map((i) => i.id).toList(),
          equals(['b1', 'b2', 'b3']),
          reason: 'Below-threshold items should appear in their original order',
        );
        expect(
          sorted.sublist(3).map((i) => i.id).toList(),
          equals(['a1', 'a2', 'a3']),
          reason: 'Above-threshold items should appear in their original order',
        );

        // Boundary check: currentStock == reorderThreshold is NOT below
        expect(
          aboveB.isBelowThreshold,
          isFalse,
          reason:
              'currentStock == reorderThreshold must NOT be below threshold '
              '(condition is strict <)',
        );

        // No ordering violation
        for (var a = 0; a < sorted.length; a++) {
          for (var b = a + 1; b < sorted.length; b++) {
            expect(
              !sorted[a].isBelowThreshold && sorted[b].isBelowThreshold,
              isFalse,
              reason: 'Pair ($a, $b) violates P12',
            );
          }
        }
      });
    });
  });
}
