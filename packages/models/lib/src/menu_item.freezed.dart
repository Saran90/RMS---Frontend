// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItemVariant _$ItemVariantFromJson(Map<String, dynamic> json) {
  return _ItemVariant.fromJson(json);
}

/// @nodoc
mixin _$ItemVariant {
  /// Unique identifier for the variant.
  String get id => throw _privateConstructorUsedError;

  /// Human-readable label (e.g. "Small", "Large").
  @JsonKey(name: 'size_label')
  String get sizeLabel => throw _privateConstructorUsedError;

  /// Price delta relative to the base price (can be negative).
  @JsonKey(name: 'price_delta', fromJson: _parseDouble)
  double get priceDelta => throw _privateConstructorUsedError;

  /// Serializes this ItemVariant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemVariantCopyWith<ItemVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemVariantCopyWith<$Res> {
  factory $ItemVariantCopyWith(
          ItemVariant value, $Res Function(ItemVariant) then) =
      _$ItemVariantCopyWithImpl<$Res, ItemVariant>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'size_label') String sizeLabel,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble) double priceDelta});
}

/// @nodoc
class _$ItemVariantCopyWithImpl<$Res, $Val extends ItemVariant>
    implements $ItemVariantCopyWith<$Res> {
  _$ItemVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sizeLabel = null,
    Object? priceDelta = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sizeLabel: null == sizeLabel
          ? _value.sizeLabel
          : sizeLabel // ignore: cast_nullable_to_non_nullable
              as String,
      priceDelta: null == priceDelta
          ? _value.priceDelta
          : priceDelta // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemVariantImplCopyWith<$Res>
    implements $ItemVariantCopyWith<$Res> {
  factory _$$ItemVariantImplCopyWith(
          _$ItemVariantImpl value, $Res Function(_$ItemVariantImpl) then) =
      __$$ItemVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'size_label') String sizeLabel,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble) double priceDelta});
}

/// @nodoc
class __$$ItemVariantImplCopyWithImpl<$Res>
    extends _$ItemVariantCopyWithImpl<$Res, _$ItemVariantImpl>
    implements _$$ItemVariantImplCopyWith<$Res> {
  __$$ItemVariantImplCopyWithImpl(
      _$ItemVariantImpl _value, $Res Function(_$ItemVariantImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItemVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sizeLabel = null,
    Object? priceDelta = null,
  }) {
    return _then(_$ItemVariantImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sizeLabel: null == sizeLabel
          ? _value.sizeLabel
          : sizeLabel // ignore: cast_nullable_to_non_nullable
              as String,
      priceDelta: null == priceDelta
          ? _value.priceDelta
          : priceDelta // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemVariantImpl implements _ItemVariant {
  const _$ItemVariantImpl(
      {required this.id,
      @JsonKey(name: 'size_label') required this.sizeLabel,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble)
      required this.priceDelta});

  factory _$ItemVariantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemVariantImplFromJson(json);

  /// Unique identifier for the variant.
  @override
  final String id;

  /// Human-readable label (e.g. "Small", "Large").
  @override
  @JsonKey(name: 'size_label')
  final String sizeLabel;

  /// Price delta relative to the base price (can be negative).
  @override
  @JsonKey(name: 'price_delta', fromJson: _parseDouble)
  final double priceDelta;

  @override
  String toString() {
    return 'ItemVariant(id: $id, sizeLabel: $sizeLabel, priceDelta: $priceDelta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemVariantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sizeLabel, sizeLabel) ||
                other.sizeLabel == sizeLabel) &&
            (identical(other.priceDelta, priceDelta) ||
                other.priceDelta == priceDelta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, sizeLabel, priceDelta);

  /// Create a copy of ItemVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemVariantImplCopyWith<_$ItemVariantImpl> get copyWith =>
      __$$ItemVariantImplCopyWithImpl<_$ItemVariantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemVariantImplToJson(
      this,
    );
  }
}

abstract class _ItemVariant implements ItemVariant {
  const factory _ItemVariant(
      {required final String id,
      @JsonKey(name: 'size_label') required final String sizeLabel,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble)
      required final double priceDelta}) = _$ItemVariantImpl;

  factory _ItemVariant.fromJson(Map<String, dynamic> json) =
      _$ItemVariantImpl.fromJson;

  /// Unique identifier for the variant.
  @override
  String get id;

  /// Human-readable label (e.g. "Small", "Large").
  @override
  @JsonKey(name: 'size_label')
  String get sizeLabel;

  /// Price delta relative to the base price (can be negative).
  @override
  @JsonKey(name: 'price_delta', fromJson: _parseDouble)
  double get priceDelta;

  /// Create a copy of ItemVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemVariantImplCopyWith<_$ItemVariantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModifierOption _$ModifierOptionFromJson(Map<String, dynamic> json) {
  return _ModifierOption.fromJson(json);
}

