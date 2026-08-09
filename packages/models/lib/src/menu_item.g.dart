// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemVariantImpl _$$ItemVariantImplFromJson(Map<String, dynamic> json) =>
    _$ItemVariantImpl(
      id: json['id'] as String,
      sizeLabel: json['size_label'] as String,
      priceDelta: _parseDouble(json['price_delta']),
    );

Map<String, dynamic> _$$ItemVariantImplToJson(_$ItemVariantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'size_label': instance.sizeLabel,
      'price_delta': instance.priceDelta,
    };

_$ModifierOptionImpl _$$ModifierOptionImplFromJson(Map<String, dynamic> json) =>
    _$ModifierOptionImpl(
      id: json['id'] as String,
      modifierName: json['modifier_name'] as String,
      priceDelta: _parseDouble(json['price_delta']),
    );

Map<String, dynamic> _$$ModifierOptionImplToJson(
        _$ModifierOptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'modifier_name': instance.modifierName,
      'price_delta': instance.priceDelta,
    };

_$ModifierGroupImpl _$$ModifierGroupImplFromJson(Map<String, dynamic> json) =>
    _$ModifierGroupImpl(
      id: json['id'] as String,
      groupName: json['group_name'] as String,
      minSelect: (json['min_select'] as num).toInt(),
      maxSelect: (json['max_select'] as num).toInt(),
      options: (json['options'] as List<dynamic>)
          .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ModifierGroupImplToJson(_$ModifierGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_name': instance.groupName,
      'min_select': instance.minSelect,
      'max_select': instance.maxSelect,
      'options': instance.options.map((e) => e.toJson()).toList(),
    };

_$MenuItemImpl _$$MenuItemImplFromJson(Map<String, dynamic> json) =>
    _$MenuItemImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      basePrice: _parseDouble(json['base_price']),
      gstRate: _parseDouble(json['gst_rate']),
      dietaryType: $enumDecode(_$DietaryTypeEnumMap, json['dietary_type']),
      isAvailable: json['is_available'] as bool,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ItemVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      modifierGroups: (json['modifier_groups'] as List<dynamic>?)
              ?.map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      imageUrl: json['photo_url'] as String?,
    );

Map<String, dynamic> _$$MenuItemImplToJson(_$MenuItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category_id': instance.categoryId,
      'base_price': instance.basePrice,
      'gst_rate': instance.gstRate,
      'dietary_type': _$DietaryTypeEnumMap[instance.dietaryType]!,
      'is_available': instance.isAvailable,
      'variants': instance.variants.map((e) => e.toJson()).toList(),
      'modifier_groups':
          instance.modifierGroups.map((e) => e.toJson()).toList(),
      'photo_url': instance.imageUrl,
    };

const _$DietaryTypeEnumMap = {
  DietaryType.veg: 'veg',
  DietaryType.nonVeg: 'non_veg',
  DietaryType.vegan: 'vegan',
  DietaryType.egg: 'egg',
};
