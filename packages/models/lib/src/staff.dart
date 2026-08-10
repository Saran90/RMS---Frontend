import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:models/src/enums.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

/// A staff member belonging to a restaurant tenant.
@freezed
class Staff with _$Staff {
  const Staff._();

  const factory Staff({
    required String id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'full_name') required String fullName,
    String? email,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    required String username,
    required StaffRole role,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Staff;

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);

  bool get isActive => status == 'active';
  bool get isInvited => status == 'invited';

  /// Display name for UI.
  String get name => fullName;
}
