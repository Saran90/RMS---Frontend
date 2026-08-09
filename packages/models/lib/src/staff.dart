import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:models/src/enums.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

/// A staff member belonging to a restaurant tenant.
@freezed
class Staff with _$Staff {
  const Staff._(); // Enable custom methods

  const factory Staff({
    /// Unique identifier.
    required String id,

    /// Email address (used for login and invitations).
    required String email,

    /// Role that governs navigation visibility and permissions.
    required StaffRole role,

    /// Staff status: "invited", "active", or "inactive".
    required String status,

    /// Timestamp when the staff member was created.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Timestamp when the staff member was last updated.
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Staff;

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);

  /// Returns true if staff status is "active".
  bool get isActive => status == 'active';

  /// Returns display name from email (prefix before @).
  /// TODO: Update to use full_name field once backend adds it.
  String get name => email.split('@').first;
}
