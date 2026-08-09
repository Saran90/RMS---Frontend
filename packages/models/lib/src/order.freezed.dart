// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) {
  return _OrderItem.fromJson(json);
}

/// @nodoc
mixin _$OrderItem {
  /// Unique identifier for this order item.
  String get id => throw _privateConstructorUsedError;

  /// Reference to the [MenuItem] ordered.
  @JsonKey(name: 'item_id')
  String get itemId => throw _privateConstructorUsedError;

  /// Snapshot of the item name at time of order — returned by API as `item_name`.
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;

  /// Number of units ordered.
  int get quantity => throw _privateConstructorUsedError;

  /// Price per unit.
  @JsonKey(name: 'unit_price')
  @_DoubleConverter()
  double get unitPrice => throw _privateConstructorUsedError;

  /// Total price for this line (unit_price × quantity + modifier_total).
  @JsonKey(name: 'item_total')
  @_DoubleConverter()
  double get itemTotal => throw _privateConstructorUsedError;

  /// Modifier total price.
  @JsonKey(name: 'modifier_total')
  @_DoubleConverter()
  double get modifierTotal => throw _privateConstructorUsedError;

  /// Modifier IDs.
  @JsonKey(name: 'modifier_ids')
  List<String> get modifierIds => throw _privateConstructorUsedError;

  /// ID of the chosen variant, if any.
  @JsonKey(name: 'variant_id')
  String? get variantId => throw _privateConstructorUsedError;

  /// Label of the chosen variant, if any.
  @JsonKey(name: 'variant_label')
  String? get variantLabel => throw _privateConstructorUsedError;

  /// Order reference.
  @JsonKey(name: 'order_id')
  String? get orderId => throw _privateConstructorUsedError;

  /// KDS status (queued, prepared, etc.).
  @JsonKey(name: 'kds_status')
  String? get kdsStatus => throw _privateConstructorUsedError;

  /// KDS station ID.
  @JsonKey(name: 'kds_station_id')
  String? get kdsStationId => throw _privateConstructorUsedError;

  /// KDS queued time.
  @JsonKey(name: 'kds_queued_at')
  DateTime? get kdsQueuedAt => throw _privateConstructorUsedError;

  /// Created at timestamp.
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemCopyWith<OrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCopyWith<$Res> {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) then) =
      _$OrderItemCopyWithImpl<$Res, OrderItem>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'item_id') String itemId,
      @JsonKey(name: 'item_name') String itemName,
      int quantity,
      @JsonKey(name: 'unit_price') @_DoubleConverter() double unitPrice,
      @JsonKey(name: 'item_total') @_DoubleConverter() double itemTotal,
      @JsonKey(name: 'modifier_total') @_DoubleConverter() double modifierTotal,
      @JsonKey(name: 'modifier_ids') List<String> modifierIds,
      @JsonKey(name: 'variant_id') String? variantId,
      @JsonKey(name: 'variant_label') String? variantLabel,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'kds_status') String? kdsStatus,
      @JsonKey(name: 'kds_station_id') String? kdsStationId,
      @JsonKey(name: 'kds_queued_at') DateTime? kdsQueuedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$OrderItemCopyWithImpl<$Res, $Val extends OrderItem>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? itemTotal = null,
    Object? modifierTotal = null,
    Object? modifierIds = null,
    Object? variantId = freezed,
    Object? variantLabel = freezed,
    Object? orderId = freezed,
    Object? kdsStatus = freezed,
    Object? kdsStationId = freezed,
    Object? kdsQueuedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      itemTotal: null == itemTotal
          ? _value.itemTotal
          : itemTotal // ignore: cast_nullable_to_non_nullable
              as double,
      modifierTotal: null == modifierTotal
          ? _value.modifierTotal
          : modifierTotal // ignore: cast_nullable_to_non_nullable
              as double,
      modifierIds: null == modifierIds
          ? _value.modifierIds
          : modifierIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      variantId: freezed == variantId
          ? _value.variantId
          : variantId // ignore: cast_nullable_to_non_nullable
              as String?,
      variantLabel: freezed == variantLabel
          ? _value.variantLabel
          : variantLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      kdsStatus: freezed == kdsStatus
          ? _value.kdsStatus
          : kdsStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      kdsStationId: freezed == kdsStationId
          ? _value.kdsStationId
          : kdsStationId // ignore: cast_nullable_to_non_nullable
              as String?,
      kdsQueuedAt: freezed == kdsQueuedAt
          ? _value.kdsQueuedAt
          : kdsQueuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderItemImplCopyWith<$Res>
    implements $OrderItemCopyWith<$Res> {
  factory _$$OrderItemImplCopyWith(
          _$OrderItemImpl value, $Res Function(_$OrderItemImpl) then) =
      __$$OrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'item_id') String itemId,
      @JsonKey(name: 'item_name') String itemName,
      int quantity,
      @JsonKey(name: 'unit_price') @_DoubleConverter() double unitPrice,
      @JsonKey(name: 'item_total') @_DoubleConverter() double itemTotal,
      @JsonKey(name: 'modifier_total') @_DoubleConverter() double modifierTotal,
      @JsonKey(name: 'modifier_ids') List<String> modifierIds,
      @JsonKey(name: 'variant_id') String? variantId,
      @JsonKey(name: 'variant_label') String? variantLabel,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'kds_status') String? kdsStatus,
      @JsonKey(name: 'kds_station_id') String? kdsStationId,
      @JsonKey(name: 'kds_queued_at') DateTime? kdsQueuedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$OrderItemImplCopyWithImpl<$Res>
    extends _$OrderItemCopyWithImpl<$Res, _$OrderItemImpl>
    implements _$$OrderItemImplCopyWith<$Res> {
  __$$OrderItemImplCopyWithImpl(
      _$OrderItemImpl _value, $Res Function(_$OrderItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? itemTotal = null,
    Object? modifierTotal = null,
    Object? modifierIds = null,
    Object? variantId = freezed,
    Object? variantLabel = freezed,
    Object? orderId = freezed,
    Object? kdsStatus = freezed,
    Object? kdsStationId = freezed,
    Object? kdsQueuedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$OrderItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      itemTotal: null == itemTotal
          ? _value.itemTotal
          : itemTotal // ignore: cast_nullable_to_non_nullable
              as double,
      modifierTotal: null == modifierTotal
          ? _value.modifierTotal
          : modifierTotal // ignore: cast_nullable_to_non_nullable
              as double,
      modifierIds: null == modifierIds
          ? _value._modifierIds
          : modifierIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      variantId: freezed == variantId
          ? _value.variantId
          : variantId // ignore: cast_nullable_to_non_nullable
              as String?,
      variantLabel: freezed == variantLabel
          ? _value.variantLabel
          : variantLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      kdsStatus: freezed == kdsStatus
          ? _value.kdsStatus
          : kdsStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      kdsStationId: freezed == kdsStationId
          ? _value.kdsStationId
          : kdsStationId // ignore: cast_nullable_to_non_nullable
              as String?,
      kdsQueuedAt: freezed == kdsQueuedAt
          ? _value.kdsQueuedAt
          : kdsQueuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemImpl implements _OrderItem {
  const _$OrderItemImpl(
      {required this.id,
      @JsonKey(name: 'item_id') required this.itemId,
      @JsonKey(name: 'item_name') required this.itemName,
      required this.quantity,
      @JsonKey(name: 'unit_price') @_DoubleConverter() required this.unitPrice,
      @JsonKey(name: 'item_total') @_DoubleConverter() required this.itemTotal,
      @JsonKey(name: 'modifier_total')
      @_DoubleConverter()
      this.modifierTotal = 0.0,
      @JsonKey(name: 'modifier_ids') final List<String> modifierIds = const [],
      @JsonKey(name: 'variant_id') this.variantId,
      @JsonKey(name: 'variant_label') this.variantLabel,
      @JsonKey(name: 'order_id') this.orderId,
      @JsonKey(name: 'kds_status') this.kdsStatus,
      @JsonKey(name: 'kds_station_id') this.kdsStationId,
      @JsonKey(name: 'kds_queued_at') this.kdsQueuedAt,
      @JsonKey(name: 'created_at') this.createdAt})
      : _modifierIds = modifierIds;

  factory _$OrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemImplFromJson(json);

  /// Unique identifier for this order item.
  @override
  final String id;

  /// Reference to the [MenuItem] ordered.
  @override
  @JsonKey(name: 'item_id')
  final String itemId;

  /// Snapshot of the item name at time of order — returned by API as `item_name`.
  @override
  @JsonKey(name: 'item_name')
  final String itemName;

  /// Number of units ordered.
  @override
  final int quantity;

  /// Price per unit.
  @override
  @JsonKey(name: 'unit_price')
  @_DoubleConverter()
  final double unitPrice;

  /// Total price for this line (unit_price × quantity + modifier_total).
  @override
  @JsonKey(name: 'item_total')
  @_DoubleConverter()
  final double itemTotal;

  /// Modifier total price.
  @override
  @JsonKey(name: 'modifier_total')
  @_DoubleConverter()
  final double modifierTotal;

  /// Modifier IDs.
  final List<String> _modifierIds;

  /// Modifier IDs.
  @override
  @JsonKey(name: 'modifier_ids')
  List<String> get modifierIds {
    if (_modifierIds is EqualUnmodifiableListView) return _modifierIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifierIds);
  }

  /// ID of the chosen variant, if any.
  @override
  @JsonKey(name: 'variant_id')
  final String? variantId;

  /// Label of the chosen variant, if any.
  @override
  @JsonKey(name: 'variant_label')
  final String? variantLabel;

  /// Order reference.
  @override
  @JsonKey(name: 'order_id')
  final String? orderId;

  /// KDS status (queued, prepared, etc.).
  @override
  @JsonKey(name: 'kds_status')
  final String? kdsStatus;

  /// KDS station ID.
  @override
  @JsonKey(name: 'kds_station_id')
  final String? kdsStationId;

  /// KDS queued time.
  @override
  @JsonKey(name: 'kds_queued_at')
  final DateTime? kdsQueuedAt;

  /// Created at timestamp.
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'OrderItem(id: $id, itemId: $itemId, itemName: $itemName, quantity: $quantity, unitPrice: $unitPrice, itemTotal: $itemTotal, modifierTotal: $modifierTotal, modifierIds: $modifierIds, variantId: $variantId, variantLabel: $variantLabel, orderId: $orderId, kdsStatus: $kdsStatus, kdsStationId: $kdsStationId, kdsQueuedAt: $kdsQueuedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.itemTotal, itemTotal) ||
                other.itemTotal == itemTotal) &&
            (identical(other.modifierTotal, modifierTotal) ||
                other.modifierTotal == modifierTotal) &&
            const DeepCollectionEquality()
                .equals(other._modifierIds, _modifierIds) &&
            (identical(other.variantId, variantId) ||
                other.variantId == variantId) &&
            (identical(other.variantLabel, variantLabel) ||
                other.variantLabel == variantLabel) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.kdsStatus, kdsStatus) ||
                other.kdsStatus == kdsStatus) &&
            (identical(other.kdsStationId, kdsStationId) ||
                other.kdsStationId == kdsStationId) &&
            (identical(other.kdsQueuedAt, kdsQueuedAt) ||
                other.kdsQueuedAt == kdsQueuedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      itemId,
      itemName,
      quantity,
      unitPrice,
      itemTotal,
      modifierTotal,
      const DeepCollectionEquality().hash(_modifierIds),
      variantId,
      variantLabel,
      orderId,
      kdsStatus,
      kdsStationId,
      kdsQueuedAt,
      createdAt);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      __$$OrderItemImplCopyWithImpl<_$OrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemImplToJson(
      this,
    );
  }
}

