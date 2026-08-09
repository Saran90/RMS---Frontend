// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GstSlab _$GstSlabFromJson(Map<String, dynamic> json) {
  return _GstSlab.fromJson(json);
}

/// @nodoc
mixin _$GstSlab {
  /// The GST rate for this slab (e.g. 5.0 for 5 %).
  @JsonKey(name: 'gst_rate')
  @_DoubleConverter()
  double get gstRate => throw _privateConstructorUsedError;

  /// The pre-tax value to which this rate applies.
  @JsonKey(name: 'taxable_value')
  @_DoubleConverter()
  double get taxableValue => throw _privateConstructorUsedError;

  /// The GST amount collected for this slab.
  @JsonKey(name: 'gst_amount')
  @_DoubleConverter()
  double get gstAmount => throw _privateConstructorUsedError;

  /// Serializes this GstSlab to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GstSlab
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GstSlabCopyWith<GstSlab> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GstSlabCopyWith<$Res> {
  factory $GstSlabCopyWith(GstSlab value, $Res Function(GstSlab) then) =
      _$GstSlabCopyWithImpl<$Res, GstSlab>;
  @useResult
  $Res call(
      {@JsonKey(name: 'gst_rate') @_DoubleConverter() double gstRate,
      @JsonKey(name: 'taxable_value') @_DoubleConverter() double taxableValue,
      @JsonKey(name: 'gst_amount') @_DoubleConverter() double gstAmount});
}

/// @nodoc
class _$GstSlabCopyWithImpl<$Res, $Val extends GstSlab>
    implements $GstSlabCopyWith<$Res> {
  _$GstSlabCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GstSlab
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gstRate = null,
    Object? taxableValue = null,
    Object? gstAmount = null,
  }) {
    return _then(_value.copyWith(
      gstRate: null == gstRate
          ? _value.gstRate
          : gstRate // ignore: cast_nullable_to_non_nullable
              as double,
      taxableValue: null == taxableValue
          ? _value.taxableValue
          : taxableValue // ignore: cast_nullable_to_non_nullable
              as double,
      gstAmount: null == gstAmount
          ? _value.gstAmount
          : gstAmount // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GstSlabImplCopyWith<$Res> implements $GstSlabCopyWith<$Res> {
  factory _$$GstSlabImplCopyWith(
          _$GstSlabImpl value, $Res Function(_$GstSlabImpl) then) =
      __$$GstSlabImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'gst_rate') @_DoubleConverter() double gstRate,
      @JsonKey(name: 'taxable_value') @_DoubleConverter() double taxableValue,
      @JsonKey(name: 'gst_amount') @_DoubleConverter() double gstAmount});
}

