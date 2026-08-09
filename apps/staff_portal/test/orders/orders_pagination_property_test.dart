// Feature: rms-flutter-frontend, Property 7: Pagination completeness
// Validates: Requirements 9.1, 9.3, 9.4 — 100 iterations

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:models/models.dart';
import 'package:staff_portal/orders/order_bloc.dart';
import 'package:staff_portal/orders/order_repository.dart';

import '../helpers/fast_check.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockOrderRepository extends Mock implements OrderRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a minimal [Order] with the given [id].
Order _order(String id) => Order(
      id: id,
      orderNumber: '#$id',
      orderType: OrderType.dineIn,
      status: OrderStatus.pending,
      items: const [],
      createdAt: DateTime(2024, 1, 1),
      totalAmount: 100.0,
    );

/// Builds a [PaginatedResponse<Order>] for a given [page] in a scenario
/// where [pageSizes] holds the number of orders per page.
PaginatedResponse<Order> _buildPage({
  required int page,
  required List<int> pageSizes,
  required int limit,
}) {
  final total = pageSizes.reduce((a, b) => a + b);
  final pages = pageSizes.length;

  // Compute how many items have already been produced on previous pages.
  int offset = 0;
  for (var i = 0; i < page - 1; i++) {
    offset += pageSizes[i];
  }

  final items = List.generate(
    pageSizes[page - 1],
    (i) => _order('${page}_$i'),
  );

  return PaginatedResponse<Order>(
    data: items,
    pagination: PaginationMeta(
      total: total,
      page: page,
      limit: limit,
      pages: pages,
    ),
  );
}

// ── Arbitraries ───────────────────────────────────────────────────────────────

/// Scenario: a list of page-sizes (2–5 pages, 0–10 items each).
/// The total across all pages equals pagination.total.
typedef _PaginationScenario = List<int>;

