// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BusinessHours _$BusinessHoursFromJson(Map<String, dynamic> json) {
  return _BusinessHours.fromJson(json);
}

/// @nodoc
mixin _$BusinessHours {
  /// ISO day of week (1 = Monday … 7 = Sunday).
  @JsonKey(name: 'day_of_week')
  int get dayOfWeek => throw _privateConstructorUsedError;

  /// Opening time in HH:MM format (24-hour).
  @JsonKey(name: 'open_time')
  String get openTime => throw _privateConstructorUsedError;

  /// Closing time in HH:MM format (24-hour).
  @JsonKey(name: 'close_time')
  String get closeTime => throw _privateConstructorUsedError;

  /// Whether the restaurant is closed on this day.
  @JsonKey(name: 'is_closed')
  bool get isClosed => throw _privateConstructorUsedError;

  /// Serializes this BusinessHours to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusinessHoursCopyWith<BusinessHours> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusinessHoursCopyWith<$Res> {
  factory $BusinessHoursCopyWith(
          BusinessHours value, $Res Function(BusinessHours) then) =
      _$BusinessHoursCopyWithImpl<$Res, BusinessHours>;
  @useResult
  $Res call(
      {@JsonKey(name: 'day_of_week') int dayOfWeek,
      @JsonKey(name: 'open_time') String openTime,
      @JsonKey(name: 'close_time') String closeTime,
      @JsonKey(name: 'is_closed') bool isClosed});
}

/// @nodoc
class _$BusinessHoursCopyWithImpl<$Res, $Val extends BusinessHours>
    implements $BusinessHoursCopyWith<$Res> {
  _$BusinessHoursCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayOfWeek = null,
    Object? openTime = null,
    Object? closeTime = null,
    Object? isClosed = null,
  }) {
    return _then(_value.copyWith(
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      openTime: null == openTime
          ? _value.openTime
          : openTime // ignore: cast_nullable_to_non_nullable
              as String,
      closeTime: null == closeTime
          ? _value.closeTime
          : closeTime // ignore: cast_nullable_to_non_nullable
              as String,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BusinessHoursImplCopyWith<$Res>
    implements $BusinessHoursCopyWith<$Res> {
  factory _$$BusinessHoursImplCopyWith(
          _$BusinessHoursImpl value, $Res Function(_$BusinessHoursImpl) then) =
      __$$BusinessHoursImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'day_of_week') int dayOfWeek,
      @JsonKey(name: 'open_time') String openTime,
      @JsonKey(name: 'close_time') String closeTime,
      @JsonKey(name: 'is_closed') bool isClosed});
}

