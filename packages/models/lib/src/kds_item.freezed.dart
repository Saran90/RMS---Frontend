// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kds_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

KdsItem _$KdsItemFromJson(Map<String, dynamic> json) {
  return _KdsItem.fromJson(json);
}

/// @nodoc
mixin _$KdsItem {
  /// ID of this order item (used for status updates).
  String get id => throw _privateConstructorUsedError;

  /// ID of the parent order.
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;

  /// ID of the menu item.
  @JsonKey(name: 'item_id')
  String get itemId => throw _privateConstructorUsedError;

  /// Display name of the item shown on the KDS card.
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;

  /// Number of units to prepare.
  int get quantity => throw _privateConstructorUsedError;

  /// Current processing status on the KDS.
  @JsonKey(name: 'kds_status')
  KdsItemStatus get kdsStatus => throw _privateConstructorUsedError;

  /// UTC timestamp when the order was placed (used for elapsed-time calc).
  @JsonKey(name: 'order_created_at')
  DateTime get orderCreatedAt => throw _privateConstructorUsedError;

  /// UTC timestamp when this item was queued on the KDS.
  @JsonKey(name: 'kds_queued_at')
  DateTime? get kdsQueuedAt => throw _privateConstructorUsedError;

  /// UTC timestamp when this item was created.
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Whether this item has exceeded its alert threshold.
  @JsonKey(name: 'is_overdue')
  bool get isOverdue => throw _privateConstructorUsedError;

  /// Alert threshold in minutes (null = use default).
  @JsonKey(name: 'kds_alert_threshold_minutes')
  int? get kdsAlertThresholdMinutes => throw _privateConstructorUsedError;

  /// KDS station this item is routed to (null = default station).
  @JsonKey(name: 'kds_station_id')
  String? get kdsStationId => throw _privateConstructorUsedError;

  /// Modifier IDs applied to this item.
  @JsonKey(name: 'modifier_ids')
  List<String> get modifierIds => throw _privateConstructorUsedError;

  /// Variant ID, if any.
  @JsonKey(name: 'variant_id')
  String? get variantId => throw _privateConstructorUsedError;

  /// Unit price.
  @JsonKey(name: 'unit_price')
  @_DoubleConverter()
  double get unitPrice => throw _privateConstructorUsedError;

  /// Modifier total.
  @JsonKey(name: 'modifier_total')
  @_DoubleConverter()
  double get modifierTotal => throw _privateConstructorUsedError;

  /// Serializes this KdsItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KdsItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KdsItemCopyWith<KdsItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KdsItemCopyWith<$Res> {
  factory $KdsItemCopyWith(KdsItem value, $Res Function(KdsItem) then) =
      _$KdsItemCopyWithImpl<$Res, KdsItem>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'item_id') String itemId,
      @JsonKey(name: 'item_name') String itemName,
      int quantity,
      @JsonKey(name: 'kds_status') KdsItemStatus kdsStatus,
      @JsonKey(name: 'order_created_at') DateTime orderCreatedAt,
      @JsonKey(name: 'kds_queued_at') DateTime? kdsQueuedAt,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'is_overdue') bool isOverdue,
      @JsonKey(name: 'kds_alert_threshold_minutes')
      int? kdsAlertThresholdMinutes,
      @JsonKey(name: 'kds_station_id') String? kdsStationId,
      @JsonKey(name: 'modifier_ids') List<String> modifierIds,
      @JsonKey(name: 'variant_id') String? variantId,
      @JsonKey(name: 'unit_price') @_DoubleConverter() double unitPrice,
      @JsonKey(name: 'modifier_total')
      @_DoubleConverter()
      double modifierTotal});
}