/// @nodoc
mixin _$ModifierOption {
  /// Unique identifier for this modifier option.
  String get id => throw _privateConstructorUsedError;

  /// Name displayed to the user (e.g. "Extra Cheese").
  @JsonKey(name: 'modifier_name')
  String get modifierName => throw _privateConstructorUsedError;

  /// Additional cost for this modifier.
  @JsonKey(name: 'price_delta', fromJson: _parseDouble)
  double get priceDelta => throw _privateConstructorUsedError;

  /// Serializes this ModifierOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModifierOptionCopyWith<ModifierOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModifierOptionCopyWith<$Res> {
  factory $ModifierOptionCopyWith(
          ModifierOption value, $Res Function(ModifierOption) then) =
      _$ModifierOptionCopyWithImpl<$Res, ModifierOption>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'modifier_name') String modifierName,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble) double priceDelta});
}

/// @nodoc
class _$ModifierOptionCopyWithImpl<$Res, $Val extends ModifierOption>
    implements $ModifierOptionCopyWith<$Res> {
  _$ModifierOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? modifierName = null,
    Object? priceDelta = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      modifierName: null == modifierName
          ? _value.modifierName
          : modifierName // ignore: cast_nullable_to_non_nullable
              as String,
      priceDelta: null == priceDelta
          ? _value.priceDelta
          : priceDelta // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModifierOptionImplCopyWith<$Res>
    implements $ModifierOptionCopyWith<$Res> {
  factory _$$ModifierOptionImplCopyWith(_$ModifierOptionImpl value,
          $Res Function(_$ModifierOptionImpl) then) =
      __$$ModifierOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'modifier_name') String modifierName,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble) double priceDelta});
}

/// @nodoc
class __$$ModifierOptionImplCopyWithImpl<$Res>
    extends _$ModifierOptionCopyWithImpl<$Res, _$ModifierOptionImpl>
    implements _$$ModifierOptionImplCopyWith<$Res> {
  __$$ModifierOptionImplCopyWithImpl(
      _$ModifierOptionImpl _value, $Res Function(_$ModifierOptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? modifierName = null,
    Object? priceDelta = null,
  }) {
    return _then(_$ModifierOptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      modifierName: null == modifierName
          ? _value.modifierName
          : modifierName // ignore: cast_nullable_to_non_nullable
              as String,
      priceDelta: null == priceDelta
          ? _value.priceDelta
          : priceDelta // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModifierOptionImpl implements _ModifierOption {
  const _$ModifierOptionImpl(
      {required this.id,
      @JsonKey(name: 'modifier_name') required this.modifierName,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble)
      required this.priceDelta});

  factory _$ModifierOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModifierOptionImplFromJson(json);

  /// Unique identifier for this modifier option.
  @override
  final String id;

  /// Name displayed to the user (e.g. "Extra Cheese").
  @override
  @JsonKey(name: 'modifier_name')
  final String modifierName;

  /// Additional cost for this modifier.
  @override
  @JsonKey(name: 'price_delta', fromJson: _parseDouble)
  final double priceDelta;

  @override
  String toString() {
    return 'ModifierOption(id: $id, modifierName: $modifierName, priceDelta: $priceDelta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModifierOptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.modifierName, modifierName) ||
                other.modifierName == modifierName) &&
            (identical(other.priceDelta, priceDelta) ||
                other.priceDelta == priceDelta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, modifierName, priceDelta);

  /// Create a copy of ModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModifierOptionImplCopyWith<_$ModifierOptionImpl> get copyWith =>
      __$$ModifierOptionImplCopyWithImpl<_$ModifierOptionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModifierOptionImplToJson(
      this,
    );
  }
}

abstract class _ModifierOption implements ModifierOption {
  const factory _ModifierOption(
      {required final String id,
      @JsonKey(name: 'modifier_name') required final String modifierName,
      @JsonKey(name: 'price_delta', fromJson: _parseDouble)
      required final double priceDelta}) = _$ModifierOptionImpl;

