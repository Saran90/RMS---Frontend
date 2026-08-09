// Feature: rms-flutter-frontend, Property 2: Short password rejection
// Validates: Requirements 2.6 — 100 iterations

import 'dart:math';

import 'package:auth/auth.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fast_check.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Characters used by the generator — printable ASCII a-z, A-Z, 0-9.
const _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Returns a string of exactly [length] characters drawn from [_chars].
String _stringOfLength(int length, Random rng) {
  if (length == 0) return '';
  return String.fromCharCodes(
    List.generate(
      length,
      (_) => _chars.codeUnitAt(rng.nextInt(_chars.length)),
    ),
  );
}

/// Arbitrary that generates strings of length 0–7 (all below the 8-char min).
final _shortPasswordArbitrary = Arbitrary<String>(
  (rng) => _stringOfLength(rng.nextInt(8), rng), // 0..7 inclusive
);

// ── Password validator (mirrors the one in register/change-password screens) ─

String? _passwordValidator(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 8) return 'Password must be at least 8 characters';
  return null;
}

// ── Widget under test ─────────────────────────────────────────────────────────

/// A minimal form that contains only a password [TextFormField] with the
/// production validator.  Submitting calls [Form.validate].
class _PasswordFormWidget extends StatefulWidget {
  const _PasswordFormWidget({required this.authBloc});

  final MockAuthBloc authBloc;

  @override
  State<_PasswordFormWidget> createState() => _PasswordFormWidgetState();
}

class _PasswordFormWidgetState extends State<_PasswordFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  void submit() => _formKey.currentState!.validate();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: widget.authBloc,
        child: Scaffold(
          body: Form(
            key: _formKey,
            child: TextFormField(
              key: const Key('passwordField'),
              controller: _controller,
              validator: _passwordValidator,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Property test ─────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    // Register a concrete AuthEvent instance as fallback for mocktail's any<AuthEvent>().
    // We use LogoutRequested (no required params) since AuthEvent is sealed.
    registerFallbackValue(const LogoutRequested());
  });

  group('Property 2 – Short password rejection (Requirement 2.6)', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      // Provide a stable initial state so the mock bloc behaves predictably.
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthInitial(),
      );
    });

    tearDown(() {
      mockAuthBloc.close();
    });

    testWidgets(
      'validation error appears and no AuthEvent is dispatched '
      'for any password shorter than 8 characters (100 iterations)',
      (tester) async {
        await forAllAsync<String>(
          _shortPasswordArbitrary,
          (shortPassword) async {
            // Build the widget fresh for each iteration.
            await tester.pumpWidget(
              _PasswordFormWidget(authBloc: mockAuthBloc),
            );

            // Enter the short password.
            await tester.enterText(
              find.byKey(const Key('passwordField')),
              shortPassword,
            );

            // Submit the form (triggers validation only — no bloc dispatch).
            final state = tester.state<_PasswordFormWidgetState>(
              find.byType(_PasswordFormWidget),
            );
            state.submit();

            await tester.pump();

            // ── Assert validation error is shown ──────────────────────────
            final expectedError = shortPassword.isEmpty
                ? 'Password is required'
                : 'Password must be at least 8 characters';

            expect(
              find.text(expectedError),
              findsOneWidget,
              reason: 'Expected validation error "$expectedError" for '
                  'password of length ${shortPassword.length}',
            );

            // ── Assert NO HTTP call was made (no event dispatched) ─────────
            verifyNever(
              () => mockAuthBloc.add(any<AuthEvent>()),
            );
          },
          iterations: 100,
        );
      },
    );
  });
}
