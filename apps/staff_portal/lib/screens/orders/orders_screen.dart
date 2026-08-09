// Feature: rms-flutter-frontend
// Implements: Requirements 9.1, 9.2, 9.3, 9.4

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:staff_portal/orders/order_bloc.dart';
import 'package:staff_portal/orders/order_design.dart';

/// Orders list screen with pagination, filters, and infinite scroll.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderBloc>(
      create: (ctx) =>
          OrderBloc(repository: ctx.read())..add(const OrderListRequested()),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOrders();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute?.isCurrent == true) {
      _refreshOrders();
    }
  }

  void _refreshOrders() {
    final bloc = context.read<OrderBloc>();
    final currentState = bloc.state;
    if (currentState is OrderListLoaded) {
      bloc.add(OrderListRequested(
        orderType: currentState.orderType,
        status: currentState.status,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: orderBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OrdersPageHeader(),
          const _FilterBar(),
          Expanded(
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                return switch (state) {
                  OrderInitial() || OrderLoading() => const _LoadingView(),
                  OrderListLoaded(
                    :final orders,
                    :final isLoadingMore,
                    :final hasReachedEnd
                  ) =>
                    _OrdersList(
                      orders: orders,
                      isLoadingMore: isLoadingMore,
                      hasReachedEnd: hasReachedEnd,
                    ),
                  OrderError(:final message) => ErrorStateWidget(
                      message: message,
                      onRetry: () => context
                          .read<OrderBloc>()
                          .add(const OrderListRequested()),
                    ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _OrdersPageHeader extends StatelessWidget {
  const _OrdersPageHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        final orders = switch (state) {
          OrderListLoaded(:final orders) => orders,
          _ => <Order>[],
        };

        final active = orders
            .where((o) =>
                o.status != OrderStatus.completed &&
                o.status != OrderStatus.cancelled)
            .length;
        final value = orders.fold<double>(0, (s, o) => s + o.subtotal);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: orderTitle,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Track and manage live orders',
                          style: TextStyle(fontSize: 12.5, color: orderMuted),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<OrderBloc>()
                            .add(const OrderListRequested()),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: orderTitle,
                          side: const BorderSide(color: orderBorder),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.go('/orders/create'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New order'),
                        style: FilledButton.styleFrom(
                          backgroundColor: orderAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OrderStatCard(
                      label: 'On this page',
                      value: '${orders.length}',
                      icon: Icons.list_alt,
                      accent: orderAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OrderStatCard(
                      label: 'Active',
                      value: '$active',
                      icon: Icons.bolt_outlined,
                      accent: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OrderStatCard(
                      label: 'Page value',
                      value: '₹${value.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      accent: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String? _selectedType;
  String? _selectedStatus;

  void _applyType(String? type) {
    setState(() => _selectedType = type);
    context.read<OrderBloc>().add(
          OrderListRequested(
            orderType: type,
            status: _selectedStatus,
          ),
        );
  }

  void _applyStatus(String? status) {
    setState(() => _selectedStatus = status);
    context.read<OrderBloc>().add(
          OrderListRequested(
            orderType: _selectedType,
            status: status,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: orderMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OrderChoiceChip(
                label: 'All',
                selected: _selectedType == null,
                onTap: () => _applyType(null),
              ),
              OrderChoiceChip(
                label: 'Dine-in',
                selected: _selectedType == 'dine_in',
                onTap: () => _applyType('dine_in'),
              ),
              OrderChoiceChip(
                label: 'Takeaway',
                selected: _selectedType == 'takeaway',
                onTap: () => _applyType('takeaway'),
              ),
              OrderChoiceChip(
                label: 'Delivery',
                selected: _selectedType == 'delivery',
                onTap: () => _applyType('delivery'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: orderMuted,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OrderChoiceChip(
                  label: 'All',
                  selected: _selectedStatus == null,
                  onTap: () => _applyStatus(null),
                ),
                const SizedBox(width: 8),
                ..._statusFilters.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OrderChoiceChip(
                      label: f.label,
                      selected: _selectedStatus == f.value,
                      onTap: () => _applyStatus(f.value),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilter {
  const _StatusFilter(this.label, this.value);
  final String label;
  final String value;
}

const _statusFilters = [
  _StatusFilter('Pending', 'pending'),
  _StatusFilter('Confirmed', 'confirmed'),
  _StatusFilter('Preparing', 'preparing'),
  _StatusFilter('Ready', 'ready'),
  _StatusFilter('Served', 'served'),
  _StatusFilter('Completed', 'completed'),
];

// ── Loading view ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: const [
        LoadingSkeletonCard(height: 72),
        SizedBox(height: 10),
        LoadingSkeletonCard(height: 72),
        SizedBox(height: 10),
        LoadingSkeletonCard(height: 72),
        SizedBox(height: 10),
        LoadingSkeletonCard(height: 72),
      ],
    );
  }
}

// ── Orders list ───────────────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.isLoadingMore,
    required this.hasReachedEnd,
  });

  final List<Order> orders;
  final bool isLoadingMore;
  final bool hasReachedEnd;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const OrderEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: PaginatedListView<Order>(
            items: orders,
            isLoading: isLoadingMore,
            onEndReached: hasReachedEnd
                ? null
                : () => context
                    .read<OrderBloc>()
                    .add(const OrderNextPageRequested()),
            itemBuilder: (ctx, order) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: OrderListTile(
                order: order,
                onTap: () => context.go('/orders/${order.id}'),
              ),
            ),
          ),
        ),
        if (hasReachedEnd)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No more orders',
              style: TextStyle(fontSize: 12, color: orderMuted),
            ),
          ),
      ],
    );
  }
}
