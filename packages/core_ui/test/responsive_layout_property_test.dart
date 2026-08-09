// Feature: rms-flutter-frontend, Property 14: Breakpoint consistency

import 'dart:math';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fast_check.dart';

/// **Validates: Requirements 17.1, 17.2, 17.3**
///
/// Property 14: Responsive Layout Breakpoint Consistency
///
/// For any arbitrary screen width, [ResponsiveLayout] must render exactly the
/// correct slot with no gaps or overlaps:
///   - width < 600         → compact slot
///   - 600 ≤ width < 1024  → medium slot
///   - width ≥ 1024        → expanded slot

// ── Shared sentinel widgets with unique keys ─────────────────────────────────
const _compactWidget = Text('compact', key: Key('compact'));
const _mediumWidget = Text('medium', key: Key('medium'));
const _expandedWidget = Text('expanded', key: Key('expanded'));

/// Pumps a [ResponsiveLayout] inside a [MediaQuery] constrained to [width].
Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: const ResponsiveLayout(
          compact: _compactWidget,
          medium: _mediumWidget,
          expanded: _expandedWidget,
        ),
      ),
    ),
  );
}

/// Async variant of [forAll] for widget tests that require [WidgetTester].
///
/// Runs [property] for [iterations] randomly-generated inputs produced by
/// [arbitrary] using a fixed seed for reproducibility.
Future<void> forAllWidgetTest<T>(
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

void main() {
  // ── Property 14 ──────────────────────────────────────────────────────────
  group('Property 14: Responsive breakpoint consistency', () {
    /// Sub-property A — compact range: width ∈ [0, 600)
    /// Validates: Requirement 17.1
    testWidgets('compact slot rendered for all widths in [0, 600)',
        (tester) async {
      await forAllWidgetTest(
        Arbitrary.doubleInRange(0, 599.9999),
        (width) async {
          await _pumpAtWidth(tester, width);
          expect(
            find.byKey(const Key('compact')),
            findsOneWidget,
            reason: 'compact slot expected at width=$width',
          );
          expect(
            find.byKey(const Key('medium')),
            findsNothing,
            reason: 'medium slot must NOT appear at width=$width',
          );
          expect(
            find.byKey(const Key('expanded')),
            findsNothing,
            reason: 'expanded slot must NOT appear at width=$width',
          );
        },
        iterations: 100,
      );
    });

    /// Sub-property B — medium range: width ∈ [600, 1024)
    /// Validates: Requirement 17.2
    testWidgets('medium slot rendered for all widths in [600, 1024)',
        (tester) async {
      await forAllWidgetTest(
        Arbitrary.doubleInRange(600, 1023.9999),
        (width) async {
          await _pumpAtWidth(tester, width);
          expect(
            find.byKey(const Key('medium')),
            findsOneWidget,
            reason: 'medium slot expected at width=$width',
          );
          expect(
            find.byKey(const Key('compact')),
            findsNothing,
            reason: 'compact slot must NOT appear at width=$width',
          );
          expect(
            find.byKey(const Key('expanded')),
            findsNothing,
            reason: 'expanded slot must NOT appear at width=$width',
          );
        },
        iterations: 100,
      );
    });

    /// Sub-property C — expanded range: width ∈ [1024, 4096]
    /// Validates: Requirement 17.3
    testWidgets('expanded slot rendered for all widths in [1024, 4096]',
        (tester) async {
      await forAllWidgetTest(
        Arbitrary.doubleInRange(1024, 4096),
        (width) async {
          await _pumpAtWidth(tester, width);
          expect(
            find.byKey(const Key('expanded')),
            findsOneWidget,
            reason: 'expanded slot expected at width=$width',
          );
          expect(
            find.byKey(const Key('compact')),
            findsNothing,
            reason: 'compact slot must NOT appear at width=$width',
          );
          expect(
            find.byKey(const Key('medium')),
            findsNothing,
            reason: 'medium slot must NOT appear at width=$width',
          );
        },
        iterations: 100,
      );
    });

    /// Sub-property D — no gaps or overlaps across the full width space
    /// Validates: Requirements 17.1, 17.2, 17.3
    ///
    /// For any arbitrary width in [0, 4096], exactly one slot is rendered.
    testWidgets('exactly one slot rendered for any width in [0, 4096]',
        (tester) async {
      await forAllWidgetTest(
        Arbitrary.doubleInRange(0, 4096),
        (width) async {
          await _pumpAtWidth(tester, width);

          final compactCount =
              tester.widgetList(find.byKey(const Key('compact'))).length;
          final mediumCount =
              tester.widgetList(find.byKey(const Key('medium'))).length;
          final expandedCount =
              tester.widgetList(find.byKey(const Key('expanded'))).length;

          expect(
            compactCount + mediumCount + expandedCount,
            equals(1),
            reason:
                'Exactly one slot must be visible at width=$width (no gaps, no overlaps)',
          );
        },
        iterations: 100,
      );
    });
  });
}