  factory _ModifierOption.fromJson(Map<String, dynamic> json) =
      _$ModifierOptionImpl.fromJson;

  /// Unique identifier for this modifier option.
  @override
  String get id;

  /// Name displayed to the user (e.g. "Extra Cheese").
  @override
  @JsonKey(name: 'modifier_name')
  String get modifierName;

  /// Additional cost for this modifier.
  @override
  @JsonKey(name: 'price_delta', fromJson: _parseDouble)
  double get priceDelta;

  /// Create a copy of ModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModifierOptionImplCopyWith<_$ModifierOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModifierGroup _$ModifierGroupFromJson(Map<String, dynamic> json) {
  return _ModifierGroup.fromJson(json);
}

/// @nodoc
mixin _$ModifierGroup {
  /// Unique identifier for the modifier group.
  String get id => throw _privateConstructorUsedError;

  /// Display name for the group (e.g. "Add-ons", "Sauces").
  @JsonKey(name: 'group_name')
  String get groupName => throw _privateConstructorUsedError;

  /// Minimum number of options the customer must select.
  @JsonKey(name: 'min_select')
  int get minSelect => throw _privateConstructorUsedError;

  /// Maximum number of options the customer may select.
  @JsonKey(name: 'max_select')
  int get maxSelect => throw _privateConstructorUsedError;

  /// Selectable options within this group.
  List<ModifierOption> get options => throw _privateConstructorUsedError;

  /// Serializes this ModifierGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModifierGroupCopyWith<ModifierGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModifierGroupCopyWith<$Res> {
  factory $ModifierGroupCopyWith(
          ModifierGroup value, $Res Function(ModifierGroup) then) =
      _$ModifierGroupCopyWithImpl<$Res, ModifierGroup>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'group_name') String groupName,
      @JsonKey(name: 'min_select') int minSelect,
      @JsonKey(name: 'max_select') int maxSelect,
      List<ModifierOption> options});
}

/// @nodoc
class _$ModifierGroupCopyWithImpl<$Res, $Val extends ModifierGroup>
    implements $ModifierGroupCopyWith<$Res> {
  _$ModifierGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupName = null,
    Object? minSelect = null,
    Object? maxSelect = null,
    Object? options = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      minSelect: null == minSelect
          ? _value.minSelect
          : minSelect // ignore: cast_nullable_to_non_nullable
              as int,
      maxSelect: null == maxSelect
          ? _value.maxSelect
          : maxSelect // ignore: cast_nullable_to_non_nullable
              as int,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<ModifierOption>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModifierGroupImplCopyWith<$Res>
    implements $ModifierGroupCopyWith<$Res> {
  factory _$$ModifierGroupImplCopyWith(
          _$ModifierGroupImpl value, $Res Function(_$ModifierGroupImpl) then) =
      __$$ModifierGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'group_name') String groupName,
      @JsonKey(name: 'min_select') int minSelect,
      @JsonKey(name: 'max_select') int maxSelect,
      List<ModifierOption> options});
}

/// @nodoc
class __$$ModifierGroupImplCopyWithImpl<$Res>
    extends _$ModifierGroupCopyWithImpl<$Res, _$ModifierGroupImpl>
    implements _$$ModifierGroupImplCopyWith<$Res> {
  __$$ModifierGroupImplCopyWithImpl(
      _$ModifierGroupImpl _value, $Res Function(_$ModifierGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupName = null,
    Object? minSelect = null,
    Object? maxSelect = null,
    Object? options = null,
  }) {
    return _then(_$ModifierGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      minSelect: null == minSelect
          ? _value.minSelect
          : minSelect // ignore: cast_nullable_to_non_nullable
              as int,
      maxSelect: null == maxSelect
          ? _value.maxSelect
          : maxSelect // ignore: cast_nullable_to_non_nullable
              as int,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<ModifierOption>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModifierGroupImpl implements _ModifierGroup {
  const _$ModifierGroupImpl(
      {required this.id,
      @JsonKey(name: 'group_name') required this.groupName,
      @JsonKey(name: 'min_select') required this.minSelect,
      @JsonKey(name: 'max_select') required this.maxSelect,
      required final List<ModifierOption> options})
      : _options = options;

  factory _$ModifierGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModifierGroupImplFromJson(json);

  /// Unique identifier for the modifier group.
  @override
  final String id;

  /// Display name for the group (e.g. "Add-ons", "Sauces").
  @override
  @JsonKey(name: 'group_name')
  final String groupName;

  /// Minimum number of options the customer must select.
  @override
  @JsonKey(name: 'min_select')
  final int minSelect;

  /// Maximum number of options the customer may select.
  @override
  @JsonKey(name: 'max_select')
  final int maxSelect;

  /// Selectable options within this group.
  final List<ModifierOption> _options;

  /// Selectable options within this group.
  @override
  List<ModifierOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  String toString() {
    return 'ModifierGroup(id: $id, groupName: $groupName, minSelect: $minSelect, maxSelect: $maxSelect, options: $options)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModifierGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.minSelect, minSelect) ||
                other.minSelect == minSelect) &&
            (identical(other.maxSelect, maxSelect) ||
                other.maxSelect == maxSelect) &&
            const DeepCollectionEquality().equals(other._options, _options));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, groupName, minSelect,
      maxSelect, const DeepCollectionEquality().hash(_options));

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModifierGroupImplCopyWith<_$ModifierGroupImpl> get copyWith =>
      __$$ModifierGroupImplCopyWithImpl<_$ModifierGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModifierGroupImplToJson(
      this,
    );
  }
}

