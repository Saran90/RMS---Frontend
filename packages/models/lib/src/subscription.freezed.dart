// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) {
  return _Subscription.fromJson(json);
}

/// @nodoc
mixin _$Subscription {
  /// Unique identifier.
  String get id => throw _privateConstructorUsedError;

  /// Reference to the pricing plan.
  @JsonKey(name: 'plan_id')
  String get planId => throw _privateConstructorUsedError;

  /// Human-readable plan name (e.g. "Starter", "Pro").
  @JsonKey(name: 'plan_name')
  String get planName => throw _privateConstructorUsedError;

  /// Current subscription status (e.g. "active", "expired", "cancelled").
  String get status => throw _privateConstructorUsedError;

  /// UTC timestamp when the subscription expires.
  @JsonKey(name: 'expires_at')
  DateTime get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionCopyWith<Subscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionCopyWith<$Res> {
  factory $SubscriptionCopyWith(
          Subscription value, $Res Function(Subscription) then) =
      _$SubscriptionCopyWithImpl<$Res, Subscription>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'plan_id') String planId,
      @JsonKey(name: 'plan_name') String planName,
      String status,
      @JsonKey(name: 'expires_at') DateTime expiresAt});
}

/// @nodoc
class _$SubscriptionCopyWithImpl<$Res, $Val extends Subscription>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? planName = null,
    Object? status = null,
    Object? expiresAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      planName: null == planName
          ? _value.planName
          : planName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubscriptionImplCopyWith<$Res>
    implements $SubscriptionCopyWith<$Res> {
  factory _$$SubscriptionImplCopyWith(
          _$SubscriptionImpl value, $Res Function(_$SubscriptionImpl) then) =
      __$$SubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'plan_id') String planId,
      @JsonKey(name: 'plan_name') String planName,
      String status,
      @JsonKey(name: 'expires_at') DateTime expiresAt});
}

/// @nodoc
class __$$SubscriptionImplCopyWithImpl<$Res>
    extends _$SubscriptionCopyWithImpl<$Res, _$SubscriptionImpl>
    implements _$$SubscriptionImplCopyWith<$Res> {
  __$$SubscriptionImplCopyWithImpl(
      _$SubscriptionImpl _value, $Res Function(_$SubscriptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? planName = null,
    Object? status = null,
    Object? expiresAt = null,
  }) {
    return _then(_$SubscriptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      planName: null == planName
          ? _value.planName
          : planName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionImpl implements _Subscription {
  const _$SubscriptionImpl(
      {required this.id,
      @JsonKey(name: 'plan_id') required this.planId,
      @JsonKey(name: 'plan_name') required this.planName,
      required this.status,
      @JsonKey(name: 'expires_at') required this.expiresAt});

  factory _$SubscriptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionImplFromJson(json);

  /// Unique identifier.
  @override
  final String id;

  /// Reference to the pricing plan.
  @override
  @JsonKey(name: 'plan_id')
  final String planId;

  /// Human-readable plan name (e.g. "Starter", "Pro").
  @override
  @JsonKey(name: 'plan_name')
  final String planName;

  /// Current subscription status (e.g. "active", "expired", "cancelled").
  @override
  final String status;

  /// UTC timestamp when the subscription expires.
  @override
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  @override
  String toString() {
    return 'Subscription(id: $id, planId: $planId, planName: $planName, status: $status, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.planName, planName) ||
                other.planName == planName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, planId, planName, status, expiresAt);

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      __$$SubscriptionImplCopyWithImpl<_$SubscriptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionImplToJson(
      this,
    );
  }
}

abstract class _Subscription implements Subscription {
  const factory _Subscription(
          {required final String id,
          @JsonKey(name: 'plan_id') required final String planId,
          @JsonKey(name: 'plan_name') required final String planName,
          required final String status,
          @JsonKey(name: 'expires_at') required final DateTime expiresAt}) =
      _$SubscriptionImpl;

  factory _Subscription.fromJson(Map<String, dynamic> json) =
      _$SubscriptionImpl.fromJson;

  /// Unique identifier.
  @override
  String get id;

  /// Reference to the pricing plan.
  @override
  @JsonKey(name: 'plan_id')
  String get planId;

  /// Human-readable plan name (e.g. "Starter", "Pro").
  @override
  @JsonKey(name: 'plan_name')
  String get planName;

  /// Current subscription status (e.g. "active", "expired", "cancelled").
  @override
  String get status;

  /// UTC timestamp when the subscription expires.
  @override
  @JsonKey(name: 'expires_at')
  DateTime get expiresAt;

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
