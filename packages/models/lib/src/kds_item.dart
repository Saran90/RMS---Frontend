import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:models/src/enums.dart';

part 'kds_item.freezed.dart';
part 'kds_item.g.dart';

/// A single item surfaced on the Kitchen Display System (KDS).
@freezed
class KdsItem with _$KdsItem {
  const factory KdsItem({
    /// ID of this order item (used for status updates).
    required String id,

    /// ID of the parent order.
    @JsonKey(name: 'order_id') required String orderId,

    /// ID of the menu item.
    @JsonKey(name: 'item_id') required String itemId,

    /// Display name of the item shown on the KDS card.
    @JsonKey(name: 'item_name') required String itemName,

    /// Number of units to prepare.
    required int quantity,

    /// Current processing status on the KDS.
    @JsonKey(name: 'kds_status') required KdsItemStatus kdsStatus,

    /// UTC timestamp when the order was placed (used for elapsed-time calc).
    @JsonKey(name: 'order_created_at') required DateTime orderCreatedAt,

    /// UTC timestamp when this item was queued on the KDS.
    @JsonKey(name: 'kds_queued_at') DateTime? kdsQueuedAt,

    /// UTC timestamp when this item was created.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Whether this item has exceeded its alert threshold.
    @JsonKey(name: 'is_overdue') @Default(false) bool isOverdue,

    /// Alert threshold in minutes (null = use default).
    @JsonKey(name: 'kds_alert_threshold_minutes') int? kdsAlertThresholdMinutes,

    /// KDS station this item is routed to (null = default station).
    @JsonKey(name: 'kds_station_id') String? kdsStationId,

    /// Modifier IDs applied to this item.
    @JsonKey(name: 'modifier_ids') @Default([]) List<String> modifierIds,

    /// Variant ID, if any.
    @JsonKey(name: 'variant_id') String? variantId,

    /// Unit price.
    @JsonKey(name: 'unit_price')
    @_DoubleConverter()
    @Default(0.0)
    double unitPrice,

    /// Modifier total.
    @JsonKey(name: 'modifier_total')
    @_DoubleConverter()
    @Default(0.0)
    double modifierTotal,
  }) = _KdsItem;

  factory KdsItem.fromJson(Map<String, dynamic> json) =>
      _$KdsItemFromJson(json);
}

/// Converts numeric strings like "99.00" to double.
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