abstract class _ModifierGroup implements ModifierGroup {
  const factory _ModifierGroup(
      {required final String id,
      @JsonKey(name: 'group_name') required final String groupName,
      @JsonKey(name: 'min_select') required final int minSelect,
      @JsonKey(name: 'max_select') required final int maxSelect,
      required final List<ModifierOption> options}) = _$ModifierGroupImpl;

  factory _ModifierGroup.fromJson(Map<String, dynamic> json) =
      _$ModifierGroupImpl.fromJson;

  /// Unique identifier for the modifier group.
  @override
  String get id;

  /// Display name for the group (e.g. "Add-ons", "Sauces").
  @override
  @JsonKey(name: 'group_name')
  String get groupName;

  /// Minimum number of options the customer must select.
  @override
  @JsonKey(name: 'min_select')
  int get minSelect;

  /// Maximum number of options the customer may select.
  @override
  @JsonKey(name: 'max_select')
  int get maxSelect;

  /// Selectable options within this group.
  @override
  List<ModifierOption> get options;

  /// Create a copy of ModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModifierGroupImplCopyWith<_$ModifierGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) {
  return _MenuItem.fromJson(json);
}

/// @nodoc
mixin _$MenuItem {
  /// Unique identifier.
  String get id => throw _privateConstructorUsedError;

  /// Display name shown to customers and staff.
  String get name => throw _privateConstructorUsedError;

  /// The category this item belongs to.
  @JsonKey(name: 'category_id')
  String get categoryId => throw _privateConstructorUsedError;

  /// Base price before variants and modifiers.
  @JsonKey(name: 'base_price', fromJson: _parseDouble)
  double get basePrice => throw _privateConstructorUsedError;

  /// GST rate applied to this item (e.g. 5.0 for 5 %).
  @JsonKey(name: 'gst_rate', fromJson: _parseDouble)
  double get gstRate => throw _privateConstructorUsedError;

  /// Dietary classification per FSSAI standard.
  @JsonKey(name: 'dietary_type')
  DietaryType get dietaryType => throw _privateConstructorUsedError;

  /// Whether this item is currently available for ordering.
  @JsonKey(name: 'is_available')
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Available size/price variants; may be empty.
  List<ItemVariant> get variants => throw _privateConstructorUsedError;

  /// Modifier groups (add-ons, customisations); may be empty.
  @JsonKey(name: 'modifier_groups')
  List<ModifierGroup> get modifierGroups => throw _privateConstructorUsedError;

  /// Optional URL to the item image.
  @JsonKey(name: 'photo_url')
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this MenuItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuItemCopyWith<MenuItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuItemCopyWith<$Res> {
  factory $MenuItemCopyWith(MenuItem value, $Res Function(MenuItem) then) =
      _$MenuItemCopyWithImpl<$Res, MenuItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'category_id') String categoryId,
      @JsonKey(name: 'base_price', fromJson: _parseDouble) double basePrice,
      @JsonKey(name: 'gst_rate', fromJson: _parseDouble) double gstRate,
      @JsonKey(name: 'dietary_type') DietaryType dietaryType,
      @JsonKey(name: 'is_available') bool isAvailable,
      List<ItemVariant> variants,
      @JsonKey(name: 'modifier_groups') List<ModifierGroup> modifierGroups,
      @JsonKey(name: 'photo_url') String? imageUrl});
}

