// Feature: rms-flutter-frontend, Property 5: State revert on API failure
// Validates: Requirements 7.7 — 100 iterations

import 'package:api_client/api_client.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:models/models.dart';
import 'package:staff_portal/menu/menu_item_bloc.dart';
import 'package:staff_portal/menu/menu_repository.dart';

import '../helpers/fast_check.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockMenuRepository extends Mock implements MenuRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a minimal [MenuItem] with the given [id] and [isAvailable].
MenuItem _item({required String id, required bool isAvailable}) => MenuItem(
      id: id,
      name: 'Test Item',
      categoryId: 'cat-1',
      basePrice: 100.0,
      gstRate: 5.0,
      dietaryType: DietaryType.veg,
      isAvailable: isAvailable,
      variants: const [],
      modifierGroups: const [],
    );

// ── Arbitraries ───────────────────────────────────────────────────────────────

/// Generates a boolean representing the prior availability state.
final _boolArbitrary = Arbitrary.boolean();

/// Generates a non-empty error message string.
final _errorArbitrary = Arbitrary.string(minLen: 4, maxLen: 60);

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockMenuRepository mockRepo;

  setUp(() {
    mockRepo = MockMenuRepository();
    // Stub getItems() to return an empty list by default (not under test).
    when(() => mockRepo.getItems()).thenAnswer((_) async => []);
    when(() => mockRepo.toggleAvailability(any(),
        isAvailable:
            any(named: 'isAvailable'))).thenAnswer((inv) async => _item(
          id: inv.positionalArguments[0] as String,
          isAvailable: inv.namedArguments[const Symbol('isAvailable')] as bool,
        ));
  });

  group(
      'Property 5 – State revert on API failure: availability toggle (Req 7.7)',
      () {
    test(
      'UI reverts to prior availability and emits non-empty error '
      'for any prior state and any API error (100 iterations)',
      () async {
        await forAllAsync<(bool, String)>(
          Arbitrary<(bool, String)>((rng) => (
                _boolArbitrary.generate(rng),
                _errorArbitrary.generate(rng),
              )),
          (input) async {
            final (priorAvailability, errorMessage) = input;
            final newAvailability = !priorAvailability;

            // Override mock: toggleAvailability throws ApiException
            when(
              () => mockRepo.toggleAvailability(
                any(),
                isAvailable: newAvailability,
              ),
            ).thenThrow(ApiException(
              statusCode: 500,
              errorCode: 'server_error',
              message: errorMessage,
            ));

            // Seed the bloc with a loaded state containing our item
            final seedItem =
                _item(id: 'item-1', isAvailable: priorAvailability);

            final bloc = MenuItemBloc(repository: mockRepo);

            // Manually emit the loaded state by triggering a load with
            // a stub that returns our seed item.
            when(() => mockRepo.getItems()).thenAnswer((_) async => [seedItem]);
            bloc.add(const MenuItemsLoadRequested());
            await Future<void>.delayed(Duration.zero);

            // Now dispatch the toggle
            bloc.add(MenuItemAvailabilityToggled(
              id: 'item-1',
              isAvailable: newAvailability,
            ));

            // Collect states emitted after the toggle
            final states = <MenuItemState>[];
            await bloc.stream
                .take(2) // optimistic update + revert/error
                .forEach(states.add)
                .timeout(const Duration(seconds: 2), onTimeout: () {});

            await bloc.close();

            // ── Assert optimistic state emitted ───────────────────────────
            final optimistic = states.isNotEmpty ? states.first : null;
            if (optimistic is MenuItemLoaded) {
              final toggled =
                  optimistic.items.firstWhere((i) => i.id == 'item-1');
              expect(
                toggled.isAvailable,
                equals(newAvailability),
                reason: 'Optimistic update should flip availability',
              );
            }

            // ── Assert revert state ───────────────────────────────────────
            final revertState = states.length >= 2 ? states[1] : null;

            expect(
              revertState,
              isA<MenuItemOperationError>(),
              reason: 'Expected MenuItemOperationError after API failure',
            );

            final opError = revertState as MenuItemOperationError;

            // Items reverted to prior state
            final revertedItem =
                opError.items.firstWhere((i) => i.id == 'item-1');
            expect(
              revertedItem.isAvailable,
              equals(priorAvailability),
              reason: 'Item availability should revert to prior value '
                  '(was $priorAvailability, toggled to $newAvailability)',
            );

            // Non-empty error message shown (Req 7.7)
            expect(
              opError.message.isNotEmpty,
              isTrue,
              reason: 'Error message must be non-empty',
            );
            expect(
              opError.message,
              equals(errorMessage),
              reason: 'Error message should match the ApiException message',
            );
          },
          iterations: 100,
        );
      },
    );

    // ── Deterministic edge cases ──────────────────────────────────────────

    blocTest<MenuItemBloc, MenuItemState>(
      'emits [optimistic loaded, operation error] when toggle API call fails',
      build: () {
        when(() => mockRepo.getItems())
            .thenAnswer((_) async => [_item(id: 'x', isAvailable: true)]);
        when(
          () => mockRepo.toggleAvailability('x', isAvailable: false),
        ).thenThrow(ApiException(
          statusCode: 422,
          errorCode: 'conflict',
          message: 'Item cannot be disabled',
        ));
        return MenuItemBloc(repository: mockRepo);
      },
      seed: () => MenuItemLoaded(items: [_item(id: 'x', isAvailable: true)]),
      act: (bloc) => bloc.add(
        const MenuItemAvailabilityToggled(id: 'x', isAvailable: false),
      ),
      expect: () => [
        // Optimistic update
        isA<MenuItemLoaded>().having(
          (s) => s.items.first.isAvailable,
          'optimistic isAvailable',
          false,
        ),
        // Revert on error
        isA<MenuItemOperationError>()
            .having(
              (s) => s.items.first.isAvailable,
              'reverted isAvailable',
              true,
            )
            .having(
              (s) => s.message,
              'error message',
              'Item cannot be disabled',
            ),
      ],
    );
  });
}
