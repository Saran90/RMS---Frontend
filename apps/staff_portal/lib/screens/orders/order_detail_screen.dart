// Feature: rms-flutter-frontend
// Implements: Requirements 9.7, 9.8, 9.9

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/orders/order_bloc.dart';
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
            backgroundColor: AppTheme.surface,
            appBar: AppBar(title: const Text('Order Detail')),
            body: ListView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              children: const [
                LoadingSkeletonCard(height: 120),
                SizedBox(height: AppTheme.spacing8),
                LoadingSkeletonCard(height: 200),
                SizedBox(height: AppTheme.spacing8),
                LoadingSkeletonCard(height: 88),
              ],
            ),
          );
        }

        // ── Error state (no cached order) ────────────────────────────────────
        if (state is OrderError && _lastOrder == null) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(title: const Text('Order Detail')),
            body: ErrorStateWidget(
              message: state.message,
              onRetry: () => context
                  .read<OrderBloc>()
                  .add(OrderDetailRequested(widget.orderId)),
            ),
          );
        }

        // ── Determine the order to display ───────────────────────────────────
        final Order? order =
            (state is OrderDetailLoaded) ? state.order : _lastOrder;

        if (order == null) {
          // Fallback — nothing to show yet
          return Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(title: const Text('Order Detail')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // ── Full detail view ─────────────────────────────────────────────────
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _isUpdating
                    ? null
                    : () => context
                        .read<OrderBloc>()
                        .add(OrderDetailRequested(widget.orderId)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Metadata card ─────────────────────────────────────────
                _MetadataCard(order: order),
                const SizedBox(height: AppTheme.spacing16),

                // ── Items card ────────────────────────────────────────────
                _ItemsCard(order: order),
                const SizedBox(height: AppTheme.spacing16),

                // ── Status-transition buttons ─────────────────────────────
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
        );
      },
    );
  }
}

// ── Metadata card (Req 9.9) ───────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.order});

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
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                _TypeBadge(type: order.orderType),
                const SizedBox(width: AppTheme.spacing8),
                _StatusBadgeWidget(status: order.status),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            _InfoRow(
              label: 'Created',
              value: _formatDateTime(order.createdAt),
            ),
            if (order.tableId != null && order.orderType == OrderType.dineIn)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacing8),
                child: _InfoRow(
                  label: 'Table',
                  value: order.tableId!,
                ),
              ),
          ],
        ),
      ),
    );
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.mutedText),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
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
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${order.items.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing12),
            const Divider(height: 1),
            ...order.items.map((item) => _OrderItemRow(item: item)),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spacing12),
            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '₹${order.subtotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + per-item total
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quantity badge
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
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(2)} each',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    // Variant
                    if (item.variantId != null) ...[
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Variant: ${item.variantId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                      ),
                    ],
                    // Modifiers
                    if (item.modifierIds.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Modifiers: ${item.modifierIds.join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              // Per-item total
              Text(
                '₹${item.itemTotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
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
  OrderStatus.ready: [OrderStatus.served],
  OrderStatus.served: [], // completed is triggered by billing payment
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
      return Card(
        elevation: 0,
        color: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
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
                        ? AppTheme.primary
                        : order.status == OrderStatus.confirmed
                            ? AppTheme.warning
                            : AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  order.status == OrderStatus.cancelled
                      ? 'Order cancelled.'
                      : order.status == OrderStatus.served
                          ? 'Order served — go to Billing to record payment and complete the order.'
                          : order.status == OrderStatus.confirmed
                              ? 'Order confirmed — kitchen will pick this up from the KDS.'
                              : 'Order completed.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.mutedText),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: [
                // Forward-progress buttons
                ...nextStatuses.map((nextStatus) => _StatusButton(
                      label:
                          'Mark as ${_statusLabels[nextStatus] ?? nextStatus.jsonValue}',
                      isLoading: isUpdating,
                      onPressed: isUpdating
                          ? null
                          : () => onStatusRequested(nextStatus),
                    )),
                // Cancel button
                if (canCancel)
                  _StatusButton(
                    label: 'Cancel Order',
                    isLoading: isUpdating,
                    isDestructive: true,
                    onPressed:
                        isUpdating ? null : () => _showCancelDialog(context),
                  ),
              ],
            ),
          ],
        ),
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
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: isDestructive
            ? FilledButton.styleFrom(backgroundColor: AppTheme.error)
            : null,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final OrderType type;

  static const _labels = <OrderType, String>{
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

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadgeWidget extends StatelessWidget {
  const _StatusBadgeWidget({required this.status});

  final OrderStatus status;

  static const _labels = <OrderStatus, String>{
    OrderStatus.pending: 'Pending',
    OrderStatus.confirmed: 'Confirmed',
    OrderStatus.preparing: 'Preparing',
    OrderStatus.ready: 'Ready',
    OrderStatus.served: 'Served',
    OrderStatus.completed: 'Completed',
    OrderStatus.cancelled: 'Cancelled',
  };

  static const _colors = <OrderStatus, Color>{
    OrderStatus.pending: AppColors.orderPending,
    OrderStatus.confirmed: AppColors.orderConfirmed,
    OrderStatus.preparing: AppColors.orderPreparing,
    OrderStatus.ready: AppColors.orderReady,
    OrderStatus.served: AppColors.orderServed,
    OrderStatus.completed: AppColors.orderCompleted,
    OrderStatus.cancelled: AppTheme.error,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppTheme.mutedText;
    final label = _labels[status] ?? status.jsonValue;
    return StatusBadge(label: label, color: color);
  }
}
