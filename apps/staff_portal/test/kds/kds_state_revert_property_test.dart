// Feature: rms-flutter-frontend, Property 5: State revert on API failure
// Validates: Requirements 10.5 — 100 iterations

import 'dart:math';

import 'package:api_client/api_client.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:models/models.dart';
import 'package:staff_portal/kds/kds_bloc.dart';
import 'package:staff_portal/kds/kds_repository.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockKdsRepository extends Mock implements KdsRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a [KdsItem] with the given [orderItemId] and [status].
KdsItem _kdsItem({
  required String orderItemId,
  required KdsItemStatus status,
}) =>
    KdsItem(
      orderItemId: orderItemId,
      orderId: 'order-1',
      orderNumber: '#1001',
      itemName: 'Margherita Pizza',
      quantity: 1,
      status: status,
      stationId: 'station-1',
      createdAt: DateTime(2024, 1, 1, 12, 0),
    );

// ── Arbitraries ───────────────────────────────────────────────────────────────

/// Pick a random [KdsItemStatus] from the non-done statuses (queued / started).
KdsItemStatus _randomInitialStatus(Random rng) =>
    rng.nextBool() ? KdsItemStatus.queued : KdsItemStatus.started;

/// Generate a list of 1–5 [KdsItem]s with random statuses.
List<KdsItem> _randomItemList(Random rng) {
  final count = 1 + rng.nextInt(5); // 1..5
  return List.generate(
    count,
    (i) => _kdsItem(
      orderItemId: 'item-$i',
      status: _randomInitialStatus(rng),
    ),
  );
}

