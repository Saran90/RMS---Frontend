// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Table _$TableFromJson(Map<String, dynamic> json) {
  return _Table.fromJson(json);
}

/// @nodoc
mixin _$Table {
  /// Unique identifier.
  String get id => throw _privateConstructorUsedError;

  /// Human-readable table label (e.g. "T-01").
  @JsonKey(name: 'table_number')
  String get tableNumber => throw _privateConstructorUsedError;

  /// Floor section (e.g. "Main Hall", "Outdoor").
  @JsonKey(name: 'section_label')
  String? get sectionLabel => throw _privateConstructorUsedError;

  /// Current occupancy status.
  TableStatus get status => throw _privateConstructorUsedError;

  /// ID of the active order on this table, if any.
  @JsonKey(name: 'current_order_id')
  String? get currentOrderId => throw _privateConstructorUsedError;

  /// URL of the QR code customers scan for self-ordering.
  @JsonKey(name: 'qr_url')
  String? get qrUrl =>
      throw _privateConstructorUsedError; // ── Reservation fields (populated when status == reserved) ────────────
  @JsonKey(name: 'reservation_name')
  String? get reservationName => throw _privateConstructorUsedError;
  @JsonKey(name: 'reservation_phone')
  String? get reservationPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'reserved_for')
  DateTime? get reservedFor => throw _privateConstructorUsedError;
  @JsonKey(name: 'reserved_until')
  DateTime? get reservedUntil => throw _privateConstructorUsedError;

  /// Serializes this Table to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Table
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TableCopyWith<Table> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TableCopyWith<$Res> {
  factory $TableCopyWith(Table value, $Res Function(Table) then) =
      _$TableCopyWithImpl<$Res, Table>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'table_number') String tableNumber,
      @JsonKey(name: 'section_label') String? sectionLabel,
      TableStatus status,
      @JsonKey(name: 'current_order_id') String? currentOrderId,
      @JsonKey(name: 'qr_url') String? qrUrl,
      @JsonKey(name: 'reservation_name') String? reservationName,
      @JsonKey(name: 'reservation_phone') String? reservationPhone,
      @JsonKey(name: 'reserved_for') DateTime? reservedFor,
      @JsonKey(name: 'reserved_until') DateTime? reservedUntil});
}

/// @nodoc
class _$TableCopyWithImpl<$Res, $Val extends Table>
    implements $TableCopyWith<$Res> {
  _$TableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Table
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableNumber = null,
    Object? sectionLabel = freezed,
    Object? status = null,
    Object? currentOrderId = freezed,
    Object? qrUrl = freezed,
    Object? reservationName = freezed,
    Object? reservationPhone = freezed,
    Object? reservedFor = freezed,
    Object? reservedUntil = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tableNumber: null == tableNumber
          ? _value.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionLabel: freezed == sectionLabel
          ? _value.sectionLabel
          : sectionLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TableStatus,
      currentOrderId: freezed == currentOrderId
          ? _value.currentOrderId
          : currentOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      qrUrl: freezed == qrUrl
          ? _value.qrUrl
          : qrUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      reservationName: freezed == reservationName
          ? _value.reservationName
          : reservationName // ignore: cast_nullable_to_non_nullable
              as String?,
      reservationPhone: freezed == reservationPhone
          ? _value.reservationPhone
          : reservationPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      reservedFor: freezed == reservedFor
          ? _value.reservedFor
          : reservedFor // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reservedUntil: freezed == reservedUntil
          ? _value.reservedUntil
          : reservedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TableImplCopyWith<$Res> implements $TableCopyWith<$Res> {
  factory _$$TableImplCopyWith(
          _$TableImpl value, $Res Function(_$TableImpl) then) =
      __$$TableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'table_number') String tableNumber,
      @JsonKey(name: 'section_label') String? sectionLabel,
      TableStatus status,
      @JsonKey(name: 'current_order_id') String? currentOrderId,
      @JsonKey(name: 'qr_url') String? qrUrl,
      @JsonKey(name: 'reservation_name') String? reservationName,
      @JsonKey(name: 'reservation_phone') String? reservationPhone,
      @JsonKey(name: 'reserved_for') DateTime? reservedFor,
      @JsonKey(name: 'reserved_until') DateTime? reservedUntil});
}

