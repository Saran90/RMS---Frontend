// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kds_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

KdsOrder _$KdsOrderFromJson(Map<String, dynamic> json) {
  return _KdsOrder.fromJson(json);
}

/// @nodoc
mixin _$KdsOrder {
  /// Order ID
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;

  /// Order type (dine_in, takeaway, delivery)
  @JsonKey(name: 'order_type')
  OrderType get orderType => throw _privateConstructorUsedError;

  /// Current order status
  @JsonKey(name: 'order_status')
  OrderStatus get orderStatus => throw _privateConstructorUsedError;

  /// Table ID (for dine-in orders)
  @JsonKey(name: 'table_id')
  String? get tableId => throw _privateConstructorUsedError;

  /// When the order was created
  @JsonKey(name: 'order_created_at')
  DateTime get orderCreatedAt => throw _privateConstructorUsedError;

  /// Items in this order
  List<KdsItem> get items => throw _privateConstructorUsedError;

  /// Serializes this KdsOrder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KdsOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KdsOrderCopyWith<KdsOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KdsOrderCopyWith<$Res> {
  factory $KdsOrderCopyWith(KdsOrder value, $Res Function(KdsOrder) then) =
      _$KdsOrderCopyWithImpl<$Res, KdsOrder>;
  @useResult
  $Res call(
      {@JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_type') OrderType orderType,
      @JsonKey(name: 'order_status') OrderStatus orderStatus,
      @JsonKey(name: 'table_id') String? tableId,
      @JsonKey(name: 'order_created_at') DateTime orderCreatedAt,
      List<KdsItem> items});
}

/// @nodoc
class _$KdsOrderCopyWithImpl<$Res, $Val extends KdsOrder>
    implements $KdsOrderCopyWith<$Res> {
  _$KdsOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KdsOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? orderType = null,
    Object? orderStatus = null,
    Object? tableId = freezed,
    Object? orderCreatedAt = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as OrderType,
      orderStatus: null == orderStatus
          ? _value.orderStatus
          : orderStatus // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      tableId: freezed == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderCreatedAt: null == orderCreatedAt
          ? _value.orderCreatedAt
          : orderCreatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<KdsItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$KdsOrderImplCopyWith<$Res>
    implements $KdsOrderCopyWith<$Res> {
  factory _$$KdsOrderImplCopyWith(
          _$KdsOrderImpl value, $Res Function(_$KdsOrderImpl) then) =
      __$$KdsOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_type') OrderType orderType,
      @JsonKey(name: 'order_status') OrderStatus orderStatus,
      @JsonKey(name: 'table_id') String? tableId,
      @JsonKey(name: 'order_created_at') DateTime orderCreatedAt,
      List<KdsItem> items});
}

/// @nodoc
class __$$KdsOrderImplCopyWithImpl<$Res>
    extends _$KdsOrderCopyWithImpl<$Res, _$KdsOrderImpl>
    implements _$$KdsOrderImplCopyWith<$Res> {
  __$$KdsOrderImplCopyWithImpl(
      _$KdsOrderImpl _value, $Res Function(_$KdsOrderImpl) _then)
      : super(_value, _then);

  /// Create a copy of KdsOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? orderType = null,
    Object? orderStatus = null,
    Object? tableId = freezed,
    Object? orderCreatedAt = null,
    Object? items = null,
  }) {
    return _then(_$KdsOrderImpl(
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as OrderType,
      orderStatus: null == orderStatus
          ? _value.orderStatus
          : orderStatus // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      tableId: freezed == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderCreatedAt: null == orderCreatedAt
          ? _value.orderCreatedAt
          : orderCreatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<KdsItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KdsOrderImpl implements _KdsOrder {
  const _$KdsOrderImpl(
      {@JsonKey(name: 'order_id') required this.orderId,
      @JsonKey(name: 'order_type') required this.orderType,
      @JsonKey(name: 'order_status') required this.orderStatus,
      @JsonKey(name: 'table_id') this.tableId,
      @JsonKey(name: 'order_created_at') required this.orderCreatedAt,
      final List<KdsItem> items = const []})
      : _items = items;

  factory _$KdsOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$KdsOrderImplFromJson(json);

  /// Order ID
  @override
  @JsonKey(name: 'order_id')
  final String orderId;

  /// Order type (dine_in, takeaway, delivery)
  @override
  @JsonKey(name: 'order_type')
  final OrderType orderType;

  /// Current order status
  @override
  @JsonKey(name: 'order_status')
  final OrderStatus orderStatus;

  /// Table ID (for dine-in orders)
  @override
  @JsonKey(name: 'table_id')
  final String? tableId;

  /// When the order was created
  @override
  @JsonKey(name: 'order_created_at')
  final DateTime orderCreatedAt;

  /// Items in this order
  final List<KdsItem> _items;

  /// Items in this order
  @override
  @JsonKey()
  List<KdsItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'KdsOrder(orderId: $orderId, orderType: $orderType, orderStatus: $orderStatus, tableId: $tableId, orderCreatedAt: $orderCreatedAt, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KdsOrderImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            (identical(other.orderStatus, orderStatus) ||
                other.orderStatus == orderStatus) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.orderCreatedAt, orderCreatedAt) ||
                other.orderCreatedAt == orderCreatedAt) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, orderId, orderType, orderStatus,
      tableId, orderCreatedAt, const DeepCollectionEquality().hash(_items));

  /// Create a copy of KdsOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KdsOrderImplCopyWith<_$KdsOrderImpl> get copyWith =>
      __$$KdsOrderImplCopyWithImpl<_$KdsOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KdsOrderImplToJson(
      this,
    );
  }
}

abstract class _KdsOrder implements KdsOrder {
  const factory _KdsOrder(
      {@JsonKey(name: 'order_id') required final String orderId,
      @JsonKey(name: 'order_type') required final OrderType orderType,
      @JsonKey(name: 'order_status') required final OrderStatus orderStatus,
      @JsonKey(name: 'table_id') final String? tableId,
      @JsonKey(name: 'order_created_at') required final DateTime orderCreatedAt,
      final List<KdsItem> items}) = _$KdsOrderImpl;

  factory _KdsOrder.fromJson(Map<String, dynamic> json) =
      _$KdsOrderImpl.fromJson;

  /// Order ID
  @override
  @JsonKey(name: 'order_id')
  String get orderId;

  /// Order type (dine_in, takeaway, delivery)
  @override
  @JsonKey(name: 'order_type')
  OrderType get orderType;

  /// Current order status
  @override
  @JsonKey(name: 'order_status')
  OrderStatus get orderStatus;

  /// Table ID (for dine-in orders)
  @override
  @JsonKey(name: 'table_id')
  String? get tableId;

  /// When the order was created
  @override
  @JsonKey(name: 'order_created_at')
  DateTime get orderCreatedAt;

  /// Items in this order
  @override
  List<KdsItem> get items;

  /// Create a copy of KdsOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KdsOrderImplCopyWith<_$KdsOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
