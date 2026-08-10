import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:models/src/enums.dart';
import 'package:models/src/kds_item.dart';

part 'kds_order.freezed.dart';
part 'kds_order.g.dart';

/// An order shown in the KDS feed with its items.
@freezed
class KdsOrder with _$KdsOrder {
  const factory KdsOrder({
    /// Order ID
    @JsonKey(name: 'order_id') required String orderId,

    /// Order type (dine_in, takeaway, delivery)
    @JsonKey(name: 'order_type') required OrderType orderType,

    /// Current order status
    @JsonKey(name: 'order_status') required OrderStatus orderStatus,

    /// Table ID (for dine-in orders)
    @JsonKey(name: 'table_id') String? tableId,

    /// Human-readable table number (dine-in)
    @JsonKey(name: 'table_number') int? tableNumber,

    /// Floor section for the table (dine-in)
    @JsonKey(name: 'section_label') String? sectionLabel,

    /// When the order was created
    @JsonKey(name: 'order_created_at') required DateTime orderCreatedAt,

    /// Items in this order
    @Default([]) List<KdsItem> items,
  }) = _KdsOrder;

  factory KdsOrder.fromJson(Map<String, dynamic> json) =>
      _$KdsOrderFromJson(json);
}
