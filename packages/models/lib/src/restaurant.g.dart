// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusinessHoursImpl _$$BusinessHoursImplFromJson(Map<String, dynamic> json) =>
    _$BusinessHoursImpl(
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      openTime: json['open_time'] as String,
      closeTime: json['close_time'] as String,
      isClosed: json['is_closed'] as bool? ?? false,
    );

Map<String, dynamic> _$$BusinessHoursImplToJson(_$BusinessHoursImpl instance) =>
    <String, dynamic>{
      'day_of_week': instance.dayOfWeek,
      'open_time': instance.openTime,
      'close_time': instance.closeTime,
      'is_closed': instance.isClosed,
    };

_$RestaurantImpl _$$RestaurantImplFromJson(Map<String, dynamic> json) =>
    _$RestaurantImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      gstNumber: json['gst_number'] as String,
      logoUrl: json['logo_url'] as String?,
      businessHours: (json['business_hours'] as List<dynamic>?)
              ?.map((e) => BusinessHours.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RestaurantImplToJson(_$RestaurantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'phone': instance.phone,
      'gst_number': instance.gstNumber,
      'logo_url': instance.logoUrl,
      'business_hours': instance.businessHours.map((e) => e.toJson()).toList(),
    };
