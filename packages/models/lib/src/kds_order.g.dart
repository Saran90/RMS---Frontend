// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kds_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KdsOrderImpl _$$KdsOrderImplFromJson(Map<String, dynamic> json) =>
    _$KdsOrderImpl(
      orderId: json['order_id'] as String,
      orderType: $enumDecode(_$OrderTypeEnumMap, json['order_type']),
      orderStatus: $enumDecode(_$OrderStatusEnumMap, json['order_status']),
      tableId: json['table_id'] as String?,
      orderCreatedAt: DateTime.parse(json['order_created_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => KdsItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$KdsOrderImplToJson(_$KdsOrderImpl instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'order_type': _$OrderTypeEnumMap[instance.orderType]!,
      'order_status': _$OrderStatusEnumMap[instance.orderStatus]!,
      'table_id': instance.tableId,
      'order_created_at': instance.orderCreatedAt.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
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
