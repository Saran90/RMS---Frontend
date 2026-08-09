import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant.freezed.dart';
part 'restaurant.g.dart';

/// Opening hours for a single day of the week.
@freezed
class BusinessHours with _$BusinessHours {
  const factory BusinessHours({
    /// ISO day of week (1 = Monday … 7 = Sunday).
    @JsonKey(name: 'day_of_week') required int dayOfWeek,

    /// Opening time in HH:MM format (24-hour).
    @JsonKey(name: 'open_time') required String openTime,

    /// Closing time in HH:MM format (24-hour).
    @JsonKey(name: 'close_time') required String closeTime,

    /// Whether the restaurant is closed on this day.
    @JsonKey(name: 'is_closed') @Default(false) bool isClosed,
  }) = _BusinessHours;

  factory BusinessHours.fromJson(Map<String, dynamic> json) =>
      _$BusinessHoursFromJson(json);
}

/// A restaurant tenant managed within the RMS platform.
@freezed
class Restaurant with _$Restaurant {
  const factory Restaurant({
    /// Unique identifier.
    required String id,

    /// Trading name of the restaurant.
    required String name,

    /// Physical address.
    required String address,

    /// Contact phone number.
    required String phone,

    /// GSTIN (Goods and Services Tax Identification Number).
    @JsonKey(name: 'gst_number') required String gstNumber,

    /// Optional URL of the restaurant logo.
    @JsonKey(name: 'logo_url') String? logoUrl,

    /// Weekly business hours (up to 7 entries, one per day).
    @JsonKey(name: 'business_hours')
    @Default([])
    List<BusinessHours> businessHours,
  }) = _Restaurant;

  factory Restaurant.fromJson(Map<String, dynamic> json) =>
      _$RestaurantFromJson(json);
}