/// @nodoc
class __$$GstSlabImplCopyWithImpl<$Res>
    extends _$GstSlabCopyWithImpl<$Res, _$GstSlabImpl>
    implements _$$GstSlabImplCopyWith<$Res> {
  __$$GstSlabImplCopyWithImpl(
      _$GstSlabImpl _value, $Res Function(_$GstSlabImpl) _then)
      : super(_value, _then);

  /// Create a copy of GstSlab
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gstRate = null,
    Object? taxableValue = null,
    Object? gstAmount = null,
  }) {
    return _then(_$GstSlabImpl(
      gstRate: null == gstRate
          ? _value.gstRate
          : gstRate // ignore: cast_nullable_to_non_nullable
              as double,
      taxableValue: null == taxableValue
          ? _value.taxableValue
          : taxableValue // ignore: cast_nullable_to_non_nullable
              as double,
      gstAmount: null == gstAmount
          ? _value.gstAmount
          : gstAmount // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GstSlabImpl implements _GstSlab {
  const _$GstSlabImpl(
      {@JsonKey(name: 'gst_rate') @_DoubleConverter() required this.gstRate,
      @JsonKey(name: 'taxable_value')
      @_DoubleConverter()
      required this.taxableValue,
      @JsonKey(name: 'gst_amount')
      @_DoubleConverter()
      required this.gstAmount});

  factory _$GstSlabImpl.fromJson(Map<String, dynamic> json) =>
      _$$GstSlabImplFromJson(json);

  /// The GST rate for this slab (e.g. 5.0 for 5 %).
  @override
  @JsonKey(name: 'gst_rate')
  @_DoubleConverter()
  final double gstRate;

  /// The pre-tax value to which this rate applies.
  @override
  @JsonKey(name: 'taxable_value')
  @_DoubleConverter()
  final double taxableValue;

  /// The GST amount collected for this slab.
  @override
  @JsonKey(name: 'gst_amount')
  @_DoubleConverter()
  final double gstAmount;

  @override
  String toString() {
    return 'GstSlab(gstRate: $gstRate, taxableValue: $taxableValue, gstAmount: $gstAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GstSlabImpl &&
            (identical(other.gstRate, gstRate) || other.gstRate == gstRate) &&
            (identical(other.taxableValue, taxableValue) ||
                other.taxableValue == taxableValue) &&
            (identical(other.gstAmount, gstAmount) ||
                other.gstAmount == gstAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, gstRate, taxableValue, gstAmount);

  /// Create a copy of GstSlab
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GstSlabImplCopyWith<_$GstSlabImpl> get copyWith =>
      __$$GstSlabImplCopyWithImpl<_$GstSlabImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GstSlabImplToJson(
      this,
    );
  }
}

abstract class _GstSlab implements GstSlab {
  const factory _GstSlab(
      {@JsonKey(name: 'gst_rate')
      @_DoubleConverter()
      required final double gstRate,
      @JsonKey(name: 'taxable_value')
      @_DoubleConverter()
      required final double taxableValue,
      @JsonKey(name: 'gst_amount')
      @_DoubleConverter()
      required final double gstAmount}) = _$GstSlabImpl;

  factory _GstSlab.fromJson(Map<String, dynamic> json) = _$GstSlabImpl.fromJson;

  /// The GST rate for this slab (e.g. 5.0 for 5 %).
  @override
  @JsonKey(name: 'gst_rate')
  @_DoubleConverter()
  double get gstRate;

  /// The pre-tax value to which this rate applies.
  @override
  @JsonKey(name: 'taxable_value')
  @_DoubleConverter()
  double get taxableValue;

  /// The GST amount collected for this slab.
  @override
  @JsonKey(name: 'gst_amount')
  @_DoubleConverter()
  double get gstAmount;

  /// Create a copy of GstSlab
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GstSlabImplCopyWith<_$GstSlabImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Payment _$PaymentFromJson(Map<String, dynamic> json) {
  return _Payment.fromJson(json);
}

/// @nodoc
mixin _$Payment {
  /// Amount paid in this transaction.
  @_DoubleConverter()
  double get amount => throw _privateConstructorUsedError;

  /// Payment mode (e.g. "cash", "upi", "card").
  String? get mode => throw _privateConstructorUsedError;

  /// UTC timestamp when the payment was recorded.
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt => throw _privateConstructorUsedError;

  /// Unique identifier for the payment.
  String? get id => throw _privateConstructorUsedError;

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call(
      {@_DoubleConverter() double amount,
      String? mode,
      @JsonKey(name: 'paid_at') DateTime? paidAt,
      String? id});
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = null,
    Object? mode = freezed,
    Object? paidAt = freezed,
    Object? id = freezed,
  }) {
    return _then(_value.copyWith(
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      mode: freezed == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String?,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
          _$PaymentImpl value, $Res Function(_$PaymentImpl) then) =
      __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@_DoubleConverter() double amount,
      String? mode,
      @JsonKey(name: 'paid_at') DateTime? paidAt,
      String? id});
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
      _$PaymentImpl _value, $Res Function(_$PaymentImpl) _then)
      : super(_value, _then);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = null,
    Object? mode = freezed,
    Object? paidAt = freezed,
    Object? id = freezed,
  }) {
    return _then(_$PaymentImpl(
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      mode: freezed == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String?,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentImpl implements _Payment {
  const _$PaymentImpl(
      {@_DoubleConverter() required this.amount,
      this.mode,
      @JsonKey(name: 'paid_at') this.paidAt,
      this.id});

  factory _$PaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentImplFromJson(json);

  /// Amount paid in this transaction.
  @override
  @_DoubleConverter()
  final double amount;

  /// Payment mode (e.g. "cash", "upi", "card").
  @override
  final String? mode;

  /// UTC timestamp when the payment was recorded.
  @override
  @JsonKey(name: 'paid_at')
  final DateTime? paidAt;

  /// Unique identifier for the payment.
  @override
  final String? id;

  @override
  String toString() {
    return 'Payment(amount: $amount, mode: $mode, paidAt: $paidAt, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, amount, mode, paidAt, id);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentImplToJson(
      this,
    );
  }
}

abstract class _Payment implements Payment {
  const factory _Payment(
      {@_DoubleConverter() required final double amount,
      final String? mode,
      @JsonKey(name: 'paid_at') final DateTime? paidAt,
      final String? id}) = _$PaymentImpl;

  factory _Payment.fromJson(Map<String, dynamic> json) = _$PaymentImpl.fromJson;

  /// Amount paid in this transaction.
  @override
  @_DoubleConverter()
  double get amount;

  /// Payment mode (e.g. "cash", "upi", "card").
  @override
  String? get mode;

  /// UTC timestamp when the payment was recorded.
  @override
  @JsonKey(name: 'paid_at')
  DateTime? get paidAt;

  /// Unique identifier for the payment.
  @override
  String? get id;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Bill _$BillFromJson(Map<String, dynamic> json) {
  return _Bill.fromJson(json);
}

/// @nodoc
mixin _$Bill {
  /// Unique identifier.
  String get id => throw _privateConstructorUsedError;

  /// Reference to the [Order] this bill covers.
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;

  /// Sum of all item prices before tax.
  @_DoubleConverter()
  double get subtotal => throw _privateConstructorUsedError;

  /// Per-slab GST breakdown (one entry per distinct GST rate).
  @JsonKey(name: 'gst_breakdown')
  List<GstSlab> get gstBreakdown => throw _privateConstructorUsedError;

  /// Final total including GST.
  @_DoubleConverter()
  double get total => throw _privateConstructorUsedError;

  /// Current bill status (e.g. "open", "paid", "voided").
  String get status => throw _privateConstructorUsedError;

  /// Human-readable bill number for receipts and payment descriptions.
  @JsonKey(name: 'bill_number')
  @_NullableStringConverter()
  String? get billNumber => throw _privateConstructorUsedError;

  /// Razorpay order id set after payment initiation.
  @JsonKey(name: 'razorpay_order_id')
  String? get razorpayOrderId => throw _privateConstructorUsedError;

  /// Razorpay payment id set after successful verification.
  @JsonKey(name: 'razorpay_payment_id')
  String? get razorpayPaymentId => throw _privateConstructorUsedError;

  /// Payments applied to this bill.
  List<Payment> get payments => throw _privateConstructorUsedError;

  /// Serializes this Bill to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Bill
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BillCopyWith<Bill> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillCopyWith<$Res> {
  factory $BillCopyWith(Bill value, $Res Function(Bill) then) =
      _$BillCopyWithImpl<$Res, Bill>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      @_DoubleConverter() double subtotal,
      @JsonKey(name: 'gst_breakdown') List<GstSlab> gstBreakdown,
      @_DoubleConverter() double total,
      String status,
      @JsonKey(name: 'bill_number')
      @_NullableStringConverter()
      String? billNumber,
      @JsonKey(name: 'razorpay_order_id') String? razorpayOrderId,
      @JsonKey(name: 'razorpay_payment_id') String? razorpayPaymentId,
      List<Payment> payments});
}

/// @nodoc
class _$BillCopyWithImpl<$Res, $Val extends Bill>
    implements $BillCopyWith<$Res> {
  _$BillCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Bill
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? subtotal = null,
    Object? gstBreakdown = null,
    Object? total = null,
    Object? status = null,
    Object? billNumber = freezed,
    Object? razorpayOrderId = freezed,
    Object? razorpayPaymentId = freezed,
    Object? payments = null,
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
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      gstBreakdown: null == gstBreakdown
          ? _value.gstBreakdown
          : gstBreakdown // ignore: cast_nullable_to_non_nullable
              as List<GstSlab>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      billNumber: freezed == billNumber
          ? _value.billNumber
          : billNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      razorpayOrderId: freezed == razorpayOrderId
          ? _value.razorpayOrderId
          : razorpayOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      razorpayPaymentId: freezed == razorpayPaymentId
          ? _value.razorpayPaymentId
          : razorpayPaymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      payments: null == payments
          ? _value.payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BillImplCopyWith<$Res> implements $BillCopyWith<$Res> {
  factory _$$BillImplCopyWith(
          _$BillImpl value, $Res Function(_$BillImpl) then) =
      __$$BillImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      @_DoubleConverter() double subtotal,
      @JsonKey(name: 'gst_breakdown') List<GstSlab> gstBreakdown,
      @_DoubleConverter() double total,
      String status,
      @JsonKey(name: 'bill_number')
      @_NullableStringConverter()
      String? billNumber,
      @JsonKey(name: 'razorpay_order_id') String? razorpayOrderId,
      @JsonKey(name: 'razorpay_payment_id') String? razorpayPaymentId,
      List<Payment> payments});
}

/// @nodoc
class __$$BillImplCopyWithImpl<$Res>
    extends _$BillCopyWithImpl<$Res, _$BillImpl>
    implements _$$BillImplCopyWith<$Res> {
  __$$BillImplCopyWithImpl(_$BillImpl _value, $Res Function(_$BillImpl) _then)
      : super(_value, _then);

  /// Create a copy of Bill
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? subtotal = null,
    Object? gstBreakdown = null,
    Object? total = null,
    Object? status = null,
    Object? billNumber = freezed,
    Object? razorpayOrderId = freezed,
    Object? razorpayPaymentId = freezed,
    Object? payments = null,
  }) {
    return _then(_$BillImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      gstBreakdown: null == gstBreakdown
          ? _value._gstBreakdown
          : gstBreakdown // ignore: cast_nullable_to_non_nullable
              as List<GstSlab>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      billNumber: freezed == billNumber
          ? _value.billNumber
          : billNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      razorpayOrderId: freezed == razorpayOrderId
          ? _value.razorpayOrderId
          : razorpayOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      razorpayPaymentId: freezed == razorpayPaymentId
          ? _value.razorpayPaymentId
          : razorpayPaymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      payments: null == payments
          ? _value._payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BillImpl implements _Bill {
  const _$BillImpl(
      {required this.id,
      @JsonKey(name: 'order_id') required this.orderId,
      @_DoubleConverter() required this.subtotal,
      @JsonKey(name: 'gst_breakdown') required final List<GstSlab> gstBreakdown,
      @_DoubleConverter() required this.total,
      required this.status,
      @JsonKey(name: 'bill_number') @_NullableStringConverter() this.billNumber,
      @JsonKey(name: 'razorpay_order_id') this.razorpayOrderId,
      @JsonKey(name: 'razorpay_payment_id') this.razorpayPaymentId,
      final List<Payment> payments = const []})
      : _gstBreakdown = gstBreakdown,
        _payments = payments;

  factory _$BillImpl.fromJson(Map<String, dynamic> json) =>
      _$$BillImplFromJson(json);

  /// Unique identifier.
  @override
  final String id;

  /// Reference to the [Order] this bill covers.
  @override
  @JsonKey(name: 'order_id')
  final String orderId;

  /// Sum of all item prices before tax.
  @override
  @_DoubleConverter()
  final double subtotal;

  /// Per-slab GST breakdown (one entry per distinct GST rate).
  final List<GstSlab> _gstBreakdown;

  /// Per-slab GST breakdown (one entry per distinct GST rate).
  @override
  @JsonKey(name: 'gst_breakdown')
  List<GstSlab> get gstBreakdown {
    if (_gstBreakdown is EqualUnmodifiableListView) return _gstBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gstBreakdown);
  }

  /// Final total including GST.
  @override
  @_DoubleConverter()
  final double total;

  /// Current bill status (e.g. "open", "paid", "voided").
  @override
  final String status;

  /// Human-readable bill number for receipts and payment descriptions.
  @override
  @JsonKey(name: 'bill_number')
  @_NullableStringConverter()
  final String? billNumber;

  /// Razorpay order id set after payment initiation.
  @override
  @JsonKey(name: 'razorpay_order_id')
  final String? razorpayOrderId;

  /// Razorpay payment id set after successful verification.
  @override
  @JsonKey(name: 'razorpay_payment_id')
  final String? razorpayPaymentId;

  /// Payments applied to this bill.
  final List<Payment> _payments;

  /// Payments applied to this bill.
  @override
  @JsonKey()
  List<Payment> get payments {
    if (_payments is EqualUnmodifiableListView) return _payments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_payments);
  }

  @override
  String toString() {
    return 'Bill(id: $id, orderId: $orderId, subtotal: $subtotal, gstBreakdown: $gstBreakdown, total: $total, status: $status, billNumber: $billNumber, razorpayOrderId: $razorpayOrderId, razorpayPaymentId: $razorpayPaymentId, payments: $payments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            const DeepCollectionEquality()
                .equals(other._gstBreakdown, _gstBreakdown) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.billNumber, billNumber) ||
                other.billNumber == billNumber) &&
            (identical(other.razorpayOrderId, razorpayOrderId) ||
                other.razorpayOrderId == razorpayOrderId) &&
            (identical(other.razorpayPaymentId, razorpayPaymentId) ||
                other.razorpayPaymentId == razorpayPaymentId) &&
            const DeepCollectionEquality().equals(other._payments, _payments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      orderId,
      subtotal,
      const DeepCollectionEquality().hash(_gstBreakdown),
      total,
      status,
      billNumber,
      razorpayOrderId,
      razorpayPaymentId,
      const DeepCollectionEquality().hash(_payments));

  /// Create a copy of Bill
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BillImplCopyWith<_$BillImpl> get copyWith =>
      __$$BillImplCopyWithImpl<_$BillImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BillImplToJson(
      this,
    );
  }
}

