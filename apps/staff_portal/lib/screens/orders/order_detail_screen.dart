// Feature: rms-flutter-frontend
// Implements: Requirements 9.7, 9.8, 9.9

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/orders/order_bloc.dart';
import 'package:staff_portal/orders/order_design.dart';
import 'package:staff_portal/orders/order_repository.dart';

/// Order Detail screen — shows all items, status badge, and transition buttons.
///
/// Requirements: 9.7, 9.8, 9.9
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderBloc>(
      create: (ctx) => OrderBloc(repository: ctx.read<OrderRepository>())
        ..add(OrderDetailRequested(orderId)),
      child: _OrderDetailView(orderId: orderId),
    );
  }
}

// ── Main view (StatefulWidget to track last order + updating flag) ────────────

class _OrderDetailView extends StatefulWidget {
  const _OrderDetailView({required this.orderId});

  final String orderId;

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<_OrderDetailView> {
  /// Keeps the last successfully loaded order so the UI does not blank out
  /// when an [OrderOperationError] is emitted (Req 9.8).
  Order? _lastOrder;

  /// True while a status-update request is in-flight; disables buttons (Req 9.7).
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderDetailLoaded) {
          // Successful load or status update — update cached order and clear flag.
          setState(() {
            _lastOrder = state.order;
            _isUpdating = false;
          });
        } else if (state is OrderOperationError) {
          // Status-update failed — clear updating flag, show snack-bar (Req 9.8).
          setState(() => _isUpdating = false);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
        } else if (state is OrderLoading) {
          // Disable buttons while any loading is in progress.
          setState(() => _isUpdating = true);
        }
      },
      builder: (context, state) {
        // ── Loading state ────────────────────────────────────────────────────
        if (state is OrderLoading && _lastOrder == null) {
          return Scaffold(
            backgroundColor: orderBg,
            body: Column(
              children: [
                _OrderDetailHeader(
                  orderId: widget.orderId,
                  isUpdating: true,
                  onRefresh: null,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: const [
                      LoadingSkeletonCard(height: 120),
                      SizedBox(height: 12),
                      LoadingSkeletonCard(height: 200),
                      SizedBox(height: 12),
                      LoadingSkeletonCard(height: 88),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ── Error state (no cached order) ────────────────────────────────────
        if (state is OrderError && _lastOrder == null) {
          return Scaffold(
            backgroundColor: orderBg,
            body: Column(
              children: [
                _OrderDetailHeader(
                  orderId: widget.orderId,
                  isUpdating: false,
                  onRefresh: () => context
                      .read<OrderBloc>()
                      .add(OrderDetailRequested(widget.orderId)),
                ),
                Expanded(
                  child: ErrorStateWidget(
                    message: state.message,
                    onRetry: () => context
                        .read<OrderBloc>()
                        .add(OrderDetailRequested(widget.orderId)),
                  ),
                ),
              ],
            ),
          );
        }

        // ── Determine the order to display ───────────────────────────────────
        final Order? order =
            (state is OrderDetailLoaded) ? state.order : _lastOrder;

        if (order == null) {
          return Scaffold(
            backgroundColor: orderBg,
            body: const Center(
              child: CircularProgressIndicator(color: orderAccent),
            ),
          );
        }

        // ── Full detail view ─────────────────────────────────────────────────
        return Scaffold(
          backgroundColor: orderBg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrderDetailHeader(
                orderId: order.id,
                status: order.status,
                isUpdating: _isUpdating,
                onRefresh: _isUpdating
                    ? null
                    : () => context
                        .read<OrderBloc>()
                        .add(OrderDetailRequested(widget.orderId)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MetadataCard(order: order),
                      const SizedBox(height: 16),
                      _ItemsCard(order: order),
                      const SizedBox(height: 16),
                      _StatusTransitionSection(
                        order: order,
                        isUpdating: _isUpdating,
                        onStatusRequested: (newStatus) {
                          setState(() => _isUpdating = true);
                          context.read<OrderBloc>().add(
                                OrderStatusUpdateRequested(
                                  id: order.id,
                                  status: newStatus,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _OrderDetailHeader extends StatelessWidget {
  const _OrderDetailHeader({
    required this.orderId,
    this.status,
    required this.isUpdating,
    required this.onRefresh,
  });

  final String orderId;
  final OrderStatus? status;
  final bool isUpdating;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Back to orders',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: orderTitle),
            style: IconButton.styleFrom(
              backgroundColor: orderCard,
              side: const BorderSide(color: orderBorder),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$shortId',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: orderTitle,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Order details and status',
                      style: TextStyle(fontSize: 12.5, color: orderMuted),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 10),
                      OrderStatusBadge(status: status!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            OutlinedButton.icon(
              onPressed: isUpdating ? null : onRefresh,
              icon: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: orderAccent,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: orderTitle,
                side: const BorderSide(color: orderBorder),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Metadata card (Req 9.9) ───────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return OrderSectionCard(
      title: 'Order info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OrderTypeBadge(type: order.orderType),
              const SizedBox(width: 8),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Created',
            value: _formatDateTime(order.createdAt),
          ),
          if (order.tableId != null && order.orderType == OrderType.dineIn)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InfoRow(
                label: 'Table',
                value: _formatTableLabel(order),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTableLabel(Order order) {
    final number = order.tableNumber?.trim();
    if (number != null && number.isNotEmpty) {
      return 'Table $number';
    }
    return order.tableId ?? '—';
  }

  /// Formats a [DateTime] as "dd MMM yyyy, HH:mm" without requiring intl.
  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = months[d.month - 1];
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$min';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: orderMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: orderTitle,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Items card (Req 9.9) ──────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return OrderSectionCard(
      title: 'Items (${order.items.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: orderDivider),
          const SizedBox(height: 8),
          ...order.items.map((item) => _OrderItemRow(item: item)),
          const Divider(height: 1, color: orderDivider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: orderTitle,
                ),
              ),
              Text(
                '₹${order.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: orderAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: orderAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: orderAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: orderTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(2)} each',
                  style: const TextStyle(fontSize: 12, color: orderMuted),
                ),
                if (item.variantId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Variant: ${item.variantId}',
                    style: const TextStyle(fontSize: 11, color: orderMuted),
                  ),
                ],
                if (item.modifierIds.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Modifiers: ${item.modifierIds.join(', ')}',
                    style: const TextStyle(fontSize: 11, color: orderMuted),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹${item.itemTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: orderTitle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status-transition section (Req 9.7, 9.8) ─────────────────────────────────

/// The next valid statuses for each current status.
const _statusTransitions = <OrderStatus, List<OrderStatus>>{
  OrderStatus.pending: [OrderStatus.confirmed],
  OrderStatus.confirmed: [], // preparing is triggered by KDS only
  OrderStatus.preparing: [OrderStatus.ready],
  OrderStatus.ready: [OrderStatus.served, OrderStatus.completed],
  OrderStatus.served: [OrderStatus.completed],
  OrderStatus.completed: [],
  OrderStatus.cancelled: [],
};

const _statusLabels = <OrderStatus, String>{
  OrderStatus.pending: 'Pending',
  OrderStatus.confirmed: 'Confirmed',
  OrderStatus.preparing: 'Preparing',
  OrderStatus.ready: 'Ready',
  OrderStatus.served: 'Served',
  OrderStatus.completed: 'Completed',
  OrderStatus.cancelled: 'Cancelled',
};

/// Statuses from which an order can still be cancelled.
const _cancellableStatuses = {
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.preparing,
};

class _StatusTransitionSection extends StatelessWidget {
  const _StatusTransitionSection({
    required this.order,
    required this.isUpdating,
    required this.onStatusRequested,
  });

  final Order order;
  final bool isUpdating;
  final ValueChanged<OrderStatus> onStatusRequested;

  Future<void> _showCancelDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Customer request',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (confirmed == true && context.mounted) {
      context.read<OrderBloc>().add(OrderCancelRequested(
            id: order.id,
            reason:
                reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextStatuses = _statusTransitions[order.status] ?? [];
    final canCancel = _cancellableStatuses.contains(order.status);

    // Terminal state — nothing more to do
    if (nextStatuses.isEmpty && !canCancel) {
      return OrderSectionCard(
        child: Row(
          children: [
            Icon(
              order.status == OrderStatus.cancelled
                  ? Icons.cancel_outlined
                  : order.status == OrderStatus.served
                      ? Icons.receipt_long_outlined
                      : order.status == OrderStatus.confirmed
                          ? Icons.kitchen_outlined
                          : Icons.check_circle,
              color: order.status == OrderStatus.cancelled
                  ? AppTheme.error
                  : order.status == OrderStatus.served
                      ? orderAccent
                      : order.status == OrderStatus.confirmed
                          ? AppTheme.warning
                          : AppTheme.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                order.status == OrderStatus.cancelled
                    ? 'Order cancelled.'
                    : order.status == OrderStatus.served
                        ? 'Order served — mark complete when guests have finished.'
                        : order.status == OrderStatus.confirmed
                            ? 'Order confirmed — kitchen will pick this up from the KDS.'
                            : 'Order completed.',
                style: const TextStyle(fontSize: 13, color: orderMuted),
              ),
            ),
          ],
        ),
      );
    }

    return OrderSectionCard(
      title: 'Update status',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...nextStatuses.map((nextStatus) => _StatusButton(
                label:
                    'Mark as ${_statusLabels[nextStatus] ?? nextStatus.jsonValue}',
                isLoading: isUpdating,
                onPressed: isUpdating
                    ? null
                    : () => onStatusRequested(nextStatus),
              )),
          if (canCancel)
            _StatusButton(
              label: 'Cancel order',
              isLoading: isUpdating,
              isDestructive: true,
              onPressed: isUpdating ? null : () => _showCancelDialog(context),
            ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: isDestructive
            ? FilledButton.styleFrom(backgroundColor: AppTheme.error)
            : FilledButton.styleFrom(backgroundColor: orderAccent),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
