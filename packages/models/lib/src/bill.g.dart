// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GstSlabImpl _$$GstSlabImplFromJson(Map<String, dynamic> json) =>
    _$GstSlabImpl(
      gstRate: const _DoubleConverter().fromJson(json['gst_rate']),
      taxableValue: const _DoubleConverter().fromJson(json['taxable_value']),
      gstAmount: const _DoubleConverter().fromJson(json['gst_amount']),
    );

Map<String, dynamic> _$$GstSlabImplToJson(_$GstSlabImpl instance) =>
    <String, dynamic>{
      'gst_rate': const _DoubleConverter().toJson(instance.gstRate),
      'taxable_value': const _DoubleConverter().toJson(instance.taxableValue),
      'gst_amount': const _DoubleConverter().toJson(instance.gstAmount),
    };

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      amount: const _DoubleConverter().fromJson(json['amount']),
      mode: json['mode'] as String?,
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'amount': const _DoubleConverter().toJson(instance.amount),
      'mode': instance.mode,
      'paid_at': instance.paidAt?.toIso8601String(),
      'id': instance.id,
    };

_$BillImpl _$$BillImplFromJson(Map<String, dynamic> json) => _$BillImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      subtotal: const _DoubleConverter().fromJson(json['subtotal']),
      gstBreakdown: (json['gst_breakdown'] as List<dynamic>)
          .map((e) => GstSlab.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: const _DoubleConverter().fromJson(json['total']),
      status: json['status'] as String,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$BillImplToJson(_$BillImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'subtotal': const _DoubleConverter().toJson(instance.subtotal),
      'gst_breakdown': instance.gstBreakdown.map((e) => e.toJson()).toList(),
      'total': const _DoubleConverter().toJson(instance.total),
      'status': instance.status,
      'payments': instance.payments.map((e) => e.toJson()).toList(),
    };
