import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// An active subscription plan for a restaurant tenant.
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    /// Unique identifier.
    required String id,

    /// Reference to the pricing plan.
    @JsonKey(name: 'plan_id') required String planId,

    /// Human-readable plan name (e.g. "Starter", "Pro").
    @JsonKey(name: 'plan_name') required String planName,

    /// Current subscription status (e.g. "active", "expired", "cancelled").
    required String status,

    /// UTC timestamp when the subscription expires.
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}