abstract class _OrderItem implements OrderItem {
  const factory _OrderItem(
          {required final String id,
          @JsonKey(name: 'item_id') required final String itemId,
          @JsonKey(name: 'item_name') required final String itemName,
          required final int quantity,
          @JsonKey(name: 'unit_price')
          @_DoubleConverter()
          required final double unitPrice,
          @JsonKey(name: 'item_total')
          @_DoubleConverter()
          required final double itemTotal,
          @JsonKey(name: 'modifier_total')
          @_DoubleConverter()
          final double modifierTotal,
          @JsonKey(name: 'modifier_ids') final List<String> modifierIds,
          @JsonKey(name: 'variant_id') final String? variantId,
          @JsonKey(name: 'variant_label') final String? variantLabel,
          @JsonKey(name: 'order_id') final String? orderId,
          @JsonKey(name: 'kds_status') final String? kdsStatus,
          @JsonKey(name: 'kds_station_id') final String? kdsStationId,
          @JsonKey(name: 'kds_queued_at') final DateTime? kdsQueuedAt,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$OrderItemImpl;

  factory _OrderItem.fromJson(Map<String, dynamic> json) =
      _$OrderItemImpl.fromJson;

  /// Unique identifier for this order item.
  @override
  String get id;

  /// Reference to the [MenuItem] ordered.
  @override
  @JsonKey(name: 'item_id')
  String get itemId;

  /// Snapshot of the item name at time of order — returned by API as `item_name`.
  @override
  @JsonKey(name: 'item_name')
  String get itemName;

  /// Number of units ordered.
  @override
  int get quantity;

  /// Price per unit.
  @override
  @JsonKey(name: 'unit_price')
  @_DoubleConverter()
  double get unitPrice;

  /// Total price for this line (unit_price × quantity + modifier_total).
  @override
  @JsonKey(name: 'item_total')
  @_DoubleConverter()
  double get itemTotal;

  /// Modifier total price.
  @override
  @JsonKey(name: 'modifier_total')
  @_DoubleConverter()
  double get modifierTotal;

  /// Modifier IDs.
  @override
  @JsonKey(name: 'modifier_ids')
  List<String> get modifierIds;

  /// ID of the chosen variant, if any.
  @override
  @JsonKey(name: 'variant_id')
  String? get variantId;

  /// Label of the chosen variant, if any.
  @override
  @JsonKey(name: 'variant_label')
  String? get variantLabel;

  /// Order reference.
  @override
  @JsonKey(name: 'order_id')
  String? get orderId;

  /// KDS status (queued, prepared, etc.).
  @override
  @JsonKey(name: 'kds_status')
  String? get kdsStatus;

  /// KDS station ID.
  @override
  @JsonKey(name: 'kds_station_id')
  String? get kdsStationId;

  /// KDS queued time.
  @override
  @JsonKey(name: 'kds_queued_at')
  DateTime? get kdsQueuedAt;

  /// Created at timestamp.
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Order _$OrderFromJson(Map<String, dynamic> json) {
  return _Order.fromJson(json);
}

/// @nodoc
mixin _$Order {
  /// Unique identifier.
  String get id => throw _privateConstructorUsedError;

  /// Fulfilment channel.
  @JsonKey(name: 'order_type')
  OrderType get orderType => throw _privateConstructorUsedError;

  /// Current lifecycle status.
  OrderStatus get status => throw _privateConstructorUsedError;

  /// UTC timestamp when the order was created.
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Line items included in this order (may be empty in list responses).
  List<OrderItem> get items => throw _privateConstructorUsedError;

  /// Sum of all item prices — returned as a string like "0.00".
  @JsonKey(name: 'subtotal')
  @_DoubleConverter()
  double get subtotal => throw _privateConstructorUsedError;

  /// Table reference; only present for [OrderType.dineIn] orders.
  @JsonKey(name: 'table_id')
  String? get tableId => throw _privateConstructorUsedError;

  /// Customer name (delivery/takeaway orders).
  @JsonKey(name: 'customer_name')
  String? get customerName => throw _privateConstructorUsedError;

  /// Customer phone (delivery orders).
  @JsonKey(name: 'customer_phone')
  String? get customerPhone => throw _privateConstructorUsedError;

  /// Delivery address (delivery orders).
  @JsonKey(name: 'delivery_address')
  String? get deliveryAddress => throw _privateConstructorUsedError;

  /// Reason if the order was cancelled.
  @JsonKey(name: 'cancel_reason')
  String? get cancelReason => throw _privateConstructorUsedError;

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCopyWith<Order> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) then) =
      _$OrderCopyWithImpl<$Res, Order>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_type') OrderType orderType,
      OrderStatus status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<OrderItem> items,
      @JsonKey(name: 'subtotal') @_DoubleConverter() double subtotal,
      @JsonKey(name: 'table_id') String? tableId,
      @JsonKey(name: 'customer_name') String? customerName,
      @JsonKey(name: 'customer_phone') String? customerPhone,
      @JsonKey(name: 'delivery_address') String? deliveryAddress,
      @JsonKey(name: 'cancel_reason') String? cancelReason});
}