/// @nodoc
class _$KdsItemCopyWithImpl<$Res, $Val extends KdsItem>
    implements $KdsItemCopyWith<$Res> {
  _$KdsItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KdsItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? quantity = null,
    Object? kdsStatus = null,
    Object? orderCreatedAt = null,
    Object? kdsQueuedAt = freezed,
    Object? createdAt = null,
    Object? isOverdue = null,
    Object? kdsAlertThresholdMinutes = freezed,
    Object? kdsStationId = freezed,
    Object? modifierIds = null,
    Object? variantId = freezed,
    Object? unitPrice = null,
    Object? modifierTotal = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: null == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      kdsStatus: null == kdsStatus
          ? _value.kdsStatus
          : kdsStatus // ignore: cast_nullable_to_non_nullable
              as KdsItemStatus,
      orderCreatedAt: null == orderCreatedAt
          ? _value.orderCreatedAt
          : orderCreatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      kdsQueuedAt: freezed == kdsQueuedAt
          ? _value.kdsQueuedAt
          : kdsQueuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isOverdue: null == isOverdue
          ? _value.isOverdue
          : isOverdue // ignore: cast_nullable_to_non_nullable
              as bool,
      kdsAlertThresholdMinutes: freezed == kdsAlertThresholdMinutes
          ? _value.kdsAlertThresholdMinutes
          : kdsAlertThresholdMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      kdsStationId: freezed == kdsStationId
          ? _value.kdsStationId
          : kdsStationId // ignore: cast_nullable_to_non_nullable
              as String?,
      modifierIds: null == modifierIds
          ? _value.modifierIds
          : modifierIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      variantId: freezed == variantId
          ? _value.variantId
          : variantId // ignore: cast_nullable_to_non_nullable
              as String?,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      modifierTotal: null == modifierTotal
          ? _value.modifierTotal
          : modifierTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$KdsItemImplCopyWith<$Res> implements $KdsItemCopyWith<$Res> {
  factory _$$KdsItemImplCopyWith(
          _$KdsItemImpl value, $Res Function(_$KdsItemImpl) then) =
      __$$KdsItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'item_id') String itemId,
      @JsonKey(name: 'item_name') String itemName,
      int quantity,
      @JsonKey(name: 'kds_status') KdsItemStatus kdsStatus,
      @JsonKey(name: 'order_created_at') DateTime orderCreatedAt,
      @JsonKey(name: 'kds_queued_at') DateTime? kdsQueuedAt,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'is_overdue') bool isOverdue,
      @JsonKey(name: 'kds_alert_threshold_minutes')
      int? kdsAlertThresholdMinutes,
      @JsonKey(name: 'kds_station_id') String? kdsStationId,
      @JsonKey(name: 'modifier_ids') List<String> modifierIds,
      @JsonKey(name: 'variant_id') String? variantId,
      @JsonKey(name: 'unit_price') @_DoubleConverter() double unitPrice,
      @JsonKey(name: 'modifier_total')
      @_DoubleConverter()
      double modifierTotal});
}

