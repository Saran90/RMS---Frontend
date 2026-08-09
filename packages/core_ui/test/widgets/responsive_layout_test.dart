import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper: pumps a [ResponsiveLayout] inside a [MaterialApp] at the given [width].
Future<void> pumpAtWidth(
  WidgetTester tester, {
  required double width,
  required Widget compact,
  required Widget medium,
  required Widget expanded,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: ResponsiveLayout(
          compact: compact,
          medium: medium,
          expanded: expanded,
        ),
      ),
    ),
  );
}

void main() {
  const compactWidget = Text('compact', key: Key('compact'));
  const mediumWidget = Text('medium', key: Key('medium'));
  const expandedWidget = Text('expanded', key: Key('expanded'));

  group('ResponsiveLayout — breakpoint routing', () {
    // ── Requirement 17.1 ─────────────────────────────────────────────────────
    group('compact slot (width < 600)', () {
      testWidgets('renders compact at width 0', (tester) async {
        await pumpAtWidth(tester,
            width: 0,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('compact')), findsOneWidget);
        expect(find.byKey(const Key('medium')), findsNothing);
        expect(find.byKey(const Key('expanded')), findsNothing);
      });

      testWidgets('renders compact at width 1', (tester) async {
        await pumpAtWidth(tester,
            width: 1,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('compact')), findsOneWidget);
      });

      testWidgets('renders compact just below breakpoint (599.9)',
          (tester) async {
        await pumpAtWidth(tester,
            width: 599.9,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('compact')), findsOneWidget);
        expect(find.byKey(const Key('medium')), findsNothing);
        expect(find.byKey(const Key('expanded')), findsNothing);
      });
    });

    // ── Requirement 17.2 ─────────────────────────────────────────────────────
    group('medium slot (600 ≤ width < 1024)', () {
      testWidgets('renders medium exactly at compact breakpoint (600)',
          (tester) async {
        await pumpAtWidth(tester,
            width: 600,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('medium')), findsOneWidget);
        expect(find.byKey(const Key('compact')), findsNothing);
        expect(find.byKey(const Key('expanded')), findsNothing);
      });

      testWidgets('renders medium at width 800', (tester) async {
        await pumpAtWidth(tester,
            width: 800,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('medium')), findsOneWidget);
      });

      testWidgets('renders medium just below medium breakpoint (1023.9)',
          (tester) async {
        await pumpAtWidth(tester,
            width: 1023.9,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('medium')), findsOneWidget);
        expect(find.byKey(const Key('compact')), findsNothing);
        expect(find.byKey(const Key('expanded')), findsNothing);
      });
    });

    // ── Requirement 17.3 ─────────────────────────────────────────────────────
    group('expanded slot (width ≥ 1024)', () {
      testWidgets('renders expanded exactly at medium breakpoint (1024)',
          (tester) async {
        await pumpAtWidth(tester,
            width: 1024,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('expanded')), findsOneWidget);
        expect(find.byKey(const Key('compact')), findsNothing);
        expect(find.byKey(const Key('medium')), findsNothing);
      });

      testWidgets('renders expanded at width 1440', (tester) async {
        await pumpAtWidth(tester,
            width: 1440,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('expanded')), findsOneWidget);
      });

      testWidgets('renders expanded at very large width (4000)',
          (tester) async {
        await pumpAtWidth(tester,
            width: 4000,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);
        expect(find.byKey(const Key('expanded')), findsOneWidget);
        expect(find.byKey(const Key('compact')), findsNothing);
        expect(find.byKey(const Key('medium')), findsNothing);
      });
    });

    // ── Coverage gap: exactly one slot shown at any width ────────────────────
    testWidgets('exactly one slot is visible for any given width',
        (tester) async {
      for (final width in [
        0.0,
        300.0,
        599.9,
        600.0,
        900.0,
        1023.9,
        1024.0,
        1920.0
      ]) {
        await pumpAtWidth(tester,
            width: width,
            compact: compactWidget,
            medium: mediumWidget,
            expanded: expandedWidget);

        final compactCount =
            tester.widgetList(find.byKey(const Key('compact'))).length;
        final mediumCount =
            tester.widgetList(find.byKey(const Key('medium'))).length;
        final expandedCount =
            tester.widgetList(find.byKey(const Key('expanded'))).length;

        expect(
          compactCount + mediumCount + expandedCount,
          equals(1),
          reason: 'Expected exactly one slot to be shown at width=$width',
        );
      }
    });
  });
}
