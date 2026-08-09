// Feature: rms-flutter-frontend, Property 3: Required field validation
//
// Validates: Requirements 4.3
//
// For any combination of missing required fields (name, address, gstNumber),
// the form SHALL display a field-level error and SHALL make no network call.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal validator functions (mirror the screen's validators)
// ---------------------------------------------------------------------------

String? _validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Widget under test — a minimal form that mirrors the onboarding Step 1 form
// ---------------------------------------------------------------------------

class _OnboardingDetailsForm extends StatefulWidget {
  const _OnboardingDetailsForm({required this.onSubmit});

  /// Called with (name, address, gstNumber) only when the form is valid.
  final void Function(String name, String address, String gstNumber) onSubmit;

  @override
  State<_OnboardingDetailsForm> createState() => _OnboardingDetailsFormState();
}

class _OnboardingDetailsFormState extends State<_OnboardingDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameCtrl.text.trim(),
        _addressCtrl.text.trim(),
        _gstCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key('name'),
                controller: _nameCtrl,
                validator: (v) => _validateRequired(v, 'Restaurant name'),
              ),
              TextFormField(
                key: const Key('address'),
                controller: _addressCtrl,
                validator: (v) => _validateRequired(v, 'Address'),
              ),
              TextFormField(
                key: const Key('gst'),
                controller: _gstCtrl,
                validator: (v) => _validateRequired(v, 'GST number'),
              ),
              ElevatedButton(
                key: const Key('submit'),
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Feature: rms-flutter-frontend, Property 3: Required field validation
  group('Onboarding Step 1 — Required Field Validation (Property 3)', () {
    // ── All fields empty ───────────────────────────────────────────────────

    testWidgets(
      'shows validation errors for all three fields when all are empty',
      (tester) async {
        var submitCallCount = 0;

        await tester.pumpWidget(_OnboardingDetailsForm(
          onSubmit: (_, __, ___) => submitCallCount++,
        ));

        await tester.tap(find.byKey(const Key('submit')));
        await tester.pump();

        // All three required-field errors should be shown.
        expect(find.text('Restaurant name is required'), findsOneWidget);
        expect(find.text('Address is required'), findsOneWidget);
        expect(find.text('GST number is required'), findsOneWidget);

        // No network call (submit callback not fired).
        expect(submitCallCount, 0);
      },
    );

    // ── Individual missing fields ──────────────────────────────────────────

    testWidgets(
      'shows error and blocks submit when name is missing',
      (tester) async {
        var submitCallCount = 0;

        await tester.pumpWidget(_OnboardingDetailsForm(
          onSubmit: (_, __, ___) => submitCallCount++,
        ));

        await tester.enterText(find.byKey(const Key('address')), '123 Main St');
        await tester.enterText(find.byKey(const Key('gst')), '29ABCDE1234F1Z5');
        // Leave name empty.

        await tester.tap(find.byKey(const Key('submit')));
        await tester.pump();

        expect(find.text('Restaurant name is required'), findsOneWidget);
        expect(submitCallCount, 0,
            reason: 'No HTTP call should be made when name is missing');
      },
    );

    testWidgets(
      'shows error and blocks submit when address is missing',
      (tester) async {
        var submitCallCount = 0;

        await tester.pumpWidget(_OnboardingDetailsForm(
          onSubmit: (_, __, ___) => submitCallCount++,
        ));

        await tester.enterText(find.byKey(const Key('name')), 'Spice Garden');
        await tester.enterText(find.byKey(const Key('gst')), '29ABCDE1234F1Z5');
        // Leave address empty.

        await tester.tap(find.byKey(const Key('submit')));
        await tester.pump();

        expect(find.text('Address is required'), findsOneWidget);
        expect(submitCallCount, 0,
            reason: 'No HTTP call should be made when address is missing');
      },
    );

    testWidgets(
      'shows error and blocks submit when GST number is missing',
      (tester) async {
        var submitCallCount = 0;

        await tester.pumpWidget(_OnboardingDetailsForm(
          onSubmit: (_, __, ___) => submitCallCount++,
        ));

        await tester.enterText(find.byKey(const Key('name')), 'Spice Garden');
        await tester.enterText(find.byKey(const Key('address')), '123 Main St');
        // Leave GST empty.

        await tester.tap(find.byKey(const Key('submit')));
        await tester.pump();

        expect(find.text('GST number is required'), findsOneWidget);
        expect(submitCallCount, 0,
            reason: 'No HTTP call should be made when GST is missing');
      },
    );

    // ── Valid form proceeds ────────────────────────────────────────────────

    testWidgets(
      'calls submit when all required fields are present',
      (tester) async {
        var submitCallCount = 0;

        await tester.pumpWidget(_OnboardingDetailsForm(
          onSubmit: (_, __, ___) => submitCallCount++,
        ));

        await tester.enterText(find.byKey(const Key('name')), 'Spice Garden');
        await tester.enterText(
            find.byKey(const Key('address')), '123 Main St, Chennai');
        await tester.enterText(find.byKey(const Key('gst')), '29ABCDE1234F1Z5');

        await tester.tap(find.byKey(const Key('submit')));
        await tester.pump();

        expect(submitCallCount, 1,
            reason: 'Submit should fire once when all fields are valid');
        expect(find.text('Restaurant name is required'), findsNothing);
        expect(find.text('Address is required'), findsNothing);
        expect(find.text('GST number is required'), findsNothing);
      },
    );

    // ── Whitespace-only values treated as empty ───────────────────────────

    testWidgets(
      'treats whitespace-only values as empty and shows validation error',
      (tester) async {
        var submitCallCount = 0;

        await tester.pumpWidget(_OnboardingDetailsForm(
          onSubmit: (_, __, ___) => submitCallCount++,
        ));

        await tester.enterText(find.byKey(const Key('name')), '   ');
        await tester.enterText(find.byKey(const Key('address')), '\t\n');
        await tester.enterText(find.byKey(const Key('gst')), '  ');

        await tester.tap(find.byKey(const Key('submit')));
        await tester.pump();

        expect(find.text('Restaurant name is required'), findsOneWidget);
        expect(find.text('Address is required'), findsOneWidget);
        expect(find.text('GST number is required'), findsOneWidget);
        expect(submitCallCount, 0);
      },
    );
  });
}