/// Non-empty printable ASCII string (length 4–60).
String _randomErrorMessage(Random rng) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _-';
  final len = 4 + rng.nextInt(57); // 4..60
  return String.fromCharCodes(
    List.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockKdsRepository mockRepo;

  setUp(() {
    mockRepo = MockKdsRepository();
    // Fallback stub — overridden per iteration.
    registerFallbackValue(KdsItemStatus.queued);
  });

  group(
      'Property 5 – State revert on API failure: KDS status update (Req 10.5)',
      () {
    test(
      'item status reverts to original and KdsItemUpdateError.message is '
      'non-empty for any initial feed and any API error (100 iterations)',
      () async {
        final rng = Random(42);

        for (var i = 0; i < 100; i++) {
          // ── Generate arbitrary inputs ───────────────────────────────────
          final initialItems = _randomItemList(rng);
          final pickedIndex = rng.nextInt(initialItems.length);
          final pickedItem = initialItems[pickedIndex];
          final originalStatus = pickedItem.status;

          // Pick a *different* status to attempt the update with.
          final newStatus = originalStatus == KdsItemStatus.queued
              ? KdsItemStatus.started
              : KdsItemStatus.queued;

          final errorMessage = _randomErrorMessage(rng);

          // ── Configure mocks ─────────────────────────────────────────────
          when(() => mockRepo.getStationFeed(any()))
              .thenAnswer((_) async => initialItems);

          when(() => mockRepo.updateKdsItemStatus(
                pickedItem.orderItemId,
                newStatus,
              )).thenThrow(ApiException(
            statusCode: 500,
            errorCode: 'error',
            message: errorMessage,
          ));

          // ── Build bloc and seed with initial feed ───────────────────────
          final bloc = KdsBloc(repository: mockRepo);

          // Collect all states from the bloc stream.
          final allStates = <KdsState>[];
          final subscription = bloc.stream.listen(allStates.add);

          // Seed with initial feed
          bloc.add(const KdsFeedRequested('station-1'));
          // Wait for async operations to settle
          await Future<void>.delayed(const Duration(milliseconds: 50));

          // ── Dispatch the failing status update ──────────────────────────
          bloc.add(KdsItemStatusUpdateRequested(
            orderItemId: pickedItem.orderItemId,
            status: newStatus,
          ));

          // Wait for the status update + revert to complete
          await Future<void>.delayed(const Duration(milliseconds: 50));

          await subscription.cancel();
          await bloc.close();

          // Extract only the states after the feed was loaded
          // (skip KdsLoading and initial KdsFeedLoaded)
          final feedLoadedIndex =
              allStates.indexWhere((s) => s is KdsFeedLoaded);
          final states = feedLoadedIndex >= 0
              ? allStates.sublist(feedLoadedIndex + 1)
              : allStates;

          // ── Assert optimistic update was applied ────────────────────────
          if (states.isNotEmpty && states.first is KdsFeedLoaded) {
            final optimisticItem = (states.first as KdsFeedLoaded)
                .items
                .firstWhere((it) => it.orderItemId == pickedItem.orderItemId);
            expect(
              optimisticItem.status,
              equals(newStatus),
              reason: 'Iteration $i: optimistic update should set new status',
            );
          }

          // ── Assert KdsItemUpdateError emitted with reverted state ────────
          expect(
            states.length,
            greaterThanOrEqualTo(2),
            reason: 'Iteration $i: expected at least 2 states '
                '(optimistic + error revert)',
          );

          final errorState = states[1];
          expect(
            errorState,
            isA<KdsItemUpdateError>(),
            reason: 'Iteration $i: second state must be KdsItemUpdateError',
          );

          final kdsError = errorState as KdsItemUpdateError;

          // Item retains ORIGINAL status (reverted)
          final revertedItem = kdsError.items
              .firstWhere((it) => it.orderItemId == pickedItem.orderItemId);
          expect(
            revertedItem.status,
            equals(originalStatus),
            reason: 'Iteration $i: item status must revert to $originalStatus '
                '(attempted $newStatus)',
          );

          // Error message is non-empty
          expect(
            kdsError.message.isNotEmpty,
            isTrue,
            reason: 'Iteration $i: KdsItemUpdateError.message must be '
                'non-empty',
          );
        }
      },
    );

    // ── Deterministic edge cases ──────────────────────────────────────────

    group('deterministic edge cases', () {
      blocTest<KdsBloc, KdsState>(
        'emits [optimistic KdsFeedLoaded, KdsItemUpdateError] '
        'when updateKdsItemStatus throws ApiException — queued→started',
        build: () {
          final items = [
            _kdsItem(orderItemId: 'a', status: KdsItemStatus.queued)
          ];
          when(() => mockRepo.getStationFeed(any()))
              .thenAnswer((_) async => items);
          when(() => mockRepo.updateKdsItemStatus('a', KdsItemStatus.started))
              .thenThrow(const ApiException(
            statusCode: 500,
            errorCode: 'error',
            message: 'Server error',
          ));
          return KdsBloc(repository: mockRepo);
        },
        seed: () => KdsFeedLoaded(
          items: [_kdsItem(orderItemId: 'a', status: KdsItemStatus.queued)],
        ),
        act: (bloc) => bloc.add(const KdsItemStatusUpdateRequested(
          orderItemId: 'a',
          status: KdsItemStatus.started,
        )),
        expect: () => [
          // Optimistic update: status flipped to started
          isA<KdsFeedLoaded>().having(
            (s) => s.items.first.status,
            'optimistic status',
            KdsItemStatus.started,
          ),
          // Revert on error: status back to queued with non-empty message
          isA<KdsItemUpdateError>()
              .having(
                (s) => s.items.first.status,
                'reverted status',
                KdsItemStatus.queued,
              )
              .having(
                (s) => s.message.isNotEmpty,
                'non-empty message',
                isTrue,
              ),
        ],
      );

      blocTest<KdsBloc, KdsState>(
        'emits [optimistic KdsFeedLoaded, KdsItemUpdateError] '
        'when updateKdsItemStatus throws ApiException — started→queued',
        build: () {
          final items = [
            _kdsItem(orderItemId: 'b', status: KdsItemStatus.started)
          ];
          when(() => mockRepo.getStationFeed(any()))
              .thenAnswer((_) async => items);
          when(() => mockRepo.updateKdsItemStatus('b', KdsItemStatus.queued))
              .thenThrow(const ApiException(
            statusCode: 422,
            errorCode: 'invalid_transition',
            message: 'Cannot revert status',
          ));
          return KdsBloc(repository: mockRepo);
        },
        seed: () => KdsFeedLoaded(
          items: [_kdsItem(orderItemId: 'b', status: KdsItemStatus.started)],
        ),
        act: (bloc) => bloc.add(const KdsItemStatusUpdateRequested(
          orderItemId: 'b',
          status: KdsItemStatus.queued,
        )),
        expect: () => [
          isA<KdsFeedLoaded>().having(
            (s) => s.items.first.status,
            'optimistic status',
            KdsItemStatus.queued,
          ),
          isA<KdsItemUpdateError>()
              .having(
                (s) => s.items.first.status,
                'reverted status',
                KdsItemStatus.started,
              )
              .having(
                (s) => s.message,
                'error message',
                'Cannot revert status',
              ),
        ],
      );

      blocTest<KdsBloc, KdsState>(
        'preserves all other items unchanged when one item update fails',
        build: () {
          final items = [
            _kdsItem(orderItemId: 'x', status: KdsItemStatus.queued),
            _kdsItem(orderItemId: 'y', status: KdsItemStatus.started),
          ];
          when(() => mockRepo.getStationFeed(any()))
              .thenAnswer((_) async => items);
          when(() => mockRepo.updateKdsItemStatus('x', KdsItemStatus.started))
              .thenThrow(const ApiException(
            statusCode: 500,
            errorCode: 'error',
            message: 'Server error',
          ));
          return KdsBloc(repository: mockRepo);
        },
        seed: () => KdsFeedLoaded(items: [
          _kdsItem(orderItemId: 'x', status: KdsItemStatus.queued),
          _kdsItem(orderItemId: 'y', status: KdsItemStatus.started),
        ]),
        act: (bloc) => bloc.add(const KdsItemStatusUpdateRequested(
          orderItemId: 'x',
          status: KdsItemStatus.started,
        )),
        expect: () => [
          // Optimistic
          isA<KdsFeedLoaded>(),
          // Error revert — both items at original statuses
          isA<KdsItemUpdateError>().having(
            (s) => s.items.map((i) => i.status).toList(),
            'all items statuses reverted',
            [KdsItemStatus.queued, KdsItemStatus.started],
          ),
        ],
      );
    });
  });
}
