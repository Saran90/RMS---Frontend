// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: const _DoubleConverter().fromJson(json['unit_price']),
      itemTotal: const _DoubleConverter().fromJson(json['item_total']),
      modifierTotal: json['modifier_total'] == null
          ? 0.0
          : const _DoubleConverter().fromJson(json['modifier_total']),
      modifierIds: (json['modifier_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      variantId: json['variant_id'] as String?,
      variantLabel: json['variant_label'] as String?,
      orderId: json['order_id'] as String?,
      kdsStatus: json['kds_status'] as String?,
      kdsStationId: json['kds_station_id'] as String?,
      kdsQueuedAt: json['kds_queued_at'] == null
          ? null
          : DateTime.parse(json['kds_queued_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'item_id': instance.itemId,
      'item_name': instance.itemName,
      'quantity': instance.quantity,
      'unit_price': const _DoubleConverter().toJson(instance.unitPrice),
      'item_total': const _DoubleConverter().toJson(instance.itemTotal),
      'modifier_total': const _DoubleConverter().toJson(instance.modifierTotal),
      'modifier_ids': instance.modifierIds,
      'variant_id': instance.variantId,
      'variant_label': instance.variantLabel,
      'order_id': instance.orderId,
      'kds_status': instance.kdsStatus,
      'kds_station_id': instance.kdsStationId,
      'kds_queued_at': instance.kdsQueuedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
      id: json['id'] as String,
      orderType: $enumDecode(_$OrderTypeEnumMap, json['order_type']),
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subtotal: json['subtotal'] == null
          ? 0.0
          : const _DoubleConverter().fromJson(json['subtotal']),
      tableId: json['table_id'] as String?,
      tableNumber: _tableNumberFromJson(json['table_number']),
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      cancelReason: json['cancel_reason'] as String?,
    );

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_type': _$OrderTypeEnumMap[instance.orderType]!,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotal': const _DoubleConverter().toJson(instance.subtotal),
      'table_id': instance.tableId,
      'table_number': instance.tableNumber,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'delivery_address': instance.deliveryAddress,
      'cancel_reason': instance.cancelReason,
    };

const _$OrderTypeEnumMap = {
  OrderType.dineIn: 'dine_in',
  OrderType.takeaway: 'takeaway',
  OrderType.delivery: 'delivery',
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready: 'ready',
  OrderStatus.served: 'served',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};
