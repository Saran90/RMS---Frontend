import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

// ── Order page design tokens (aligned with dashboard / billing / menu) ────────

const Color orderBg = Color(0xFFF5F0E8);
const Color orderCard = Color(0xFFFFFFFF);
const Color orderBorder = Color(0xFFE8E0D0);
const Color orderTitle = Color(0xFF1A1208);
const Color orderMuted = Color(0xFF9A8060);
const Color orderAccent = Color(0xFFBF4010);
const Color orderDivider = Color(0xFFF0E8D8);

/// Stat card for the orders page header.
class OrderStatCard extends StatelessWidget {
  const OrderStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: orderCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: orderBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: orderTitle,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: orderMuted)),
        ],
      ),
    );
  }
}

/// Filter / tab chip for orders.
class OrderChoiceChip extends StatelessWidget {
  const OrderChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? orderAccent.withValues(alpha: 0.12) : orderCard,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? orderAccent : orderBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? orderAccent : orderMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section card wrapper.
class OrderSectionCard extends StatelessWidget {
  const OrderSectionCard({
    required this.child,
    this.title,
    super.key,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: orderCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: orderBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: orderTitle,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Empty state for orders list.
class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: orderAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: orderAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: orderTitle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Orders will appear here once placed',
              style: TextStyle(fontSize: 13, color: orderMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class OrderTypeBadge extends StatelessWidget {
  const OrderTypeBadge({required this.type, super.key});
  final OrderType type;

  static const _labels = {
    OrderType.dineIn: 'Dine-in',
    OrderType.takeaway: 'Takeaway',
    OrderType.delivery: 'Delivery',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: orderDivider,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: orderBorder),
      ),
      child: Text(
        _labels[type] ?? type.jsonValue,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: orderMuted,
        ),
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({required this.status, super.key});
  final OrderStatus status;

  static const _labels = {
    OrderStatus.pending: 'Pending',
    OrderStatus.confirmed: 'Confirmed',
    OrderStatus.preparing: 'Preparing',
    OrderStatus.ready: 'Ready',
    OrderStatus.served: 'Served',
    OrderStatus.completed: 'Completed',
    OrderStatus.cancelled: 'Cancelled',
  };

  static const _colors = {
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
    final color = _colors[status] ?? orderMuted;
    final label = _labels[status] ?? status.jsonValue;
    return StatusBadge(label: label, color: color);
  }
}

/// Compact order row for the list.
class OrderListTile extends StatelessWidget {
  const OrderListTile({
    required this.order,
    required this.onTap,
    super.key,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.fold<int>(0, (s, i) => s + i.quantity);
    final preview = order.items.isEmpty
        ? 'No items'
        : order.items
            .take(2)
            .map((i) => '${i.quantity}× ${i.itemName}')
            .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: orderCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: orderBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: orderAccent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: orderAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 20,
                            color: orderAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${order.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: orderTitle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OrderTypeBadge(type: order.orderType),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preview,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: orderMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (itemCount > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: orderMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OrderStatusBadge(status: order.status),
                            const SizedBox(height: 6),
                            Text(
                              '₹${order.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: orderAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: orderMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
