import 'package:models/models.dart';
import 'package:staff_portal/router/app_router.dart';

/// Default landing route after login / restaurant selection for each role.
String homeRouteForRole(StaffRole role) {
  switch (role) {
    case StaffRole.chef:
      return AppRoutes.kds;
    case StaffRole.cashier:
      return AppRoutes.billing;
    case StaffRole.waiter:
      return AppRoutes.tables;
    case StaffRole.deliveryStaff:
      return AppRoutes.orders;
    case StaffRole.owner:
    case StaffRole.manager:
      return AppRoutes.dashboard;
  }
}

/// Only owners may have multiple restaurants and switch venues.
bool canSwitchRestaurant(StaffRole role) => role == StaffRole.owner;

/// Human-readable role label for profile and headers.
String roleDisplayLabel(StaffRole role) {
  switch (role) {
    case StaffRole.owner:
      return 'Owner';
    case StaffRole.manager:
      return 'Manager';
    case StaffRole.waiter:
      return 'Waiter';
    case StaffRole.chef:
      return 'Chef';
    case StaffRole.cashier:
      return 'Cashier';
    case StaffRole.deliveryStaff:
      return 'Delivery Staff';
  }
}

/// Initials for avatar badges (e.g. "John Waiter" → "JW").
String userInitials(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return trimmed[0].toUpperCase();
}
