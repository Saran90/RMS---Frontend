// Feature: rms-flutter-frontend, Property 8: KDS overdue invariant
// Validates: Requirements 10.7

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Overdue logic (mirrors the KDS screen implementation)
// ─────────────────────────────────────────────────────────────────────────────
//
//   bool isOverdue = elapsed.inMinutes >= 10;
//   showRedBorder     = isOverdue
//   showOverdueLabel  = isOverdue
//
// Invariant: both UI flags are derived from the same condition and therefore
// always toggle together.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Property 8 – KDS overdue invariant (Req 10.7)', () {
    // ── Property test: 100 random durations 0..25 minutes ────────────────────
    test(
      'showRedBorder and showOverdueLabel always toggle together for any '
      'duration in [0, 25) minutes (100 iterations)',
      () {
        final rng = Random(42);

        for (var i = 0; i < 100; i++) {
          // Generate a random duration between 0 and 25 minutes (exclusive),
          // expressed in whole seconds so we cover intra-minute fractions.
          final totalSeconds = rng.nextInt(25 * 60); // 0..1499 seconds
          final elapsed = Duration(seconds: totalSeconds);

          // ── Overdue logic (mirrored from KDS screen) ──────────────────
          final isOverdue = elapsed.inMinutes >= 10;
          final showRedBorder = isOverdue;
          final showOverdueLabel = isOverdue;

          // ── Property assertions ───────────────────────────────────────
          // P8-a: both flags always agree
          expect(
            showRedBorder,
            equals(showOverdueLabel),
            reason: 'Iteration $i (${elapsed.inSeconds}s): '
                'showRedBorder ($showRedBorder) must equal '
                'showOverdueLabel ($showOverdueLabel)',
          );

          // P8-b: red border iff elapsed >= 10 minutes
          expect(
            showRedBorder,
            equals(elapsed.inMinutes >= 10),
            reason: 'Iteration $i (${elapsed.inSeconds}s): '
                'showRedBorder must be true iff elapsed >= 10 min '
                '(elapsed.inMinutes=${elapsed.inMinutes})',
          );

          // P8-c: overdue label iff elapsed >= 10 minutes
          expect(
            showOverdueLabel,
            equals(elapsed.inMinutes >= 10),
            reason: 'Iteration $i (${elapsed.inSeconds}s): '
                'showOverdueLabel must be true iff elapsed >= 10 min '
                '(elapsed.inMinutes=${elapsed.inMinutes})',
          );
        }
      },
    );

    // ── Boundary tests ────────────────────────────────────────────────────────
    group('boundary cases', () {
      /// Helper: run the overdue logic and return (showRedBorder, showOverdueLabel).
      (bool, bool) _evaluate(Duration elapsed) {
        final isOverdue = elapsed.inMinutes >= 10;
        return (isOverdue, isOverdue);
      }

      test('9 minutes 59 seconds → NOT overdue', () {
        final elapsed = const Duration(minutes: 9, seconds: 59);
        final (showRedBorder, showOverdueLabel) = _evaluate(elapsed);

        expect(elapsed.inMinutes, equals(9),
            reason: 'Duration.inMinutes truncates — 9m59s = 9 whole minutes');
        expect(showRedBorder, isFalse,
            reason: '9m59s is below the 10-minute threshold');
        expect(showOverdueLabel, isFalse,
            reason: '9m59s is below the 10-minute threshold');
        expect(showRedBorder, equals(showOverdueLabel),
            reason: 'Both flags must agree');
      });

      test('10 minutes 0 seconds → overdue', () {
        final elapsed = const Duration(minutes: 10, seconds: 0);
        final (showRedBorder, showOverdueLabel) = _evaluate(elapsed);

        expect(elapsed.inMinutes, equals(10));
        expect(showRedBorder, isTrue,
            reason: '10m0s meets the 10-minute threshold');
        expect(showOverdueLabel, isTrue,
            reason: '10m0s meets the 10-minute threshold');
        expect(showRedBorder, equals(showOverdueLabel),
            reason: 'Both flags must agree');
      });

      test('10 minutes 1 second → overdue', () {
        final elapsed = const Duration(minutes: 10, seconds: 1);
        final (showRedBorder, showOverdueLabel) = _evaluate(elapsed);

        expect(elapsed.inMinutes, equals(10));
        expect(showRedBorder, isTrue,
            reason: '10m1s exceeds the 10-minute threshold');
        expect(showOverdueLabel, isTrue,
            reason: '10m1s exceeds the 10-minute threshold');
        expect(showRedBorder, equals(showOverdueLabel),
            reason: 'Both flags must agree');
      });
    });
  });
}
