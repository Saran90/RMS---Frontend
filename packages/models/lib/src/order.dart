import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:models/src/enums.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// A single line-item within an [Order].
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    /// Unique identifier for this order item.
    required String id,

    /// Reference to the [MenuItem] ordered.
    @JsonKey(name: 'item_id') required String itemId,

    /// Snapshot of the item name at time of order — returned by API as `item_name`.
    @JsonKey(name: 'item_name') required String itemName,

    /// Number of units ordered.
    required int quantity,

    /// Price per unit.
    @JsonKey(name: 'unit_price') @_DoubleConverter() required double unitPrice,

    /// Total price for this line (unit_price × quantity + modifier_total).
    @JsonKey(name: 'item_total') @_DoubleConverter() required double itemTotal,

    /// Modifier total price.
    @JsonKey(name: 'modifier_total')
    @_DoubleConverter()
    @Default(0.0)
    double modifierTotal,

    /// Modifier IDs.
    @JsonKey(name: 'modifier_ids') @Default([]) List<String> modifierIds,

    /// ID of the chosen variant, if any.
    @JsonKey(name: 'variant_id') String? variantId,

    /// Label of the chosen variant, if any.
    @JsonKey(name: 'variant_label') String? variantLabel,

    /// Order reference.
    @JsonKey(name: 'order_id') String? orderId,

    /// KDS status (queued, prepared, etc.).
    @JsonKey(name: 'kds_status') String? kdsStatus,

    /// KDS station ID.
    @JsonKey(name: 'kds_station_id') String? kdsStationId,

    /// KDS queued time.
    @JsonKey(name: 'kds_queued_at') DateTime? kdsQueuedAt,

    /// Created at timestamp.
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

/// An order placed by a customer or staff member.
@freezed
class Order with _$Order {
  const factory Order({
    /// Unique identifier.
    required String id,

    /// Fulfilment channel.
    @JsonKey(name: 'order_type') required OrderType orderType,

    /// Current lifecycle status.
    required OrderStatus status,

    /// UTC timestamp when the order was created.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Line items included in this order (may be empty in list responses).
    @Default([]) List<OrderItem> items,

    /// Sum of all item prices — returned as a string like "0.00".
    @JsonKey(name: 'subtotal')
    @_DoubleConverter()
    @Default(0.0)
    double subtotal,

    /// Table reference; only present for [OrderType.dineIn] orders.
    @JsonKey(name: 'table_id') String? tableId,

    /// Customer name (delivery/takeaway orders).
    @JsonKey(name: 'customer_name') String? customerName,

    /// Customer phone (delivery orders).
    @JsonKey(name: 'customer_phone') String? customerPhone,

    /// Delivery address (delivery orders).
    @JsonKey(name: 'delivery_address') String? deliveryAddress,

    /// Reason if the order was cancelled.
    @JsonKey(name: 'cancel_reason') String? cancelReason,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

/// Converts numeric strings like "0.00" to double.
class _DoubleConverter implements JsonConverter<double, dynamic> {
  const _DoubleConverter();

  @override
  double fromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }

  @override
  dynamic toJson(double value) => value;
}
