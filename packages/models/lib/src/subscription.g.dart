// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionImpl _$$SubscriptionImplFromJson(Map<String, dynamic> json) =>
    _$SubscriptionImpl(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      planName: json['plan_name'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$$SubscriptionImplToJson(_$SubscriptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_id': instance.planId,
      'plan_name': instance.planName,
      'status': instance.status,
      'expires_at': instance.expiresAt.toIso8601String(),
    };
