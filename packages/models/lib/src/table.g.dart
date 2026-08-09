// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TableImpl _$$TableImplFromJson(Map<String, dynamic> json) => _$TableImpl(
      id: json['id'] as String,
      tableNumber: json['table_number'] as String,
      sectionLabel: json['section_label'] as String?,
      status: $enumDecode(_$TableStatusEnumMap, json['status']),
      currentOrderId: json['current_order_id'] as String?,
      qrUrl: json['qr_url'] as String?,
      reservationName: json['reservation_name'] as String?,
      reservationPhone: json['reservation_phone'] as String?,
      reservedFor: json['reserved_for'] == null
          ? null
          : DateTime.parse(json['reserved_for'] as String),
      reservedUntil: json['reserved_until'] == null
          ? null
          : DateTime.parse(json['reserved_until'] as String),
    );

Map<String, dynamic> _$$TableImplToJson(_$TableImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'table_number': instance.tableNumber,
      'section_label': instance.sectionLabel,
      'status': _$TableStatusEnumMap[instance.status]!,
      'current_order_id': instance.currentOrderId,
      'qr_url': instance.qrUrl,
      'reservation_name': instance.reservationName,
      'reservation_phone': instance.reservationPhone,
      'reserved_for': instance.reservedFor?.toIso8601String(),
      'reserved_until': instance.reservedUntil?.toIso8601String(),
    };

const _$TableStatusEnumMap = {
  TableStatus.available: 'available',
  TableStatus.occupied: 'occupied',
  TableStatus.reserved: 'reserved',
  TableStatus.cleaning: 'cleaning',
};
