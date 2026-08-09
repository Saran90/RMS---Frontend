// Feature: rms-flutter-frontend, Property 6: Offline suppression
//
// Validates: Requirements 19.2, 19.4

import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:staff_portal/connectivity/connectivity_cubit.dart';

import '../helpers/fast_check.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockConnectivityCubit extends MockCubit<ConnectivityStatus>
    implements ConnectivityCubit {}

// ---------------------------------------------------------------------------
// Write-action button guarded by offline state
// ---------------------------------------------------------------------------

/// A sample write-action button that checks connectivity before acting.
///
/// When offline:
/// - The [ElevatedButton] is visually disabled (onPressed is null).
/// - A [Tooltip] with the message "No internet connection" is shown.
class OfflineGuardedButton extends StatelessWidget {
  const OfflineGuardedButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        final isOffline = status == ConnectivityStatus.disconnected;

        return Tooltip(
          message: isOffline ? 'No internet connection' : '',
          child: ElevatedButton(
            // Null onPressed disables the button
            onPressed: isOffline ? null : onPressed,
            child: Text(label),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Property 6 — Offline Write Suppression', () {
    late MockConnectivityCubit mockCubit;

    setUp(() {
      mockCubit = MockConnectivityCubit();
    });

    // Helper that pumps the guarded button into the widget tree.
    Future<void> pumpButton(
      WidgetTester tester,
      MockConnectivityCubit cubit,
      VoidCallback onPressed,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ConnectivityCubit>.value(
            value: cubit,
            child: Scaffold(
              body: Center(
                child: OfflineGuardedButton(
                  label: 'Submit',
                  onPressed: onPressed,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Deterministic tests ──────────────────────────────────────────────────

    testWidgets('button is disabled and shows tooltip text when offline', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(ConnectivityStatus.disconnected);

      var callCount = 0;
      await pumpButton(tester, mockCubit, () => callCount++);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        button.onPressed,
        isNull,
        reason: 'Button must be disabled when offline',
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(callCount, 0, reason: 'Write action must not fire when offline');

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'No internet connection');
    });

    testWidgets('button is enabled and tooltip is empty when online', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(ConnectivityStatus.connected);

      var callCount = 0;
      await pumpButton(tester, mockCubit, () => callCount++);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Button must be enabled when online',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(callCount, 1, reason: 'Write action must fire once when online');

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, isEmpty);
    });

    // ── Property-based variant ────────────────────────────────────────────────

    testWidgets('Property 6 — for any offline write attempt: button disabled, '
        'no callback fired, tooltip shows "No internet connection"', (
      tester,
    ) async {
      final offlineArbitrary = Arbitrary.boolean();
      final rng = Random(42);

      for (var i = 0; i < 100; i++) {
        final isOffline = offlineArbitrary.generate(rng);

        final cubit = MockConnectivityCubit();
        when(() => cubit.state).thenReturn(
          isOffline
              ? ConnectivityStatus.disconnected
              : ConnectivityStatus.connected,
        );

        var callCount = 0;
        await pumpButton(tester, cubit, () => callCount++);

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );

        if (isOffline) {
          // Must be disabled — no write goes through
          expect(
            button.onPressed,
            isNull,
            reason: 'Iteration $i: offline → button must be null',
          );

          await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
          await tester.pump();
          expect(
            callCount,
            0,
            reason: 'Iteration $i: offline → 0 write calls expected',
          );

          final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
          expect(
            tooltip.message,
            'No internet connection',
            reason: 'Iteration $i: offline → tooltip must show',
          );
        } else {
          // Online — button must be enabled
          expect(
            button.onPressed,
            isNotNull,
            reason: 'Iteration $i: online → button must be enabled',
          );
        }
      }
    });
  });
}