/// @nodoc
class __$$KdsItemImplCopyWithImpl<$Res>
    extends _$KdsItemCopyWithImpl<$Res, _$KdsItemImpl>
    implements _$$KdsItemImplCopyWith<$Res> {
  __$$KdsItemImplCopyWithImpl(
      _$KdsItemImpl _value, $Res Function(_$KdsItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of KdsItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? quantity = null,
    Object? kdsStatus = null,
    Object? orderCreatedAt = null,
    Object? kdsQueuedAt = freezed,
    Object? createdAt = null,
    Object? isOverdue = null,
    Object? kdsAlertThresholdMinutes = freezed,
    Object? kdsStationId = freezed,
    Object? modifierIds = null,
    Object? variantId = freezed,
    Object? unitPrice = null,
    Object? modifierTotal = null,
  }) {
    return _then(_$KdsItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: null == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      kdsStatus: null == kdsStatus
          ? _value.kdsStatus
          : kdsStatus // ignore: cast_nullable_to_non_nullable
              as KdsItemStatus,
      orderCreatedAt: null == orderCreatedAt
          ? _value.orderCreatedAt
          : orderCreatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      kdsQueuedAt: freezed == kdsQueuedAt
          ? _value.kdsQueuedAt
          : kdsQueuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isOverdue: null == isOverdue
          ? _value.isOverdue
          : isOverdue // ignore: cast_nullable_to_non_nullable
              as bool,
      kdsAlertThresholdMinutes: freezed == kdsAlertThresholdMinutes
          ? _value.kdsAlertThresholdMinutes
          : kdsAlertThresholdMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      kdsStationId: freezed == kdsStationId
          ? _value.kdsStationId
          : kdsStationId // ignore: cast_nullable_to_non_nullable
              as String?,
      modifierIds: null == modifierIds
          ? _value._modifierIds
          : modifierIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      variantId: freezed == variantId
          ? _value.variantId
          : variantId // ignore: cast_nullable_to_non_nullable
              as String?,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      modifierTotal: null == modifierTotal
          ? _value.modifierTotal
          : modifierTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KdsItemImpl implements _KdsItem {
  const _$KdsItemImpl(
      {required this.id,
      @JsonKey(name: 'order_id') required this.orderId,
      @JsonKey(name: 'item_id') required this.itemId,
      @JsonKey(name: 'item_name') required this.itemName,
      required this.quantity,
      @JsonKey(name: 'kds_status') required this.kdsStatus,
      @JsonKey(name: 'order_created_at') required this.orderCreatedAt,
      @JsonKey(name: 'kds_queued_at') this.kdsQueuedAt,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'is_overdue') this.isOverdue = false,
      @JsonKey(name: 'kds_alert_threshold_minutes')
      this.kdsAlertThresholdMinutes,
      @JsonKey(name: 'kds_station_id') this.kdsStationId,
      @JsonKey(name: 'modifier_ids') final List<String> modifierIds = const [],
      @JsonKey(name: 'variant_id') this.variantId,
      @JsonKey(name: 'unit_price') @_DoubleConverter() this.unitPrice = 0.0,
      @JsonKey(name: 'modifier_total')
      @_DoubleConverter()
      this.modifierTotal = 0.0})
      : _modifierIds = modifierIds;

  factory _$KdsItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$KdsItemImplFromJson(json);

  /// ID of this order item (used for status updates).
  @override
  final String id;

  /// ID of the parent order.
  @override
  @JsonKey(name: 'order_id')
  final String orderId;

  /// ID of the menu item.
  @override
  @JsonKey(name: 'item_id')
  final String itemId;

  /// Display name of the item shown on the KDS card.
  @override
  @JsonKey(name: 'item_name')
  final String itemName;

  /// Number of units to prepare.
  @override
  final int quantity;

  /// Current processing status on the KDS.
  @override
  @JsonKey(name: 'kds_status')
  final KdsItemStatus kdsStatus;

  /// UTC timestamp when the order was placed (used for elapsed-time calc).
  @override
  @JsonKey(name: 'order_created_at')
  final DateTime orderCreatedAt;

  /// UTC timestamp when this item was queued on the KDS.
  @override
  @JsonKey(name: 'kds_queued_at')
  final DateTime? kdsQueuedAt;

  /// UTC timestamp when this item was created.
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Whether this item has exceeded its alert threshold.
  @override
  @JsonKey(name: 'is_overdue')
  final bool isOverdue;

  /// Alert threshold in minutes (null = use default).
  @override
  @JsonKey(name: 'kds_alert_threshold_minutes')
  final int? kdsAlertThresholdMinutes;

  /// KDS station this item is routed to (null = default station).
  @override
  @JsonKey(name: 'kds_station_id')
  final String? kdsStationId;

  /// Modifier IDs applied to this item.
  final List<String> _modifierIds;

  /// Modifier IDs applied to this item.
  @override
  @JsonKey(name: 'modifier_ids')
  List<String> get modifierIds {
    if (_modifierIds is EqualUnmodifiableListView) return _modifierIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifierIds);
  }

  /// Variant ID, if any.
  @override
  @JsonKey(name: 'variant_id')
  final String? variantId;

  /// Unit price.
  @override
  @JsonKey(name: 'unit_price')
  @_DoubleConverter()
  final double unitPrice;

  /// Modifier total.
  @override
  @JsonKey(name: 'modifier_total')
  @_DoubleConverter()
  final double modifierTotal;

  @override
  String toString() {
    return 'KdsItem(id: $id, orderId: $orderId, itemId: $itemId, itemName: $itemName, quantity: $quantity, kdsStatus: $kdsStatus, orderCreatedAt: $orderCreatedAt, kdsQueuedAt: $kdsQueuedAt, createdAt: $createdAt, isOverdue: $isOverdue, kdsAlertThresholdMinutes: $kdsAlertThresholdMinutes, kdsStationId: $kdsStationId, modifierIds: $modifierIds, variantId: $variantId, unitPrice: $unitPrice, modifierTotal: $modifierTotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KdsItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.kdsStatus, kdsStatus) ||
                other.kdsStatus == kdsStatus) &&
            (identical(other.orderCreatedAt, orderCreatedAt) ||
                other.orderCreatedAt == orderCreatedAt) &&
            (identical(other.kdsQueuedAt, kdsQueuedAt) ||
                other.kdsQueuedAt == kdsQueuedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isOverdue, isOverdue) ||
                other.isOverdue == isOverdue) &&
            (identical(
                    other.kdsAlertThresholdMinutes, kdsAlertThresholdMinutes) ||
                other.kdsAlertThresholdMinutes == kdsAlertThresholdMinutes) &&
            (identical(other.kdsStationId, kdsStationId) ||
                other.kdsStationId == kdsStationId) &&
            const DeepCollectionEquality()
                .equals(other._modifierIds, _modifierIds) &&
            (identical(other.variantId, variantId) ||
                other.variantId == variantId) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.modifierTotal, modifierTotal) ||
                other.modifierTotal == modifierTotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      orderId,
      itemId,
      itemName,
      quantity,
      kdsStatus,
      orderCreatedAt,
      kdsQueuedAt,
      createdAt,
      isOverdue,
      kdsAlertThresholdMinutes,
      kdsStationId,
      const DeepCollectionEquality().hash(_modifierIds),
      variantId,
      unitPrice,
      modifierTotal);

  /// Create a copy of KdsItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KdsItemImplCopyWith<_$KdsItemImpl> get copyWith =>
      __$$KdsItemImplCopyWithImpl<_$KdsItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KdsItemImplToJson(
      this,
    );
  }
}

