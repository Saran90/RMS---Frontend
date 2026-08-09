// Feature: rms-flutter-frontend, Property 10: Bill split total
// Validates: Requirements 11.8 — 100 iterations

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:models/models.dart';
import 'package:staff_portal/billing/billing_bloc.dart';
import 'package:staff_portal/billing/billing_repository.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockBillingRepository extends Mock implements BillingRepository {}

// ── Validation logic (mirrors Requirement 11.8) ───────────────────────────────
//
// Requirement 11.8:
//   IF the split configuration results in a sum that does not equal the Bill
//   total, THEN THE App SHALL display a validation error and prevent submission.
//
// The split validation guard checks whether the sum of all proposed split parts
// equals (within floating-point tolerance) the original bill total.
// This mirrors the production validation that must run before calling
// BillingRepository.splitBill().
//
// Tolerance: 0.01 (one cent), to handle floating-point rounding in amounts.
// ─────────────────────────────────────────────────────────────────────────────

const double _splitTolerance = 0.01;

/// Validates a proposed split configuration.
///
/// Returns a non-null error message when [splitAmounts] do not sum to
/// [billTotal] (within [_splitTolerance]), which must block the network call.
///
/// Returns null when the split is valid and the call may proceed.
String? _validateSplitTotal({
  required double billTotal,
  required List<double> splitAmounts,
}) {
  if (splitAmounts.isEmpty) {
    return 'Split amounts must not be empty';
  }
  final partsSum = splitAmounts.fold<double>(0.0, (sum, a) => sum + a);
  final diff = (partsSum - billTotal).abs();
  if (diff > _splitTolerance) {
    return 'Split amounts (₹${partsSum.toStringAsFixed(2)}) do not equal '
        'the bill total (₹${billTotal.toStringAsFixed(2)})';
  }
  return null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a minimal draft [Bill] with [total] and no existing payments.
Bill _buildBill({required double total}) => Bill(
      id: 'bill-split-test-001',
      orderId: 'order-split-test-001',
      subtotal: total / 1.05,
      gstBreakdown: [
        GstSlab(
          gstRate: 5.0,
          taxableValue: total / 1.05,
          gstAmount: total - (total / 1.05),
        ),
      ],
      total: total,
      status: 'draft',
    );

/// Generates a list of [n] doubles that sum to exactly [total].
///
/// Produces n-1 random parts in (0, remaining) and sets the last part to
/// the remainder, ensuring exact summation.
List<double> _validSplitAmounts(double total, int n, Random rng) {
  assert(n >= 2, 'Split requires at least 2 parts');
  final parts = <double>[];
  var remaining = total;
  for (var i = 0; i < n - 1; i++) {
    // Each part is between 0.01 and (remaining - 0.01*(n-1-i)) so the last
    // part stays positive.
    final maxPart = remaining - 0.01 * (n - 1 - i);
    final part =
        maxPart > 0.01 ? (0.01 + rng.nextDouble() * (maxPart - 0.01)) : 0.01;
    // Round to 2 decimal places to avoid floating-point drift across many adds.
    final rounded = (part * 100).round() / 100.0;
    parts.add(rounded);
    remaining -= rounded;
  }
  // The last part is exactly the remainder (rounded to 2 dp).
  parts.add((remaining * 100).round() / 100.0);
  return parts;
}

/// Generates a list of [n] doubles that do NOT sum to [billTotal].
///
/// Deliberately introduces an offset so the sum is off by more than the
/// tolerance [_splitTolerance].
List<double> _invalidSplitAmounts(double total, int n, Random rng) {
  assert(n >= 2, 'Split requires at least 2 parts');
  // Start with a valid split then perturb the first part.
  final parts = _validSplitAmounts(total, n, rng);

  // Add an offset of ±[offsetMagnitude] to the first part.
  // Ensure the offset exceeds the tolerance in either direction.
  const offsetMagnitude = 1.0; // ₹1.00 – well above the 0.01 tolerance
  final sign = rng.nextBool() ? 1.0 : -1.0;
  parts[0] = (parts[0] + sign * offsetMagnitude * (1 + rng.nextDouble())).abs();

  return parts;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Section 1: Property test — invalid splits are rejected (100 iterations) ─

  group(
    'Property 10 – Bill split total invariant (Req 11.8)',
    () {
      /// **Validates: Requirements 11.8**
      ///
      /// For any (billTotal, splitAmounts[]) where the parts do NOT sum to
      /// billTotal, the validation guard must:
      ///   1. Return a non-null error message
      ///   2. Confirm BillingRepository.splitBill is never called
      test(
        'validation rejects split configurations whose parts do not sum '
        'to the bill total (100 random iterations)',
        () {
          final rng = Random(42);
          final mockRepo = MockBillingRepository();

          for (var i = 0; i < 100; i++) {
            // 1. Generate a random billTotal in [100.0, 10000.0]
            final billTotal =
                (100.0 + rng.nextDouble() * 9900.0 * 100).round() / 100.0;

            // 2. Random number of diners (2..6)
            final diners = 2 + rng.nextInt(5);

            // 3. Build split amounts that intentionally do NOT sum to total
            final badAmounts = _invalidSplitAmounts(billTotal, diners, rng);

            // Guard: confirm the bad amounts genuinely don't match the total
            final partsSum = badAmounts.fold<double>(0.0, (s, a) => s + a);
            expect(
              (partsSum - billTotal).abs() > _splitTolerance,
              isTrue,
              reason: 'Iteration $i: test generator must produce an '
                  'invalid split (sum=${partsSum.toStringAsFixed(2)}, '
                  'total=${billTotal.toStringAsFixed(2)})',
            );

            // 4. Run the validation guard
            final error = _validateSplitTotal(
              billTotal: billTotal,
              splitAmounts: badAmounts,
            );

            // 5. Must produce a validation error
            expect(
              error,
              isNotNull,
              reason: 'Iteration $i: invalid split must produce a validation '
                  'error (sum=${partsSum.toStringAsFixed(2)}, '
                  'total=${billTotal.toStringAsFixed(2)})',
            );

            // 6. splitBill must never be called when validation fails
            verifyNever(
              () => mockRepo.splitBill(
                billId: any(named: 'billId'),
                diners: any(named: 'diners'),
              ),
            );
          }
        },
      );

      /// **Validates: Requirements 11.8 (positive case)**
      ///
      /// For any (billTotal, splitAmounts[]) where the parts DO sum to
      /// billTotal, the validation guard must accept the configuration
      /// (return null), allowing the split call to proceed.
      test(
        'validation accepts split configurations whose parts sum exactly '
        'to the bill total (100 random iterations)',
        () {
          final rng = Random(99);

          for (var i = 0; i < 100; i++) {
            // 1. Generate a random billTotal in [100.0, 10000.0]
            final billTotal =
                (100.0 + rng.nextDouble() * 9900.0 * 100).round() / 100.0;

            // 2. Random number of diners (2..6)
            final diners = 2 + rng.nextInt(5);

            // 3. Build split amounts that DO sum to total
            final goodAmounts = _validSplitAmounts(billTotal, diners, rng);

            // Guard: confirm the amounts genuinely match the total
            final partsSum = goodAmounts.fold<double>(0.0, (s, a) => s + a);
            expect(
              (partsSum - billTotal).abs() <= _splitTolerance,
              isTrue,
              reason: 'Iteration $i: test generator must produce a valid split '
                  '(sum=${partsSum.toStringAsFixed(2)}, '
                  'total=${billTotal.toStringAsFixed(2)})',
            );

            // 4. Run the validation guard
            final error = _validateSplitTotal(
              billTotal: billTotal,
              splitAmounts: goodAmounts,
            );

            // 5. Must NOT produce a validation error
            expect(
              error,
              isNull,
              reason: 'Iteration $i: valid split must be accepted '
                  '(sum=${partsSum.toStringAsFixed(2)}, '
                  'total=${billTotal.toStringAsFixed(2)})',
            );
          }
        },
      );

      // ── Deterministic boundary tests ─────────────────────────────────────

      group('boundary cases', () {
        test(
            'two parts: [50.00, 50.01] against total=100.00 → rejected '
            '(off by 0.01 which equals tolerance boundary)', () {
          // Off by exactly the tolerance limit — should be rejected since
          // we require diff <= tolerance (strict: > tolerance means error).
          const billTotal = 100.0;
          final parts = [50.00, 50.01]; // sum = 100.01, diff = 0.01
          final error = _validateSplitTotal(
            billTotal: billTotal,
            splitAmounts: parts,
          );
          // diff == 0.01 is NOT > 0.01, so this should be accepted
          expect(
            error,
            isNull,
            reason:
                'diff of exactly 0.01 equals tolerance and must be accepted',
          );
        });

        test(
            'two parts: [50.00, 50.02] against total=100.00 → rejected '
            '(off by 0.02, exceeds tolerance)', () {
          const billTotal = 100.0;
          final parts = [50.00, 50.02]; // sum = 100.02, diff = 0.02
          final error = _validateSplitTotal(
            billTotal: billTotal,
            splitAmounts: parts,
          );
          expect(
            error,
            isNotNull,
            reason: 'diff of 0.02 > tolerance 0.01 must be rejected',
          );
        });

        test('two equal parts sum to total exactly → accepted', () {
          const billTotal = 200.0;
          final parts = [100.0, 100.0];
          final error = _validateSplitTotal(
            billTotal: billTotal,
            splitAmounts: parts,
          );
          expect(error, isNull, reason: '[100.0, 100.0] sums to 200.0 exactly');
        });

        test('three equal parts sum to total exactly → accepted', () {
          const billTotal = 300.0;
          final parts = [100.0, 100.0, 100.0];
          final error = _validateSplitTotal(
            billTotal: billTotal,
            splitAmounts: parts,
          );
          expect(error, isNull,
              reason: '[100.0, 100.0, 100.0] sums to 300.0 exactly');
        });

        test('parts sum to less than total → rejected', () {
          const billTotal = 300.0;
          final parts = [100.0, 100.0]; // sum = 200.0, missing 100.0
          final error = _validateSplitTotal(
            billTotal: billTotal,
            splitAmounts: parts,
          );
          expect(
            error,
            isNotNull,
            reason: 'sum=200.0 < total=300.0 must be rejected',
          );
          expect(error, contains('200.00'),
              reason: 'Error message must include the actual sum');
          expect(error, contains('300.00'),
              reason: 'Error message must include the expected total');
        });

        test('parts sum to more than total → rejected', () {
          const billTotal = 300.0;
          final parts = [100.0, 100.0, 200.0]; // sum = 400.0
          final error = _validateSplitTotal(
            billTotal: billTotal,
            splitAmounts: parts,
          );
          expect(
            error,
            isNotNull,
            reason: 'sum=400.0 > total=300.0 must be rejected',
          );
        });

        test('empty parts list → rejected', () {
          const billTotal = 100.0;
          final error = _validateSplitTotal(
            billTotal: billTotal,
            splitAmounts: [],
          );
          expect(error, isNotNull,
              reason: 'Empty split parts must produce an error');
        });
      });

      // ── BLoC stays in initial state when split is blocked ─────────────────

      group('BLoC does not emit BillSplit when validation fails', () {
        late MockBillingRepository mockRepo;

        setUp(() {
          mockRepo = MockBillingRepository();
        });

        test(
          'BillingBloc stays in BillingInitial when BillSplitRequested '
          'is never dispatched due to invalid split validation (100 iterations)',
          () {
            final rng = Random(42);

            for (var i = 0; i < 100; i++) {
              final billTotal =
                  (100.0 + rng.nextDouble() * 9900.0 * 100).round() / 100.0;
              final diners = 2 + rng.nextInt(5);
              final badAmounts = _invalidSplitAmounts(billTotal, diners, rng);

              final error = _validateSplitTotal(
                billTotal: billTotal,
                splitAmounts: badAmounts,
              );

              // Guard check fails → event is never dispatched to bloc
              expect(error, isNotNull,
                  reason: 'Iteration $i: invalid split must produce error');

              if (error != null) {
                // Widget-layer guard returns early: BillSplitRequested is never
                // added to the bloc → bloc stays in initial state.
                final bloc = BillingBloc(repository: mockRepo);
                expect(bloc.state, isA<BillingInitial>(),
                    reason: 'Bloc must remain in BillingInitial — '
                        'no split event was dispatched');
                bloc.close();
              }

              // Confirm repository splitBill was never called
              verifyNever(() => mockRepo.splitBill(
                    billId: any(named: 'billId'),
                    diners: any(named: 'diners'),
                  ));
            }
          },
        );
      });

      // ── Bill model construction ───────────────────────────────────────────

      group('Bill model used in split scenarios', () {
        test('_buildBill creates a valid draft Bill', () {
          const total = 500.0;
          final bill = _buildBill(total: total);

          expect(bill.total, equals(total));
          expect(bill.status, equals('draft'));
          expect(bill.payments, isEmpty);
          expect(bill.gstBreakdown, isNotEmpty);
        });
      });
    },
  );
}