/// @nodoc
class __$$BusinessHoursImplCopyWithImpl<$Res>
    extends _$BusinessHoursCopyWithImpl<$Res, _$BusinessHoursImpl>
    implements _$$BusinessHoursImplCopyWith<$Res> {
  __$$BusinessHoursImplCopyWithImpl(
      _$BusinessHoursImpl _value, $Res Function(_$BusinessHoursImpl) _then)
      : super(_value, _then);

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayOfWeek = null,
    Object? openTime = null,
    Object? closeTime = null,
    Object? isClosed = null,
  }) {
    return _then(_$BusinessHoursImpl(
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      openTime: null == openTime
          ? _value.openTime
          : openTime // ignore: cast_nullable_to_non_nullable
              as String,
      closeTime: null == closeTime
          ? _value.closeTime
          : closeTime // ignore: cast_nullable_to_non_nullable
              as String,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BusinessHoursImpl implements _BusinessHours {
  const _$BusinessHoursImpl(
      {@JsonKey(name: 'day_of_week') required this.dayOfWeek,
      @JsonKey(name: 'open_time') required this.openTime,
      @JsonKey(name: 'close_time') required this.closeTime,
      @JsonKey(name: 'is_closed') this.isClosed = false});

  factory _$BusinessHoursImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusinessHoursImplFromJson(json);

  /// ISO day of week (1 = Monday … 7 = Sunday).
  @override
  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;

  /// Opening time in HH:MM format (24-hour).
  @override
  @JsonKey(name: 'open_time')
  final String openTime;

  /// Closing time in HH:MM format (24-hour).
  @override
  @JsonKey(name: 'close_time')
  final String closeTime;

  /// Whether the restaurant is closed on this day.
  @override
  @JsonKey(name: 'is_closed')
  final bool isClosed;

  @override
  String toString() {
    return 'BusinessHours(dayOfWeek: $dayOfWeek, openTime: $openTime, closeTime: $closeTime, isClosed: $isClosed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusinessHoursImpl &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.openTime, openTime) ||
                other.openTime == openTime) &&
            (identical(other.closeTime, closeTime) ||
                other.closeTime == closeTime) &&
            (identical(other.isClosed, isClosed) ||
                other.isClosed == isClosed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, dayOfWeek, openTime, closeTime, isClosed);

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusinessHoursImplCopyWith<_$BusinessHoursImpl> get copyWith =>
      __$$BusinessHoursImplCopyWithImpl<_$BusinessHoursImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BusinessHoursImplToJson(
      this,
    );
  }
}

abstract class _BusinessHours implements BusinessHours {
  const factory _BusinessHours(
      {@JsonKey(name: 'day_of_week') required final int dayOfWeek,
      @JsonKey(name: 'open_time') required final String openTime,
      @JsonKey(name: 'close_time') required final String closeTime,
      @JsonKey(name: 'is_closed') final bool isClosed}) = _$BusinessHoursImpl;

  factory _BusinessHours.fromJson(Map<String, dynamic> json) =
      _$BusinessHoursImpl.fromJson;

  /// ISO day of week (1 = Monday … 7 = Sunday).
  @override
  @JsonKey(name: 'day_of_week')
  int get dayOfWeek;

  /// Opening time in HH:MM format (24-hour).
  @override
  @JsonKey(name: 'open_time')
  String get openTime;

  /// Closing time in HH:MM format (24-hour).
  @override
  @JsonKey(name: 'close_time')
  String get closeTime;

  /// Whether the restaurant is closed on this day.
  @override
  @JsonKey(name: 'is_closed')
  bool get isClosed;

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusinessHoursImplCopyWith<_$BusinessHoursImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Restaurant _$RestaurantFromJson(Map<String, dynamic> json) {
  return _Restaurant.fromJson(json);
}

/// @nodoc
mixin _$Restaurant {
  /// Unique identifier.
  String get id => throw _privateConstructorUsedError;

  /// Trading name of the restaurant.
  String get name => throw _privateConstructorUsedError;

  /// Physical address.
  String get address => throw _privateConstructorUsedError;

  /// Contact phone number.
  String get phone => throw _privateConstructorUsedError;

  /// GSTIN (Goods and Services Tax Identification Number).
  @JsonKey(name: 'gst_number')
  String get gstNumber => throw _privateConstructorUsedError;

  /// Optional URL of the restaurant logo.
  @JsonKey(name: 'logo_url')
  String? get logoUrl => throw _privateConstructorUsedError;

  /// Weekly business hours (up to 7 entries, one per day).
  @JsonKey(name: 'business_hours')
  List<BusinessHours> get businessHours => throw _privateConstructorUsedError;

  /// Serializes this Restaurant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Restaurant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestaurantCopyWith<Restaurant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestaurantCopyWith<$Res> {
  factory $RestaurantCopyWith(
          Restaurant value, $Res Function(Restaurant) then) =
      _$RestaurantCopyWithImpl<$Res, Restaurant>;
  @useResult
  $Res call(
      {String id,
      String name,
      String address,
      String phone,
      @JsonKey(name: 'gst_number') String gstNumber,
      @JsonKey(name: 'logo_url') String? logoUrl,
      @JsonKey(name: 'business_hours') List<BusinessHours> businessHours});
}

/// @nodoc
class _$RestaurantCopyWithImpl<$Res, $Val extends Restaurant>
    implements $RestaurantCopyWith<$Res> {
  _$RestaurantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Restaurant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? phone = null,
    Object? gstNumber = null,
    Object? logoUrl = freezed,
    Object? businessHours = null,
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
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      gstNumber: null == gstNumber
          ? _value.gstNumber
          : gstNumber // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      businessHours: null == businessHours
          ? _value.businessHours
          : businessHours // ignore: cast_nullable_to_non_nullable
              as List<BusinessHours>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RestaurantImplCopyWith<$Res>
    implements $RestaurantCopyWith<$Res> {
  factory _$$RestaurantImplCopyWith(
          _$RestaurantImpl value, $Res Function(_$RestaurantImpl) then) =
      __$$RestaurantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String address,
      String phone,
      @JsonKey(name: 'gst_number') String gstNumber,
      @JsonKey(name: 'logo_url') String? logoUrl,
      @JsonKey(name: 'business_hours') List<BusinessHours> businessHours});
}

/// @nodoc
class __$$RestaurantImplCopyWithImpl<$Res>
    extends _$RestaurantCopyWithImpl<$Res, _$RestaurantImpl>
    implements _$$RestaurantImplCopyWith<$Res> {
  __$$RestaurantImplCopyWithImpl(
      _$RestaurantImpl _value, $Res Function(_$RestaurantImpl) _then)
      : super(_value, _then);

  /// Create a copy of Restaurant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? phone = null,
    Object? gstNumber = null,
    Object? logoUrl = freezed,
    Object? businessHours = null,
  }) {
    return _then(_$RestaurantImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      gstNumber: null == gstNumber
          ? _value.gstNumber
          : gstNumber // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      businessHours: null == businessHours
          ? _value._businessHours
          : businessHours // ignore: cast_nullable_to_non_nullable
              as List<BusinessHours>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RestaurantImpl implements _Restaurant {
  const _$RestaurantImpl(
      {required this.id,
      required this.name,
      required this.address,
      required this.phone,
      @JsonKey(name: 'gst_number') required this.gstNumber,
      @JsonKey(name: 'logo_url') this.logoUrl,
      @JsonKey(name: 'business_hours')
      final List<BusinessHours> businessHours = const []})
      : _businessHours = businessHours;

  factory _$RestaurantImpl.fromJson(Map<String, dynamic> json) =>
      _$$RestaurantImplFromJson(json);

  /// Unique identifier.
  @override
  final String id;

  /// Trading name of the restaurant.
  @override
  final String name;

  /// Physical address.
  @override
  final String address;

  /// Contact phone number.
  @override
  final String phone;

  /// GSTIN (Goods and Services Tax Identification Number).
  @override
  @JsonKey(name: 'gst_number')
  final String gstNumber;

  /// Optional URL of the restaurant logo.
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  /// Weekly business hours (up to 7 entries, one per day).
  final List<BusinessHours> _businessHours;

  /// Weekly business hours (up to 7 entries, one per day).
  @override
  @JsonKey(name: 'business_hours')
  List<BusinessHours> get businessHours {
    if (_businessHours is EqualUnmodifiableListView) return _businessHours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_businessHours);
  }

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, address: $address, phone: $phone, gstNumber: $gstNumber, logoUrl: $logoUrl, businessHours: $businessHours)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestaurantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.gstNumber, gstNumber) ||
                other.gstNumber == gstNumber) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            const DeepCollectionEquality()
                .equals(other._businessHours, _businessHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, address, phone,
      gstNumber, logoUrl, const DeepCollectionEquality().hash(_businessHours));

  /// Create a copy of Restaurant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestaurantImplCopyWith<_$RestaurantImpl> get copyWith =>
      __$$RestaurantImplCopyWithImpl<_$RestaurantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RestaurantImplToJson(
      this,
    );
  }
}

abstract class _Restaurant implements Restaurant {
  const factory _Restaurant(
      {required final String id,
      required final String name,
      required final String address,
      required final String phone,
      @JsonKey(name: 'gst_number') required final String gstNumber,
      @JsonKey(name: 'logo_url') final String? logoUrl,
      @JsonKey(name: 'business_hours')
      final List<BusinessHours> businessHours}) = _$RestaurantImpl;

  factory _Restaurant.fromJson(Map<String, dynamic> json) =
      _$RestaurantImpl.fromJson;

  /// Unique identifier.
  @override
  String get id;

  /// Trading name of the restaurant.
  @override
  String get name;

  /// Physical address.
  @override
  String get address;

  /// Contact phone number.
  @override
  String get phone;

  /// GSTIN (Goods and Services Tax Identification Number).
  @override
  @JsonKey(name: 'gst_number')
  String get gstNumber;

  /// Optional URL of the restaurant logo.
  @override
  @JsonKey(name: 'logo_url')
  String? get logoUrl;

  /// Weekly business hours (up to 7 entries, one per day).
  @override
  @JsonKey(name: 'business_hours')
  List<BusinessHours> get businessHours;

  /// Create a copy of Restaurant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestaurantImplCopyWith<_$RestaurantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