abstract class _Bill implements Bill {
  const factory _Bill(
      {required final String id,
      @JsonKey(name: 'order_id') required final String orderId,
      @_DoubleConverter() required final double subtotal,
      @JsonKey(name: 'gst_breakdown') required final List<GstSlab> gstBreakdown,
      @_DoubleConverter() required final double total,
      required final String status,
      @JsonKey(name: 'bill_number')
      @_NullableStringConverter()
      final String? billNumber,
      @JsonKey(name: 'razorpay_order_id') final String? razorpayOrderId,
      @JsonKey(name: 'razorpay_payment_id') final String? razorpayPaymentId,
      final List<Payment> payments}) = _$BillImpl;

  factory _Bill.fromJson(Map<String, dynamic> json) = _$BillImpl.fromJson;

  /// Unique identifier.
  @override
  String get id;

  /// Reference to the [Order] this bill covers.
  @override
  @JsonKey(name: 'order_id')
  String get orderId;

  /// Sum of all item prices before tax.
  @override
  @_DoubleConverter()
  double get subtotal;

  /// Per-slab GST breakdown (one entry per distinct GST rate).
  @override
  @JsonKey(name: 'gst_breakdown')
  List<GstSlab> get gstBreakdown;

  /// Final total including GST.
  @override
  @_DoubleConverter()
  double get total;

  /// Current bill status (e.g. "open", "paid", "voided").
  @override
  String get status;

  /// Human-readable bill number for receipts and payment descriptions.
  @override
  @JsonKey(name: 'bill_number')
  @_NullableStringConverter()
  String? get billNumber;

  /// Razorpay order id set after payment initiation.
  @override
  @JsonKey(name: 'razorpay_order_id')
  String? get razorpayOrderId;

  /// Razorpay payment id set after successful verification.
  @override
  @JsonKey(name: 'razorpay_payment_id')
  String? get razorpayPaymentId;

  /// Payments applied to this bill.
  @override
  List<Payment> get payments;

  /// Create a copy of Bill
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BillImplCopyWith<_$BillImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
