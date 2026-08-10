// Feature: rms-flutter-frontend, Property 4: Role navigation
//
// Validates: Requirements 16.3, 16.4, 16.5, 16.6, 16.7

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';
import 'package:staff_portal/navigation/nav_items.dart';

import '../helpers/fast_check.dart';

// ---------------------------------------------------------------------------
// Expected nav items per role (Req 16.3–16.6)
// ---------------------------------------------------------------------------

const Map<StaffRole, Set<String>> _expectedLabels = {
  StaffRole.owner: {
    'Dashboard',
    'Orders',
    'Menu',
    'Tables',
    'KDS',
    'Billing',
    'Staff',
    'Inventory',
    'Reports',
    'Settings',
  },
  StaffRole.manager: {
    'Dashboard',
    'Orders',
    'Menu',
    'Tables',
    'KDS',
    'Billing',
    'Staff',
    'Inventory',
    'Reports',
    // No Settings
  },
  StaffRole.waiter: {'Dashboard', 'Orders', 'Tables'},
  StaffRole.chef: {'Dashboard', 'KDS'},
  StaffRole.cashier: {'Orders', 'Billing'},
  StaffRole.deliveryStaff: {'Dashboard', 'Orders'},
};

void main() {
  group('Property 4 — Role-Based Navigation Invariant', () {
    // ── Pure unit tests (no widget pump needed) ──────────────────────────────

    test('navItemsForRole returns exactly the permitted set for each role', () {
      for (final role in StaffRole.values) {
        final items = navItemsForRole(role);
        final labels = items.map((i) => i.label).toSet();
        final expected = _expectedLabels[role]!;

        expect(
          labels,
          equals(expected),
          reason: 'Role ${role.jsonValue}: expected $expected, got $labels',
        );
      }
    });

    test('no two roles produce identical nav item sets (sanity)', () {
      final results = <StaffRole, Set<String>>{};
      for (final role in StaffRole.values) {
        results[role] = navItemsForRole(role).map((i) => i.label).toSet();
      }
      // owner and manager differ by Settings
      expect(
        results[StaffRole.owner],
        isNot(equals(results[StaffRole.manager])),
      );
    });

    // ── Property-based variant ────────────────────────────────────────────────

    test('Property 4 — for any StaffRole the visible nav items match the '
        'permitted set exactly (no extras, no omissions)', () {
      final roleArbitrary = Arbitrary.oneOf(StaffRole.values.toList());

      forAll(
        roleArbitrary,
        (role) {
          final items = navItemsForRole(role);
          final labels = items.map((i) => i.label).toSet();
          final expected = _expectedLabels[role]!;

          // No extra items
          final extras = labels.difference(expected);
          expect(
            extras,
            isEmpty,
            reason: 'Role ${role.jsonValue} has unexpected items: $extras',
          );

          // No missing items
          final missing = expected.difference(labels);
          expect(
            missing,
            isEmpty,
            reason: 'Role ${role.jsonValue} is missing items: $missing',
          );
        },
        iterations: 100,
        seed: 42,
      );
    });

    // ── Widget-level smoke test ───────────────────────────────────────────────

    testWidgets(
      'AppShell with owner role shows all 10 nav items in expanded layout',
      (tester) async {
        // Set screen width to expanded (≥ 1024 dp) so NavigationDrawer is used
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ownerItems = navItemsForRole(StaffRole.owner);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: NavigationDrawer(
                      selectedIndex: 0,
                      onDestinationSelected: (_) {},
                      children: ownerItems
                          .map(
                            (item) => NavigationDrawerDestination(
                              icon: Icon(item.icon),
                              label: Text(item.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const Expanded(child: Center(child: Text('Content'))),
                ],
              ),
            ),
          ),
        );

        for (final label in _expectedLabels[StaffRole.owner]!) {
          expect(
            find.text(label),
            findsOneWidget,
            reason: 'Expected nav item "$label" to be visible for owner',
          );
        }
      },
    );

    testWidgets(
      'AppShell with waiter role shows only Dashboard, Orders, Tables',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final waiterItems = navItemsForRole(StaffRole.waiter);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: NavigationDrawer(
                      selectedIndex: 0,
                      onDestinationSelected: (_) {},
                      children: waiterItems
                          .map(
                            (item) => NavigationDrawerDestination(
                              icon: Icon(item.icon),
                              label: Text(item.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const Expanded(child: Center(child: Text('Content'))),
                ],
              ),
            ),
          ),
        );

        // Should be visible
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('Tables'), findsOneWidget);

        // Should NOT be visible
        expect(find.text('Menu'), findsNothing);
        expect(find.text('KDS'), findsNothing);
        expect(find.text('Billing'), findsNothing);
        expect(find.text('Staff'), findsNothing);
        expect(find.text('Inventory'), findsNothing);
        expect(find.text('Reports'), findsNothing);
        expect(find.text('Settings'), findsNothing);
      },
    );
  });
}