/// @nodoc
class _$MenuItemCopyWithImpl<$Res, $Val extends MenuItem>
    implements $MenuItemCopyWith<$Res> {
  _$MenuItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? basePrice = null,
    Object? gstRate = null,
    Object? dietaryType = null,
    Object? isAvailable = null,
    Object? variants = null,
    Object? modifierGroups = null,
    Object? imageUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      basePrice: null == basePrice
          ? _value.basePrice
          : basePrice // ignore: cast_nullable_to_non_nullable
              as double,
      gstRate: null == gstRate
          ? _value.gstRate
          : gstRate // ignore: cast_nullable_to_non_nullable
              as double,
      dietaryType: null == dietaryType
          ? _value.dietaryType
          : dietaryType // ignore: cast_nullable_to_non_nullable
              as DietaryType,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      variants: null == variants
          ? _value.variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<ItemVariant>,
      modifierGroups: null == modifierGroups
          ? _value.modifierGroups
          : modifierGroups // ignore: cast_nullable_to_non_nullable
              as List<ModifierGroup>,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MenuItemImplCopyWith<$Res>
    implements $MenuItemCopyWith<$Res> {
  factory _$$MenuItemImplCopyWith(
          _$MenuItemImpl value, $Res Function(_$MenuItemImpl) then) =
      __$$MenuItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'category_id') String categoryId,
      @JsonKey(name: 'base_price', fromJson: _parseDouble) double basePrice,
      @JsonKey(name: 'gst_rate', fromJson: _parseDouble) double gstRate,
      @JsonKey(name: 'dietary_type') DietaryType dietaryType,
      @JsonKey(name: 'is_available') bool isAvailable,
      List<ItemVariant> variants,
      @JsonKey(name: 'modifier_groups') List<ModifierGroup> modifierGroups,
      @JsonKey(name: 'photo_url') String? imageUrl});
}

/// @nodoc
class __$$MenuItemImplCopyWithImpl<$Res>
    extends _$MenuItemCopyWithImpl<$Res, _$MenuItemImpl>
    implements _$$MenuItemImplCopyWith<$Res> {
  __$$MenuItemImplCopyWithImpl(
      _$MenuItemImpl _value, $Res Function(_$MenuItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? categoryId = null,
    Object? basePrice = null,
    Object? gstRate = null,
    Object? dietaryType = null,
    Object? isAvailable = null,
    Object? variants = null,
    Object? modifierGroups = null,
    Object? imageUrl = freezed,
  }) {
    return _then(_$MenuItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      basePrice: null == basePrice
          ? _value.basePrice
          : basePrice // ignore: cast_nullable_to_non_nullable
              as double,
      gstRate: null == gstRate
          ? _value.gstRate
          : gstRate // ignore: cast_nullable_to_non_nullable
              as double,
      dietaryType: null == dietaryType
          ? _value.dietaryType
          : dietaryType // ignore: cast_nullable_to_non_nullable
              as DietaryType,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      variants: null == variants
          ? _value._variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<ItemVariant>,
      modifierGroups: null == modifierGroups
          ? _value._modifierGroups
          : modifierGroups // ignore: cast_nullable_to_non_nullable
              as List<ModifierGroup>,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuItemImpl implements _MenuItem {
  const _$MenuItemImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'category_id') required this.categoryId,
      @JsonKey(name: 'base_price', fromJson: _parseDouble)
      required this.basePrice,
      @JsonKey(name: 'gst_rate', fromJson: _parseDouble) required this.gstRate,
      @JsonKey(name: 'dietary_type') required this.dietaryType,
      @JsonKey(name: 'is_available') required this.isAvailable,
      final List<ItemVariant> variants = const [],
      @JsonKey(name: 'modifier_groups')
      final List<ModifierGroup> modifierGroups = const [],
      @JsonKey(name: 'photo_url') this.imageUrl})
      : _variants = variants,
        _modifierGroups = modifierGroups;

  factory _$MenuItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuItemImplFromJson(json);

  /// Unique identifier.
  @override
  final String id;

  /// Display name shown to customers and staff.
  @override
  final String name;

  /// The category this item belongs to.
  @override
  @JsonKey(name: 'category_id')
  final String categoryId;

  /// Base price before variants and modifiers.
  @override
  @JsonKey(name: 'base_price', fromJson: _parseDouble)
  final double basePrice;

  /// GST rate applied to this item (e.g. 5.0 for 5 %).
  @override
  @JsonKey(name: 'gst_rate', fromJson: _parseDouble)
  final double gstRate;

  /// Dietary classification per FSSAI standard.
  @override
  @JsonKey(name: 'dietary_type')
  final DietaryType dietaryType;

  /// Whether this item is currently available for ordering.
  @override
  @JsonKey(name: 'is_available')
  final bool isAvailable;

  /// Available size/price variants; may be empty.
  final List<ItemVariant> _variants;

  /// Available size/price variants; may be empty.
  @override
  @JsonKey()
  List<ItemVariant> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  /// Modifier groups (add-ons, customisations); may be empty.
  final List<ModifierGroup> _modifierGroups;

  /// Modifier groups (add-ons, customisations); may be empty.
  @override
  @JsonKey(name: 'modifier_groups')
  List<ModifierGroup> get modifierGroups {
    if (_modifierGroups is EqualUnmodifiableListView) return _modifierGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifierGroups);
  }

  /// Optional URL to the item image.
  @override
  @JsonKey(name: 'photo_url')
  final String? imageUrl;

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, categoryId: $categoryId, basePrice: $basePrice, gstRate: $gstRate, dietaryType: $dietaryType, isAvailable: $isAvailable, variants: $variants, modifierGroups: $modifierGroups, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.basePrice, basePrice) ||
                other.basePrice == basePrice) &&
            (identical(other.gstRate, gstRate) || other.gstRate == gstRate) &&
            (identical(other.dietaryType, dietaryType) ||
                other.dietaryType == dietaryType) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            const DeepCollectionEquality()
                .equals(other._modifierGroups, _modifierGroups) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      categoryId,
      basePrice,
      gstRate,
      dietaryType,
      isAvailable,
      const DeepCollectionEquality().hash(_variants),
      const DeepCollectionEquality().hash(_modifierGroups),
      imageUrl);

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuItemImplCopyWith<_$MenuItemImpl> get copyWith =>
      __$$MenuItemImplCopyWithImpl<_$MenuItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuItemImplToJson(
      this,
    );
  }
}

