// Feature: rms-flutter-frontend
// Implements: Requirements 9.1, 9.2, 9.3, 9.4

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:staff_portal/orders/order_bloc.dart';

/// Orders list screen with pagination, filters, and infinite scroll.
///
/// Requirements: 9.1, 9.2, 9.3, 9.4
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
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshOrders();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh whenever this route becomes active (user navigates back)
    final modalRoute = ModalRoute.of(context);
    if (modalRoute?.isCurrent == true) {
      _refreshOrders();
    }
  }

  void _refreshOrders() {
    // Only refresh if we have a loaded state (preserve filters)
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<OrderBloc>().add(
                  const OrderListRequested(),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/orders/create'),
        tooltip: 'New Order',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
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

// ── Filter bar (Req 9.2) ──────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String? _selectedType;
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: AppTheme.cardSurface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown(
              label: 'Type',
              value: _selectedType,
              items: const {
                null: 'All Types',
                'dine_in': 'Dine-in',
                'takeaway': 'Takeaway',
                'delivery': 'Delivery',
              },
              onChanged: (value) {
                setState(() => _selectedType = value);
                // Reset to page 1 on filter change (Req 9.2)
                context.read<OrderBloc>().add(
                      OrderListRequested(
                        orderType: value,
                        status: _selectedStatus,
                      ),
                    );
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: _FilterDropdown(
              label: 'Status',
              value: _selectedStatus,
              items: const {
                null: 'All Statuses',
                'pending': 'Pending',
                'confirmed': 'Confirmed',
                'preparing': 'Preparing',
                'ready': 'Ready',
                'served': 'Served',
                'completed': 'Completed',
              },
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                // Reset to page 1 on filter change (Req 9.2)
                context.read<OrderBloc>().add(
                      OrderListRequested(
                        orderType: _selectedType,
                        status: value,
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String?, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      items: items.entries
          .map(
            (e) => DropdownMenuItem<String?>(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Loading view ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: const [
        LoadingSkeletonCard(height: 88),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 88),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 88),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 88),
      ],
    );
  }
}

// ── Orders list with infinite scroll (Req 9.1, 9.3, 9.4) ─────────────────────

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
      return const _EmptyOrders();
    }

    return Column(
      children: [
        Expanded(
          child: PaginatedListView<Order>(
            items: orders,
            isLoading: isLoadingMore,
            onEndReached: hasReachedEnd
                ? null
                : () {
                    // Load next page when bottom reached (Req 9.3)
                    context
                        .read<OrderBloc>()
                        .add(const OrderNextPageRequested());
                  },
            itemBuilder: (ctx, order) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing4,
              ),
              child: _OrderCard(order: order),
            ),
          ),
        ),
        // Show "No more orders" indicator when last page reached (Req 9.4)
        if (hasReachedEnd)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Text(
              'No more orders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
          ),
      ],
    );
  }
}

// ── Order card (Req 9.1) ──────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => context.go('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Left section: order number + type badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        _TypeBadge(type: order.orderType),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  // Right section: status badge + total amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadgeWidget(status: order.status),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        '₹${order.subtotal.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
              // Items section
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing12),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacing12),
                _OrderItemsList(items: order.items),
              ] else ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'No items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Order items list ──────────────────────────────────────────────────────────

class _OrderItemsList extends StatelessWidget {
  const _OrderItemsList({required this.items});
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    // Calculate total item count
    final totalItemCount = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item count header
        Row(
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 16,
              color: AppTheme.mutedText,
            ),
            const SizedBox(width: AppTheme.spacing4),
            Text(
              '$totalItemCount ${totalItemCount == 1 ? 'item' : 'items'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        // List of items (show first 3, then "and X more")
        ...items.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}×',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        item.itemName,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${item.itemTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        // Show "and X more" if there are more than 3 items
        if (items.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing4),
            child: Text(
              'and ${items.length - 3} more ${items.length - 3 == 1 ? 'item' : 'items'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
      ],
    );
  }
}

// ── Type badge (Req 9.1) ──────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final OrderType type;

  static const _labels = {
    OrderType.dineIn: 'Dine-in',
    OrderType.takeaway: 'Takeaway',
    OrderType.delivery: 'Delivery',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        _labels[type] ?? type.jsonValue,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.mutedText,
        ),
      ),
    );
  }
}

// ── Status badge (Req 9.1) ────────────────────────────────────────────────────

class _StatusBadgeWidget extends StatelessWidget {
  const _StatusBadgeWidget({required this.status});
  final OrderStatus status;

  static const _labels = {
    OrderStatus.pending: 'Pending',
    OrderStatus.confirmed: 'Confirmed',
    OrderStatus.preparing: 'Preparing',
    OrderStatus.ready: 'Ready',
    OrderStatus.served: 'Served',
    OrderStatus.completed: 'Completed',
  };

  static const _colors = {
    OrderStatus.pending: AppColors.orderPending,
    OrderStatus.confirmed: AppColors.orderConfirmed,
    OrderStatus.preparing: AppColors.orderPreparing,
    OrderStatus.ready: AppColors.orderReady,
    OrderStatus.served: AppColors.orderServed,
    OrderStatus.completed: AppColors.orderCompleted,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppTheme.mutedText;
    final label = _labels[status] ?? status.jsonValue;
    return StatusBadge(label: label, color: color);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 64, color: AppTheme.mutedText),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No orders found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Orders will appear here once placed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