/// @nodoc
class _$OrderCopyWithImpl<$Res, $Val extends Order>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderType = null,
    Object? status = null,
    Object? createdAt = null,
    Object? items = null,
    Object? subtotal = null,
    Object? tableId = freezed,
    Object? customerName = freezed,
    Object? customerPhone = freezed,
    Object? deliveryAddress = freezed,
    Object? cancelReason = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as OrderType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItem>,
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      tableId: freezed == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      deliveryAddress: freezed == deliveryAddress
          ? _value.deliveryAddress
          : deliveryAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      cancelReason: freezed == cancelReason
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderImplCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$$OrderImplCopyWith(
          _$OrderImpl value, $Res Function(_$OrderImpl) then) =
      __$$OrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_type') OrderType orderType,
      OrderStatus status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<OrderItem> items,
      @JsonKey(name: 'subtotal') @_DoubleConverter() double subtotal,
      @JsonKey(name: 'table_id') String? tableId,
      @JsonKey(name: 'customer_name') String? customerName,
      @JsonKey(name: 'customer_phone') String? customerPhone,
      @JsonKey(name: 'delivery_address') String? deliveryAddress,
      @JsonKey(name: 'cancel_reason') String? cancelReason});
}

/// @nodoc
class __$$OrderImplCopyWithImpl<$Res>
    extends _$OrderCopyWithImpl<$Res, _$OrderImpl>
    implements _$$OrderImplCopyWith<$Res> {
  __$$OrderImplCopyWithImpl(
      _$OrderImpl _value, $Res Function(_$OrderImpl) _then)
      : super(_value, _then);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderType = null,
    Object? status = null,
    Object? createdAt = null,
    Object? items = null,
    Object? subtotal = null,
    Object? tableId = freezed,
    Object? customerName = freezed,
    Object? customerPhone = freezed,
    Object? deliveryAddress = freezed,
    Object? cancelReason = freezed,
  }) {
    return _then(_$OrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as OrderType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItem>,
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      tableId: freezed == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      deliveryAddress: freezed == deliveryAddress
          ? _value.deliveryAddress
          : deliveryAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      cancelReason: freezed == cancelReason
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderImpl implements _Order {
  const _$OrderImpl(
      {required this.id,
      @JsonKey(name: 'order_type') required this.orderType,
      required this.status,
      @JsonKey(name: 'created_at') required this.createdAt,
      final List<OrderItem> items = const [],
      @JsonKey(name: 'subtotal') @_DoubleConverter() this.subtotal = 0.0,
      @JsonKey(name: 'table_id') this.tableId,
      @JsonKey(name: 'customer_name') this.customerName,
      @JsonKey(name: 'customer_phone') this.customerPhone,
      @JsonKey(name: 'delivery_address') this.deliveryAddress,
      @JsonKey(name: 'cancel_reason') this.cancelReason})
      : _items = items;

  factory _$OrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderImplFromJson(json);

  /// Unique identifier.
  @override
  final String id;

  /// Fulfilment channel.
  @override
  @JsonKey(name: 'order_type')
  final OrderType orderType;

  /// Current lifecycle status.
  @override
  final OrderStatus status;

  /// UTC timestamp when the order was created.
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Line items included in this order (may be empty in list responses).
  final List<OrderItem> _items;

  /// Line items included in this order (may be empty in list responses).
  @override
  @JsonKey()
  List<OrderItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Sum of all item prices — returned as a string like "0.00".
  @override
  @JsonKey(name: 'subtotal')
  @_DoubleConverter()
  final double subtotal;

  /// Table reference; only present for [OrderType.dineIn] orders.
  @override
  @JsonKey(name: 'table_id')
  final String? tableId;

  /// Customer name (delivery/takeaway orders).
  @override
  @JsonKey(name: 'customer_name')
  final String? customerName;

  /// Customer phone (delivery orders).
  @override
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;

  /// Delivery address (delivery orders).
  @override
  @JsonKey(name: 'delivery_address')
  final String? deliveryAddress;

  /// Reason if the order was cancelled.
  @override
  @JsonKey(name: 'cancel_reason')
  final String? cancelReason;

  @override
  String toString() {
    return 'Order(id: $id, orderType: $orderType, status: $status, createdAt: $createdAt, items: $items, subtotal: $subtotal, tableId: $tableId, customerName: $customerName, customerPhone: $customerPhone, deliveryAddress: $deliveryAddress, cancelReason: $cancelReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerPhone, customerPhone) ||
                other.customerPhone == customerPhone) &&
            (identical(other.deliveryAddress, deliveryAddress) ||
                other.deliveryAddress == deliveryAddress) &&
            (identical(other.cancelReason, cancelReason) ||
                other.cancelReason == cancelReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      orderType,
      status,
      createdAt,
      const DeepCollectionEquality().hash(_items),
      subtotal,
      tableId,
      customerName,
      customerPhone,
      deliveryAddress,
      cancelReason);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      __$$OrderImplCopyWithImpl<_$OrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderImplToJson(
      this,
    );
  }
}

abstract class _Order implements Order {
  const factory _Order(
          {required final String id,
          @JsonKey(name: 'order_type') required final OrderType orderType,
          required final OrderStatus status,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          final List<OrderItem> items,
          @JsonKey(name: 'subtotal') @_DoubleConverter() final double subtotal,
          @JsonKey(name: 'table_id') final String? tableId,
          @JsonKey(name: 'customer_name') final String? customerName,
          @JsonKey(name: 'customer_phone') final String? customerPhone,
          @JsonKey(name: 'delivery_address') final String? deliveryAddress,
          @JsonKey(name: 'cancel_reason') final String? cancelReason}) =
      _$OrderImpl;

  factory _Order.fromJson(Map<String, dynamic> json) = _$OrderImpl.fromJson;

  /// Unique identifier.
  @override
  String get id;

  /// Fulfilment channel.
  @override
  @JsonKey(name: 'order_type')
  OrderType get orderType;

  /// Current lifecycle status.
  @override
  OrderStatus get status;

  /// UTC timestamp when the order was created.
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Line items included in this order (may be empty in list responses).
  @override
  List<OrderItem> get items;

  /// Sum of all item prices — returned as a string like "0.00".
  @override
  @JsonKey(name: 'subtotal')
  @_DoubleConverter()
  double get subtotal;

  /// Table reference; only present for [OrderType.dineIn] orders.
  @override
  @JsonKey(name: 'table_id')
  String? get tableId;

  /// Customer name (delivery/takeaway orders).
  @override
  @JsonKey(name: 'customer_name')
  String? get customerName;

  /// Customer phone (delivery orders).
  @override
  @JsonKey(name: 'customer_phone')
  String? get customerPhone;

  /// Delivery address (delivery orders).
  @override
  @JsonKey(name: 'delivery_address')
  String? get deliveryAddress;

  /// Reason if the order was cancelled.
  @override
  @JsonKey(name: 'cancel_reason')
  String? get cancelReason;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
