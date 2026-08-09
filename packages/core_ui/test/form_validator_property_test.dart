// Feature: rms-flutter-frontend, Property 15: Form focus on error

import 'dart:math';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fast_check.dart';

/// **Validates: Requirements 20.4**
///
/// Property 15: Form Focus on Validation Failure
///
/// For any form with N fields (1–10) where a random subset have validation
/// errors, after [FormValidator.submitAndFocus] the focused [FocusNode] MUST
/// be the one at the **lowest index** that has an error — and it MUST be
/// focused before any other UI update.

// ---------------------------------------------------------------------------
// Generator types
// ---------------------------------------------------------------------------

/// Describes a generated form configuration.
class _FormConfig {
  const _FormConfig({required this.fieldCount, required this.errorMask});

  /// Number of fields in the form (1–10).
  final int fieldCount;

  /// Bitmask: bit i is set ↔ field i has a validation error.
  /// Always has at least one bit set (at least one erring field).
  final int errorMask;

  /// Index of the first erring field (lowest set bit).
  int get firstErrorIndex {
    for (var i = 0; i < fieldCount; i++) {
      if ((errorMask >> i) & 1 == 1) return i;
    }
    // Should never happen — we guarantee at least one error.
    return -1;
  }

  bool hasError(int index) => (errorMask >> index) & 1 == 1;

  @override
  String toString() =>
      '_FormConfig(fieldCount=$fieldCount, errorMask=${errorMask.toRadixString(2).padLeft(fieldCount, '0')})';
}

// ---------------------------------------------------------------------------
// Arbitrary for _FormConfig
// ---------------------------------------------------------------------------

/// Generates a [_FormConfig] with:
///   - fieldCount ∈ [1, 10]
///   - errorMask with at least one of the fieldCount bits set
Arbitrary<_FormConfig> _formConfigArbitrary() => Arbitrary<_FormConfig>((rng) {
      final fieldCount = 1 + rng.nextInt(10); // 1..10
      final maxMask = 1 << fieldCount; // exclusive upper bound
      // Generate a non-zero mask (ensures at least one error).
      int errorMask;
      do {
        errorMask = rng.nextInt(maxMask);
      } while (errorMask == 0);
      return _FormConfig(fieldCount: fieldCount, errorMask: errorMask);
    });

// ---------------------------------------------------------------------------
// Widget builder helpers
// ---------------------------------------------------------------------------

/// Builds the data structures needed for the form test:
/// - [formKey]: key for the [Form] widget
/// - [focusNodes]: one [FocusNode] per field, in order
/// - [fieldKeys]: one [GlobalKey<FormFieldState>] per field, attached to
///   each [TextFormField] so [FormValidator] can inspect [hasError]
/// - [entries]: [FormFieldEntry] list passed to [FormValidator.submitAndFocus]
({
  GlobalKey<FormState> formKey,
  List<FocusNode> focusNodes,
  List<GlobalKey<FormFieldState<dynamic>>> fieldKeys,
  List<FormFieldEntry?> entries,
}) _buildFormData(_FormConfig config) {
  final formKey = GlobalKey<FormState>();
  final focusNodes = List.generate(config.fieldCount, (_) => FocusNode());
  final fieldKeys = List.generate(
    config.fieldCount,
    (_) => GlobalKey<FormFieldState<dynamic>>(),
  );
  final entries = List<FormFieldEntry?>.generate(
    config.fieldCount,
    (i) => FormFieldEntry(fieldKey: fieldKeys[i], focusNode: focusNodes[i]),
  );
  return (
    formKey: formKey,
    focusNodes: focusNodes,
    fieldKeys: fieldKeys,
    entries: entries,
  );
}

Widget _buildFormWidget(
  GlobalKey<FormState> formKey,
  List<FocusNode> focusNodes,
  List<GlobalKey<FormFieldState<dynamic>>> fieldKeys,
  _FormConfig config,
) {
  return MaterialApp(
    home: Scaffold(
      body: Form(
        key: formKey,
        child: Column(
          children: [
            for (var i = 0; i < config.fieldCount; i++)
              TextFormField(
                key: fieldKeys[i],
                focusNode: focusNodes[i],
                // Validator returns non-null ↔ bit i is set in errorMask.
                validator: (_) => config.hasError(i) ? 'error at $i' : null,
              ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Async forAll for widget tests
// ---------------------------------------------------------------------------

Future<void> _forAllWidgetTest<T>(
  Arbitrary<T> arbitrary,
  Future<void> Function(T) property, {
  int iterations = 100,
  int seed = 42,
}) async {
  final rng = Random(seed);
  for (var i = 0; i < iterations; i++) {
    final value = arbitrary.generate(rng);
    await property(value);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Property 15: Form focus on validation failure', () {
    /// Sub-property A — submitAndFocus() returns false when form is invalid
    /// and focuses the first erring field.
    testWidgets(
      'focus moves to first erring field and returns false for any invalid form',
      (tester) async {
        await _forAllWidgetTest(
          _formConfigArbitrary(),
          (config) async {
            final (:formKey, :focusNodes, :fieldKeys, :entries) =
                _buildFormData(config);

            await tester.pumpWidget(
              _buildFormWidget(formKey, focusNodes, fieldKeys, config),
            );
            await tester.pump();

            // Act — call the SUT with proper FormFieldEntry list.
            final result = FormValidator.submitAndFocus(formKey, entries);

            // 1. Must return false (form is invalid).
            expect(
              result,
              isFalse,
              reason:
                  'submitAndFocus() should return false for invalid form. config=$config',
            );

            // 2. Allow focus system to settle.
            await tester.pump();

            final expectedIndex = config.firstErrorIndex;

            // 3. The first erring field must have focus.
            expect(
              focusNodes[expectedIndex].hasFocus,
              isTrue,
              reason:
                  'FocusNode at index $expectedIndex must have focus. config=$config',
            );

            // 4. No prior node (index < firstErrorIndex) must have focus.
            for (var i = 0; i < expectedIndex; i++) {
              expect(
                focusNodes[i].hasFocus,
                isFalse,
                reason:
                    'FocusNode at index $i (before first error at $expectedIndex) '
                    'must NOT have focus. config=$config',
              );
            }
          },
        );
      },
    );

    /// Sub-property B — submitAndFocus() returns true when form is valid
    /// (no nodes should gain focus in that case).
    testWidgets(
      'returns true and grants no focus when form is fully valid',
      (tester) async {
        // A "valid" config: fieldCount ∈ [1, 10], errorMask = 0 (no errors).
        final validConfigArb = Arbitrary<_FormConfig>((rng) {
          final fieldCount = 1 + rng.nextInt(10);
          return _FormConfig(fieldCount: fieldCount, errorMask: 0);
        });

        await _forAllWidgetTest(
          validConfigArb,
          (config) async {
            final (:formKey, :focusNodes, :fieldKeys, :entries) =
                _buildFormData(config);

            await tester.pumpWidget(
              _buildFormWidget(formKey, focusNodes, fieldKeys, config),
            );
            await tester.pump();

            final result = FormValidator.submitAndFocus(formKey, entries);

            // Must return true for a valid form.
            expect(
              result,
              isTrue,
              reason:
                  'submitAndFocus() should return true for valid form. config=$config',
            );

            await tester.pump();

            // No focus node should have been requested.
            for (var i = 0; i < config.fieldCount; i++) {
              expect(
                focusNodes[i].hasFocus,
                isFalse,
                reason:
                    'FocusNode at index $i should NOT have focus after valid submit. config=$config',
              );
            }
          },
        );
      },
    );
  });
}
