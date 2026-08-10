// Feature: rms-flutter-frontend
// Implements: Requirements 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 17.4, 17.5

import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/kds/kds_bloc.dart';
import 'package:staff_portal/kds/kitchen_history_bloc.dart';

/// Label for dine-in table context on KDS order cards.
String? kdsTableLabel(KdsOrder order) {
  if (order.orderType != OrderType.dineIn) return null;
  final tableNum = order.tableNumber;
  if (tableNum != null) {
    final section = order.sectionLabel?.trim();
    if (section != null && section.isNotEmpty) {
      return 'Table $tableNum · $section';
    }
    return 'Table $tableNum';
  }
  if (order.tableId != null) return 'Table assigned';
  return null;
}

/// KDS (Kitchen Display System) screen
/// elapsed time, status badges, and overdue indicators.
class KdsScreen extends StatelessWidget {
  const KdsScreen({super.key});

  static const stationId = 'default';

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => KdsBloc(repository: ctx.read())
            ..add(const KdsFeedRequested(stationId)),
        ),
        BlocProvider(
          create: (ctx) => KitchenHistoryBloc(repository: ctx.read()),
        ),
      ],
      child: const _KdsView(),
    );
  }
}

// â”€â”€ Main view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KdsView extends StatefulWidget {
  const _KdsView();

  @override
  State<_KdsView> createState() => _KdsViewState();
}

class _KdsViewState extends State<_KdsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      context
          .read<KitchenHistoryBloc>()
          .add(const KitchenHistoryLoadRequested(KdsScreen.stationId));
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      context.read<KdsBloc>().add(const KdsFeedRequested(KdsScreen.stationId));
    } else {
      context
          .read<KitchenHistoryBloc>()
          .add(const KitchenHistoryLoadRequested(KdsScreen.stationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<KdsBloc, KdsState>(
      listenWhen: (_, current) => current is KdsItemUpdateError,
      listener: (context, state) {
        if (state is KdsItemUpdateError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 3),
              backgroundColor: AppTheme.error,
            ));
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Kitchen Display'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refreshCurrentTab,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ActiveFeedTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _ActiveFeedTab extends StatelessWidget {
  const _ActiveFeedTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KdsBloc, KdsState>(
      builder: (context, state) => switch (state) {
        KdsInitial() || KdsLoading() => const _LoadingView(),
        KdsFeedLoaded(:final orders, :final pollingError) =>
          _FeedView(orders: orders, pollingError: pollingError),
        KdsItemUpdateError(:final orders) =>
          _FeedView(orders: orders, pollingError: false),
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KitchenHistoryBloc, KitchenHistoryState>(
      builder: (context, state) {
        return switch (state) {
          KitchenHistoryInitial() || KitchenHistoryLoading() =>
            const _LoadingView(),
          KitchenHistoryLoaded(:final orders) => orders.isEmpty
              ? const _HistoryEmptyView()
              : _HistoryOrderList(orders: orders),
          KitchenHistoryError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 40, color: AppTheme.mutedText),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.read<KitchenHistoryBloc>().add(
                            const KitchenHistoryLoadRequested(
                                KdsScreen.stationId),
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        };
      },
    );
  }
}

// â”€â”€ Loading view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: const [
        LoadingSkeletonCard(height: 200),
        SizedBox(height: AppTheme.spacing12),
        LoadingSkeletonCard(height: 200),
      ],
    );
  }
}

// â”€â”€ Feed view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FeedView extends StatelessWidget {
  const _FeedView({required this.orders, required this.pollingError});

  final List<KdsOrder> orders;
  final bool pollingError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (pollingError) const _PollingErrorBanner(),
        Expanded(
          child: orders.isEmpty
              ? const _EmptyKds()
              : _KdsOrderList(orders: orders),
        ),
      ],
    );
  }
}

// â”€â”€ Polling error banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PollingErrorBanner extends StatelessWidget {
  const _PollingErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      color: AppTheme.warningContainer,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppTheme.warning, size: 18),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              'Live updates paused â€” displaying last known data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.warning, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Scrollable list of order cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KdsOrderList extends StatelessWidget {
  const _KdsOrderList({required this.orders});
  final List<KdsOrder> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
      itemBuilder: (ctx, i) => _KdsOrderCard(order: orders[i]),
    );
  }
}

// â”€â”€ Order card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KdsOrderCard extends StatefulWidget {
  const _KdsOrderCard({required this.order});
  final KdsOrder order;

  @override
  State<_KdsOrderCard> createState() => _KdsOrderCardState();
}

class _KdsOrderCardState extends State<_KdsOrderCard> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = _computeElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _elapsed = _computeElapsed()));
  }

  Duration _computeElapsed() =>
      DateTime.now().difference(widget.order.orderCreatedAt);

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool get _isOverdue =>
      widget.order.items.any((i) => i.isOverdue) || _elapsed.inMinutes >= 10;

  @override
  Widget build(BuildContext context) {
    final isOverdue = _isOverdue;
    final order = widget.order;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isOverdue ? AppTheme.error : AppTheme.border,
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _OrderCardHeader(
            order: order,
            elapsed: _elapsed,
            isOverdue: isOverdue,
          ),

          // â”€â”€ Items â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          ...order.items.map((item) => _KdsItemRow(
                item: item,
                orderId: order.orderId,
                isLast: item == order.items.last,
              )),
        ],
      ),
    );
  }
}

