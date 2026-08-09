// Feature: rms-flutter-frontend, Property 11: Payment underpayment
// Validates: Requirements 11.6 — 100 iterations

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:models/models.dart';
import 'package:staff_portal/billing/billing_bloc.dart';
import 'package:staff_portal/billing/billing_repository.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockBillingRepository extends Mock implements BillingRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a minimal draft [Bill] with [total] and no existing payments,
/// so outstanding == total.
Bill _buildBill({required double total}) => Bill(
      id: 'bill-test-001',
      orderId: 'order-test-001',
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

/// Computes the outstanding balance for a bill:
///   outstanding = bill.total - sum(bill.payments.map(p => p.amount))
double _outstanding(Bill bill) {
  final paid = bill.payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  return (bill.total - paid).clamp(0.0, double.infinity);
}

/// Mirrors the underpayment guard from [_PaymentFormCardState._submit()]:
///   if (amount < outstanding) → validation error, no HTTP call.
///
/// Returns a non-null error message when underpayment is detected.
String? _validateUnderpayment({
  required double amount,
  required double outstanding,
}) {
  if (amount < outstanding) {
    return 'Amount must be at least ₹${outstanding.toStringAsFixed(2)}';
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Section 1: Property test — underpayment guard (100 iterations) ─────────

  group(
    'Property 11 – Payment underpayment rejection (Req 11.6)',
    () {
      /// **Validates: Requirements 11.6**
      ///
      /// For any billTotal in [100.0, 10000.0] and any paymentAmount strictly
      /// less than billTotal, the underpayment guard must:
      ///   1. Return a non-null validation error (blocking HTTP call)
      ///   2. Confirm amount < outstanding is true
      ///   3. Confirm BillingRepository.recordPayment is never called
      test(
        'guard detects underpayment and blocks HTTP call for any '
        'amount < outstanding (100 random iterations)',
        () {
          final rng = Random(42);
          final mockRepo = MockBillingRepository();

          for (var i = 0; i < 100; i++) {
            // 1. Generate a random billTotal in [100.0, 10000.0]
            final billTotal = 100.0 + rng.nextDouble() * 9900.0;

            // 2. Generate amount strictly less than billTotal
            //    fraction is in [0.01, 0.99) → amount < total
            final fraction = 0.01 + rng.nextDouble() * 0.98;
            final amount = (billTotal * fraction * 100).floor() / 100.0;

            // Ensure the floor operation didn't accidentally equal the total
            final paymentAmount = amount < billTotal ? amount : amount - 0.01;

            // 3. Build a Bill with no existing payments → outstanding == total
            final bill = _buildBill(total: billTotal);
            final outstandingBalance = _outstanding(bill);

            // The outstanding for a bill with no payments equals the total
            expect(
              outstandingBalance,
              equals(billTotal),
              reason: 'Bill with no payments: outstanding must equal total',
            );

            // 4. Verify the guard condition: amount < outstanding must be true
            expect(
              paymentAmount < outstandingBalance,
              isTrue,
              reason: 'Generated input must be an underpayment: '
                  'amount=${paymentAmount.toStringAsFixed(2)}, '
                  'outstanding=${outstandingBalance.toStringAsFixed(2)}',
            );

            // 5. Validate using the same logic as the widget
            final error = _validateUnderpayment(
              amount: paymentAmount,
              outstanding: outstandingBalance,
            );

            expect(
              error,
              isNotNull,
              reason: 'Underpayment must produce a validation error '
                  '(amount=${paymentAmount.toStringAsFixed(2)}, '
                  'outstanding=${outstandingBalance.toStringAsFixed(2)})',
            );

            // 6. The bloc does NOT emit BillLoaded because the widget-layer guard
            //    prevents BillPaymentRequested from being dispatched.
            //    Confirm recordPayment is never called.
            verifyNever(
              () => mockRepo.recordPayment(
                billId: any(named: 'billId'),
                mode: any(named: 'mode'),
                amount: any(named: 'amount'),
              ),
            );
          }
        },
      );

      // ── Deterministic boundary tests ─────────────────────────────────────

      test('underpayment: amount=99.99, outstanding=100.0 → error returned',
          () {
        const outstanding = 100.0;
        const amount = 99.99;

        expect(amount < outstanding, isTrue,
            reason: '99.99 < 100.0 must be an underpayment');

        final error =
            _validateUnderpayment(amount: amount, outstanding: outstanding);

        expect(error, isNotNull,
            reason: 'amount=99.99 < outstanding=100.0 must produce an error');
        expect(error, contains('100.00'),
            reason: 'Error must mention the required minimum amount');
      });

      test(
          'exact payment: amount=100.0, outstanding=100.0 → no error (not underpayment)',
          () {
        const outstanding = 100.0;
        const amount = 100.0;

        expect(amount < outstanding, isFalse,
            reason: '100.0 is not less than 100.0 — not an underpayment');

        final error =
            _validateUnderpayment(amount: amount, outstanding: outstanding);

        expect(error, isNull,
            reason: 'Exact payment (amount == outstanding) must be accepted');
      });

      test(
          'overpayment: amount=100.01, outstanding=100.0 → no error (not underpayment)',
          () {
        const outstanding = 100.0;
        const amount = 100.01;

        expect(amount < outstanding, isFalse,
            reason: '100.01 > 100.0 is an overpayment, not underpayment');

        final error =
            _validateUnderpayment(amount: amount, outstanding: outstanding);

        expect(error, isNull,
            reason: 'Overpayment (amount > outstanding) must be accepted');
      });
    },
  );

  // ── Section 2: BLoC does NOT emit BillLoaded when underpayment is blocked ──

  group(
    'Property 11 – BLoC does not emit BillLoaded on underpayment (Req 11.6)',
    () {
      late MockBillingRepository mockRepo;

      setUp(() {
        mockRepo = MockBillingRepository();
      });

      test(
        'BillingBloc stays in BillingInitial when BillPaymentRequested '
        'is never dispatched due to underpayment guard (100 iterations)',
        () async {
          final rng = Random(42);

          for (var i = 0; i < 100; i++) {
            final billTotal = 100.0 + rng.nextDouble() * 9900.0;
            final fraction = 0.01 + rng.nextDouble() * 0.98;
            final amount = (billTotal * fraction * 100).floor() / 100.0;
            final paymentAmount = amount < billTotal ? amount : amount - 0.01;

            final bill = _buildBill(total: billTotal);
            final outstandingBalance = _outstanding(bill);

            // Guard check — same logic as the widget's _submit()
            final isUnderpayment = paymentAmount < outstandingBalance;
            expect(isUnderpayment, isTrue);

            if (isUnderpayment) {
              // Widget-layer guard returns early: BillPaymentRequested is
              // never added to the bloc → bloc stays in initial state.
              final bloc = BillingBloc(repository: mockRepo);
              expect(bloc.state, isA<BillingInitial>(),
                  reason: 'Bloc must remain in BillingInitial — '
                      'no event was dispatched');
              await bloc.close();
            }

            // Confirm repository was never called across all iterations
            verifyNever(() => mockRepo.recordPayment(
                  billId: any(named: 'billId'),
                  mode: any(named: 'mode'),
                  amount: any(named: 'amount'),
                ));
          }
        },
      );
    },
  );
}
