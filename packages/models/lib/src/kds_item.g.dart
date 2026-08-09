// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kds_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KdsItemImpl _$$KdsItemImplFromJson(Map<String, dynamic> json) =>
    _$KdsItemImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      kdsStatus: $enumDecode(_$KdsItemStatusEnumMap, json['kds_status']),
      orderCreatedAt: DateTime.parse(json['order_created_at'] as String),
      kdsQueuedAt: json['kds_queued_at'] == null
          ? null
          : DateTime.parse(json['kds_queued_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isOverdue: json['is_overdue'] as bool? ?? false,
      kdsAlertThresholdMinutes:
          (json['kds_alert_threshold_minutes'] as num?)?.toInt(),
      kdsStationId: json['kds_station_id'] as String?,
      modifierIds: (json['modifier_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      variantId: json['variant_id'] as String?,
      unitPrice: json['unit_price'] == null
          ? 0.0
          : const _DoubleConverter().fromJson(json['unit_price']),
      modifierTotal: json['modifier_total'] == null
          ? 0.0
          : const _DoubleConverter().fromJson(json['modifier_total']),
    );

Map<String, dynamic> _$$KdsItemImplToJson(_$KdsItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'item_id': instance.itemId,
      'item_name': instance.itemName,
      'quantity': instance.quantity,
      'kds_status': _$KdsItemStatusEnumMap[instance.kdsStatus]!,
      'order_created_at': instance.orderCreatedAt.toIso8601String(),
      'kds_queued_at': instance.kdsQueuedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'is_overdue': instance.isOverdue,
      'kds_alert_threshold_minutes': instance.kdsAlertThresholdMinutes,
      'kds_station_id': instance.kdsStationId,
      'modifier_ids': instance.modifierIds,
      'variant_id': instance.variantId,
      'unit_price': const _DoubleConverter().toJson(instance.unitPrice),
      'modifier_total': const _DoubleConverter().toJson(instance.modifierTotal),
    };

const _$KdsItemStatusEnumMap = {
  KdsItemStatus.queued: 'queued',
  KdsItemStatus.started: 'started',
  KdsItemStatus.done: 'done',
};