final _scenarioArbitrary = Arbitrary<_PaginationScenario>(
  (rng) {
    // Generate between 2 and 5 pages.
    final pageCount = 2 + rng.nextInt(4); // 2..5
    return List.generate(
      pageCount,
      // 0..10 items per page; allow empty pages to test edge cases.
      (_) => rng.nextInt(11),
    );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockOrderRepository mockRepo;

  setUp(() {
    mockRepo = MockOrderRepository();
    // Provide a fallback for the named argument so Mocktail can match calls.
    registerFallbackValue(null);
  });

  // ── Property test ─────────────────────────────────────────────────────────

  group('Property 7 – Pagination completeness (Req 9.1, 9.3, 9.4)', () {
    test(
      'total collected items == pagination.total and no request is made '
      'after hasReachedEnd == true (100 iterations)',
      () async {
        await forAllAsync<_PaginationScenario>(
          _scenarioArbitrary,
          (pageSizes) async {
            final pageCount = pageSizes.length;
            final totalItems = pageSizes.fold(0, (s, n) => s + n);
            const limit = 20;

            // ── Mock setup: returns the correct page on each call ──────────
            // We track which page was last requested via a counter.
            var callCount = 0;

            when(
              () => mockRepo.getOrders(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
                orderType: any(named: 'orderType'),
                status: any(named: 'status'),
              ),
            ).thenAnswer((inv) async {
              callCount++;
              final requestedPage =
                  (inv.namedArguments[const Symbol('page')] as int?) ?? 1;
              // Clamp to valid range to avoid index errors.
              final clampedPage = requestedPage.clamp(1, pageCount);
              return _buildPage(
                page: clampedPage,
                pageSizes: pageSizes,
                limit: limit,
              );
            });

            // ── Drive the BLoC through all pages ──────────────────────────
            final bloc = OrderBloc(repository: mockRepo);

            // 1. Initial load (page 1).
            bloc.add(const OrderListRequested());
            await Future<void>.delayed(const Duration(milliseconds: 50));

            // 2. Keep requesting the next page until hasReachedEnd.
            for (var attempt = 0; attempt < pageCount + 1; attempt++) {
              final current = bloc.state;
              if (current is OrderListLoaded && current.hasReachedEnd) break;
              bloc.add(const OrderNextPageRequested());
              await Future<void>.delayed(const Duration(milliseconds: 50));
            }

            // ── Capture final loaded state ─────────────────────────────────
            final finalState = bloc.state;

            expect(
              finalState,
              isA<OrderListLoaded>(),
              reason: 'Bloc should be in OrderListLoaded state after all pages',
            );

            final loaded = finalState as OrderListLoaded;

            // ── Assert 1: total items == pagination.total (Req 9.1, 9.3) ──
            expect(
              loaded.orders.length,
              equals(totalItems),
              reason: 'Collected ${loaded.orders.length} items but '
                  'pagination.total is $totalItems '
                  '(page sizes: $pageSizes)',
            );

            // The pagination.total field from the first (and latest) response
            // should always match our expected total.
            expect(
              loaded.pagination.total,
              equals(totalItems),
              reason: 'pagination.total should equal sum of all page sizes',
            );

            // ── Assert 2: hasReachedEnd when on last page (Req 9.4) ────────
            expect(
              loaded.hasReachedEnd,
              isTrue,
              reason: 'hasReachedEnd should be true after fetching last page',
            );

            // ── Assert 3: no further requests after last page (Req 9.4) ───
            final callsBeforeExtraRequest = callCount;

            // Attempt an extra OrderNextPageRequested — it must be a no-op.
            bloc.add(const OrderNextPageRequested());
            await Future<void>.delayed(const Duration(milliseconds: 50));

            expect(
              callCount,
              equals(callsBeforeExtraRequest),
              reason: 'getOrders should not be called again after '
                  'hasReachedEnd == true (was called $callsBeforeExtraRequest '
                  'times; page sizes: $pageSizes)',
            );

            await bloc.close();
          },
          iterations: 100,
        );
      },
    );

    // ── Deterministic edge cases ───────────────────────────────────────────

    test(
      'single-item second page: hasReachedEnd true after 2 pages, '
      'orders.length == 2',
      () async {
        // Page 1: 1 item, page 2: 1 item; total = 2.
        final pageSizes = [1, 1];
        const limit = 20;

        when(
          () => mockRepo.getOrders(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            orderType: any(named: 'orderType'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((inv) async {
          final requestedPage =
              (inv.namedArguments[const Symbol('page')] as int?) ?? 1;
          return _buildPage(
            page: requestedPage.clamp(1, 2),
            pageSizes: pageSizes,
            limit: limit,
          );
        });

        final bloc = OrderBloc(repository: mockRepo);

        bloc.add(const OrderListRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(const OrderNextPageRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as OrderListLoaded;
        expect(state.orders.length, equals(2));
        expect(state.hasReachedEnd, isTrue);

        await bloc.close();
      },
    );

    test(
      'all-empty pages: hasReachedEnd true immediately on page 1 '
      'when pages == 1 and total == 0',
      () async {
        when(
          () => mockRepo.getOrders(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            orderType: any(named: 'orderType'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const PaginatedResponse<Order>(
              data: [],
              pagination: PaginationMeta(
                total: 0,
                page: 1,
                limit: 20,
                pages: 1,
              ),
            ));

        final bloc = OrderBloc(repository: mockRepo);

        bloc.add(const OrderListRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as OrderListLoaded;
        expect(state.orders, isEmpty);
        expect(state.pagination.total, equals(0));
        expect(state.hasReachedEnd, isTrue);

        // Extra next-page request must be a no-op.
        final callsBefore = verify(
          () => mockRepo.getOrders(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            orderType: any(named: 'orderType'),
            status: any(named: 'status'),
          ),
        ).callCount;

        bloc.add(const OrderNextPageRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verifyNever(
          () => mockRepo.getOrders(
            page: 2,
            limit: any(named: 'limit'),
            orderType: any(named: 'orderType'),
            status: any(named: 'status'),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'five full pages: total items collected equals sum of page sizes',
      () async {
        final pageSizes = [5, 5, 5, 5, 5];
        const limit = 5;
        final expectedTotal = pageSizes.fold(0, (s, n) => s + n); // 25

        when(
          () => mockRepo.getOrders(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            orderType: any(named: 'orderType'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((inv) async {
          final requestedPage =
              (inv.namedArguments[const Symbol('page')] as int?) ?? 1;
          return _buildPage(
            page: requestedPage.clamp(1, 5),
            pageSizes: pageSizes,
            limit: limit,
          );
        });

        final bloc = OrderBloc(repository: mockRepo);

        // Load all 5 pages.
        bloc.add(const OrderListRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        for (var p = 2; p <= 5; p++) {
          bloc.add(const OrderNextPageRequested());
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        final state = bloc.state as OrderListLoaded;
        expect(state.orders.length, equals(expectedTotal));
        expect(state.pagination.total, equals(expectedTotal));
        expect(state.hasReachedEnd, isTrue);

        await bloc.close();
      },
    );
  });
}