// â”€â”€ Order card header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OrderCardHeader extends StatelessWidget {
  const _OrderCardHeader({
    required this.order,
    required this.elapsed,
    required this.isOverdue,
  });

  final KdsOrder order;
  final Duration elapsed;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final headerBg = isOverdue
        ? AppTheme.error.withValues(alpha: 0.08)
        : AppTheme.surfaceVariant;

    final orderLabel = switch (order.orderType) {
      OrderType.dineIn => 'Dine-in',
      OrderType.takeaway => 'Takeaway',
      OrderType.delivery => 'Delivery',
    };

    final statusLabel = switch (order.orderStatus) {
      OrderStatus.pending => 'Pending',
      OrderStatus.confirmed => 'Confirmed',
      OrderStatus.preparing => 'Preparing',
      OrderStatus.ready => 'Ready',
      OrderStatus.served => 'Served',
      OrderStatus.completed => 'Completed',
      OrderStatus.cancelled => 'Cancelled',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusCard - 1),
        ),
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Order ID + type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.orderId.substring(0, 8).toUpperCase()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isOverdue ? AppTheme.error : AppTheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _HeaderChip(label: orderLabel),
                    const SizedBox(width: AppTheme.spacing4),
                    _HeaderChip(label: statusLabel, isStatus: true),
                  ],
                ),
                if (kdsTableLabel(order) != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.table_restaurant_outlined,
                        size: 14,
                        color: isOverdue ? AppTheme.error : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kdsTableLabel(order)!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isOverdue
                                  ? AppTheme.error
                                  : AppTheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Elapsed time + overdue
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ElapsedLabel(elapsed: elapsed, isOverdue: isOverdue),
              if (isOverdue) ...[
                const SizedBox(height: 2),
                const _OverdueBadge(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, this.isStatus = false});
  final String label;
  final bool isStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isStatus
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isStatus ? AppTheme.primary : AppTheme.mutedText,
        ),
      ),
    );
  }
}

// â”€â”€ Item row inside a card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KdsItemRow extends StatelessWidget {
  const _KdsItemRow({
    required this.item,
    required this.orderId,
    required this.isLast,
  });

  final KdsItem item;
  final String orderId;
  final bool isLast;

  Color _statusColor() => switch (item.kdsStatus) {
        KdsItemStatus.queued => AppColors.kdsQueued,
        KdsItemStatus.started => AppColors.kdsStarted,
        KdsItemStatus.done => AppTheme.success,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Status colour strip
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusCard - 1))
                  : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),

          // Qty badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),

          // Item name
          Expanded(
            child: Text(
              item.itemName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status badge + action button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _KdsStatusBadge(status: item.kdsStatus),
                const SizedBox(width: AppTheme.spacing8),
                _KdsActionButton(item: item, orderId: orderId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Elapsed time label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ElapsedLabel extends StatelessWidget {
  const _ElapsedLabel({required this.elapsed, this.isOverdue = false});

  final Duration elapsed;
  final bool isOverdue;

  String _format(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(elapsed),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isOverdue ? AppTheme.error : AppTheme.mutedText,
            fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
          ),
    );
  }
}

// â”€â”€ Overdue badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Overdue',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.error),
      ),
    );
  }
}

// â”€â”€ KDS status badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KdsStatusBadge extends StatelessWidget {
  const _KdsStatusBadge({required this.status});
  final KdsItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      KdsItemStatus.queued => ('Queued', AppColors.kdsQueued),
      KdsItemStatus.started => ('In Progress', AppColors.kdsStarted),
      KdsItemStatus.done => ('Done', AppTheme.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// â”€â”€ Action button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KdsActionButton extends StatelessWidget {
  const _KdsActionButton({required this.item, required this.orderId});
  final KdsItem item;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return switch (item.kdsStatus) {
      KdsItemStatus.queued => _ActionBtn(
          label: 'Start',
          color: AppTheme.primary,
          onPressed: () => context.read<KdsBloc>().add(
                KdsItemStatusUpdateRequested(
                  itemId: item.id,
                  orderId: orderId,
                  status: KdsItemStatus.started,
                ),
              ),
        ),
      KdsItemStatus.started => _ActionBtn(
          label: 'Done',
          color: AppColors.kdsStarted,
          onPressed: () => context.read<KdsBloc>().add(
                KdsItemStatusUpdateRequested(
                  itemId: item.id,
                  orderId: orderId,
                  status: KdsItemStatus.done,
                ),
              ),
        ),
      KdsItemStatus.done => const SizedBox.shrink(),
    };
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.label, required this.color, required this.onPressed});
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppTheme.onPrimary,
          minimumSize: const Size(64, 32),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

// â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyKds extends StatelessWidget {
  const _EmptyKds();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu,
                size: 64, color: AppTheme.mutedText),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No active orders',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Items will appear here when orders are placed',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Kitchen history (completed orders) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HistoryEmptyView extends StatelessWidget {
  const _HistoryEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: AppTheme.mutedText),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No kitchen history yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Orders you complete in KDS will appear here',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryOrderList extends StatelessWidget {
  const _HistoryOrderList({required this.orders});
  final List<KdsOrder> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
      itemBuilder: (ctx, i) => _HistoryOrderCard(order: orders[i]),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  const _HistoryOrderCard({required this.order});
  final KdsOrder order;

  @override
  Widget build(BuildContext context) {
    final orderLabel = switch (order.orderType) {
      OrderType.dineIn => 'Dine-in',
      OrderType.takeaway => 'Takeaway',
      OrderType.delivery => 'Delivery',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderId.substring(0, 8).toUpperCase()}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderLabel,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.mutedText),
                      ),
                      if (kdsTableLabel(order) != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.table_restaurant_outlined,
                              size: 13,
                              color: AppTheme.mutedText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              kdsTableLabel(order)!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  _formatDate(order.orderCreatedAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.itemName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  _KdsStatusBadge(status: item.kdsStatus),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