abstract class _KdsItem implements KdsItem {
  const factory _KdsItem(
      {required final String id,
      @JsonKey(name: 'order_id') required final String orderId,
      @JsonKey(name: 'item_id') required final String itemId,
      @JsonKey(name: 'item_name') required final String itemName,
      required final int quantity,
      @JsonKey(name: 'kds_status') required final KdsItemStatus kdsStatus,
      @JsonKey(name: 'order_created_at') required final DateTime orderCreatedAt,
      @JsonKey(name: 'kds_queued_at') final DateTime? kdsQueuedAt,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'is_overdue') final bool isOverdue,
      @JsonKey(name: 'kds_alert_threshold_minutes')
      final int? kdsAlertThresholdMinutes,
      @JsonKey(name: 'kds_station_id') final String? kdsStationId,
      @JsonKey(name: 'modifier_ids') final List<String> modifierIds,
      @JsonKey(name: 'variant_id') final String? variantId,
      @JsonKey(name: 'unit_price') @_DoubleConverter() final double unitPrice,
      @JsonKey(name: 'modifier_total')
      @_DoubleConverter()
      final double modifierTotal}) = _$KdsItemImpl;

  factory _KdsItem.fromJson(Map<String, dynamic> json) = _$KdsItemImpl.fromJson;

  /// ID of this order item (used for status updates).
  @override
  String get id;

  /// ID of the parent order.
  @override
  @JsonKey(name: 'order_id')
  String get orderId;

  /// ID of the menu item.
  @override
  @JsonKey(name: 'item_id')
  String get itemId;

  /// Display name of the item shown on the KDS card.
  @override
  @JsonKey(name: 'item_name')
  String get itemName;

  /// Number of units to prepare.
  @override
  int get quantity;

  /// Current processing status on the KDS.
  @override
  @JsonKey(name: 'kds_status')
  KdsItemStatus get kdsStatus;

  /// UTC timestamp when the order was placed (used for elapsed-time calc).
  @override
  @JsonKey(name: 'order_created_at')
  DateTime get orderCreatedAt;

  /// UTC timestamp when this item was queued on the KDS.
  @override
  @JsonKey(name: 'kds_queued_at')
  DateTime? get kdsQueuedAt;

  /// UTC timestamp when this item was created.
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Whether this item has exceeded its alert threshold.
  @override
  @JsonKey(name: 'is_overdue')
  bool get isOverdue;

  /// Alert threshold in minutes (null = use default).
  @override
  @JsonKey(name: 'kds_alert_threshold_minutes')
  int? get kdsAlertThresholdMinutes;

  /// KDS station this item is routed to (null = default station).
  @override
  @JsonKey(name: 'kds_station_id')
  String? get kdsStationId;

  /// Modifier IDs applied to this item.
  @override
  @JsonKey(name: 'modifier_ids')
  List<String> get modifierIds;

  /// Variant ID, if any.
  @override
  @JsonKey(name: 'variant_id')
  String? get variantId;

  /// Unit price.
  @override
  @JsonKey(name: 'unit_price')
  @_DoubleConverter()
  double get unitPrice;

  /// Modifier total.
  @override
  @JsonKey(name: 'modifier_total')
  @_DoubleConverter()
  double get modifierTotal;

  /// Create a copy of KdsItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KdsItemImplCopyWith<_$KdsItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