abstract class _MenuItem implements MenuItem {
  const factory _MenuItem(
      {required final String id,
      required final String name,
      @JsonKey(name: 'category_id') required final String categoryId,
      @JsonKey(name: 'base_price', fromJson: _parseDouble)
      required final double basePrice,
      @JsonKey(name: 'gst_rate', fromJson: _parseDouble)
      required final double gstRate,
      @JsonKey(name: 'dietary_type') required final DietaryType dietaryType,
      @JsonKey(name: 'is_available') required final bool isAvailable,
      final List<ItemVariant> variants,
      @JsonKey(name: 'modifier_groups')
      final List<ModifierGroup> modifierGroups,
      @JsonKey(name: 'photo_url') final String? imageUrl}) = _$MenuItemImpl;

  factory _MenuItem.fromJson(Map<String, dynamic> json) =
      _$MenuItemImpl.fromJson;

  /// Unique identifier.
  @override
  String get id;

  /// Display name shown to customers and staff.
  @override
  String get name;

  /// The category this item belongs to.
  @override
  @JsonKey(name: 'category_id')
  String get categoryId;

  /// Base price before variants and modifiers.
  @override
  @JsonKey(name: 'base_price', fromJson: _parseDouble)
  double get basePrice;

  /// GST rate applied to this item (e.g. 5.0 for 5 %).
  @override
  @JsonKey(name: 'gst_rate', fromJson: _parseDouble)
  double get gstRate;

  /// Dietary classification per FSSAI standard.
  @override
  @JsonKey(name: 'dietary_type')
  DietaryType get dietaryType;

  /// Whether this item is currently available for ordering.
  @override
  @JsonKey(name: 'is_available')
  bool get isAvailable;

  /// Available size/price variants; may be empty.
  @override
  List<ItemVariant> get variants;

  /// Modifier groups (add-ons, customisations); may be empty.
  @override
  @JsonKey(name: 'modifier_groups')
  List<ModifierGroup> get modifierGroups;

  /// Optional URL to the item image.
  @override
  @JsonKey(name: 'photo_url')
  String? get imageUrl;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuItemImplCopyWith<_$MenuItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