/// @nodoc
class __$$TableImplCopyWithImpl<$Res>
    extends _$TableCopyWithImpl<$Res, _$TableImpl>
    implements _$$TableImplCopyWith<$Res> {
  __$$TableImplCopyWithImpl(
      _$TableImpl _value, $Res Function(_$TableImpl) _then)
      : super(_value, _then);

  /// Create a copy of Table
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableNumber = null,
    Object? sectionLabel = freezed,
    Object? status = null,
    Object? currentOrderId = freezed,
    Object? qrUrl = freezed,
    Object? reservationName = freezed,
    Object? reservationPhone = freezed,
    Object? reservedFor = freezed,
    Object? reservedUntil = freezed,
  }) {
    return _then(_$TableImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tableNumber: null == tableNumber
          ? _value.tableNumber
          : tableNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionLabel: freezed == sectionLabel
          ? _value.sectionLabel
          : sectionLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TableStatus,
      currentOrderId: freezed == currentOrderId
          ? _value.currentOrderId
          : currentOrderId // ignore: cast_nullable_to_non_nullable
              as String?,
      qrUrl: freezed == qrUrl
          ? _value.qrUrl
          : qrUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      reservationName: freezed == reservationName
          ? _value.reservationName
          : reservationName // ignore: cast_nullable_to_non_nullable
              as String?,
      reservationPhone: freezed == reservationPhone
          ? _value.reservationPhone
          : reservationPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      reservedFor: freezed == reservedFor
          ? _value.reservedFor
          : reservedFor // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reservedUntil: freezed == reservedUntil
          ? _value.reservedUntil
          : reservedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TableImpl implements _Table {
  const _$TableImpl(
      {required this.id,
      @JsonKey(name: 'table_number') required this.tableNumber,
      @JsonKey(name: 'section_label') this.sectionLabel,
      required this.status,
      @JsonKey(name: 'current_order_id') this.currentOrderId,
      @JsonKey(name: 'qr_url') this.qrUrl,
      @JsonKey(name: 'reservation_name') this.reservationName,
      @JsonKey(name: 'reservation_phone') this.reservationPhone,
      @JsonKey(name: 'reserved_for') this.reservedFor,
      @JsonKey(name: 'reserved_until') this.reservedUntil});

  factory _$TableImpl.fromJson(Map<String, dynamic> json) =>
      _$$TableImplFromJson(json);

  /// Unique identifier.
  @override
  final String id;

  /// Human-readable table label (e.g. "T-01").
  @override
  @JsonKey(name: 'table_number')
  final String tableNumber;

  /// Floor section (e.g. "Main Hall", "Outdoor").
  @override
  @JsonKey(name: 'section_label')
  final String? sectionLabel;

  /// Current occupancy status.
  @override
  final TableStatus status;

  /// ID of the active order on this table, if any.
  @override
  @JsonKey(name: 'current_order_id')
  final String? currentOrderId;

  /// URL of the QR code customers scan for self-ordering.
  @override
  @JsonKey(name: 'qr_url')
  final String? qrUrl;
// ── Reservation fields (populated when status == reserved) ────────────
  @override
  @JsonKey(name: 'reservation_name')
  final String? reservationName;
  @override
  @JsonKey(name: 'reservation_phone')
  final String? reservationPhone;
  @override
  @JsonKey(name: 'reserved_for')
  final DateTime? reservedFor;
  @override
  @JsonKey(name: 'reserved_until')
  final DateTime? reservedUntil;

  @override
  String toString() {
    return 'Table(id: $id, tableNumber: $tableNumber, sectionLabel: $sectionLabel, status: $status, currentOrderId: $currentOrderId, qrUrl: $qrUrl, reservationName: $reservationName, reservationPhone: $reservationPhone, reservedFor: $reservedFor, reservedUntil: $reservedUntil)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TableImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.sectionLabel, sectionLabel) ||
                other.sectionLabel == sectionLabel) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentOrderId, currentOrderId) ||
                other.currentOrderId == currentOrderId) &&
            (identical(other.qrUrl, qrUrl) || other.qrUrl == qrUrl) &&
            (identical(other.reservationName, reservationName) ||
                other.reservationName == reservationName) &&
            (identical(other.reservationPhone, reservationPhone) ||
                other.reservationPhone == reservationPhone) &&
            (identical(other.reservedFor, reservedFor) ||
                other.reservedFor == reservedFor) &&
            (identical(other.reservedUntil, reservedUntil) ||
                other.reservedUntil == reservedUntil));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tableNumber,
      sectionLabel,
      status,
      currentOrderId,
      qrUrl,
      reservationName,
      reservationPhone,
      reservedFor,
      reservedUntil);

  /// Create a copy of Table
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TableImplCopyWith<_$TableImpl> get copyWith =>
      __$$TableImplCopyWithImpl<_$TableImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TableImplToJson(
      this,
    );
  }
}

abstract class _Table implements Table {
  const factory _Table(
          {required final String id,
          @JsonKey(name: 'table_number') required final String tableNumber,
          @JsonKey(name: 'section_label') final String? sectionLabel,
          required final TableStatus status,
          @JsonKey(name: 'current_order_id') final String? currentOrderId,
          @JsonKey(name: 'qr_url') final String? qrUrl,
          @JsonKey(name: 'reservation_name') final String? reservationName,
          @JsonKey(name: 'reservation_phone') final String? reservationPhone,
          @JsonKey(name: 'reserved_for') final DateTime? reservedFor,
          @JsonKey(name: 'reserved_until') final DateTime? reservedUntil}) =
      _$TableImpl;

  factory _Table.fromJson(Map<String, dynamic> json) = _$TableImpl.fromJson;

  /// Unique identifier.
  @override
  String get id;

  /// Human-readable table label (e.g. "T-01").
  @override
  @JsonKey(name: 'table_number')
  String get tableNumber;

  /// Floor section (e.g. "Main Hall", "Outdoor").
  @override
  @JsonKey(name: 'section_label')
  String? get sectionLabel;

  /// Current occupancy status.
  @override
  TableStatus get status;

  /// ID of the active order on this table, if any.
  @override
  @JsonKey(name: 'current_order_id')
  String? get currentOrderId;

  /// URL of the QR code customers scan for self-ordering.
  @override
  @JsonKey(name: 'qr_url')
  String?
      get qrUrl; // ── Reservation fields (populated when status == reserved) ────────────
  @override
  @JsonKey(name: 'reservation_name')
  String? get reservationName;
  @override
  @JsonKey(name: 'reservation_phone')
  String? get reservationPhone;
  @override
  @JsonKey(name: 'reserved_for')
  DateTime? get reservedFor;
  @override
  @JsonKey(name: 'reserved_until')
  DateTime? get reservedUntil;

  /// Create a copy of Table
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TableImplCopyWith<_$TableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
