import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:staff_portal/router/app_router.dart';

/// Describes a single navigation destination.
class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.allowedRoles,
  });

  final IconData icon;
  final String label;
  final String route;

  /// Roles that may see and access this item.
  final Set<StaffRole> allowedRoles;
}

const _allStaffRoles = {
  StaffRole.owner,
  StaffRole.manager,
  StaffRole.waiter,
  StaffRole.chef,
  StaffRole.cashier,
  StaffRole.deliveryStaff,
};

/// Roles that use the operational dashboard (stats, floor, active orders).
const _dashboardRoles = {
  StaffRole.owner,
  StaffRole.manager,
  StaffRole.deliveryStaff,
};

/// Navigation items with role permission sets.
const List<NavItem> kNavItems = [
  NavItem(
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    route: AppRoutes.dashboard,
    allowedRoles: _dashboardRoles,
  ),
  NavItem(
    icon: Icons.receipt_long_outlined,
    label: 'Orders',
    route: AppRoutes.orders,
    allowedRoles: {
      StaffRole.owner,
      StaffRole.manager,
      StaffRole.waiter,
      StaffRole.cashier,
      StaffRole.deliveryStaff,
    },
  ),
  NavItem(
    icon: Icons.restaurant_menu_outlined,
    label: 'Menu',
    route: AppRoutes.menu,
    allowedRoles: {StaffRole.owner, StaffRole.manager},
  ),
  NavItem(
    icon: Icons.table_restaurant_outlined,
    label: 'Tables',
    route: AppRoutes.tables,
    allowedRoles: {
      StaffRole.owner,
      StaffRole.manager,
      StaffRole.waiter,
    },
  ),
  NavItem(
    icon: Icons.event_outlined,
    label: 'Reservations',
    route: AppRoutes.reservations,
    allowedRoles: {
      StaffRole.owner,
      StaffRole.manager,
      StaffRole.waiter,
    },
  ),
  NavItem(
    icon: Icons.kitchen_outlined,
    label: 'KDS',
    route: AppRoutes.kds,
    allowedRoles: {
      StaffRole.owner,
      StaffRole.manager,
      StaffRole.chef,
    },
  ),
  NavItem(
    icon: Icons.point_of_sale_outlined,
    label: 'Billing',
    route: AppRoutes.billing,
    allowedRoles: {
      StaffRole.owner,
      StaffRole.manager,
      StaffRole.cashier,
    },
  ),
  NavItem(
    icon: Icons.people_outline,
    label: 'Staff',
    route: AppRoutes.staff,
    allowedRoles: {StaffRole.owner, StaffRole.manager},
  ),
  NavItem(
    icon: Icons.inventory_2_outlined,
    label: 'Inventory',
    route: AppRoutes.inventory,
    allowedRoles: {StaffRole.owner, StaffRole.manager},
  ),
  NavItem(
    icon: Icons.bar_chart_outlined,
    label: 'Reports',
    route: AppRoutes.reports,
    allowedRoles: {StaffRole.owner, StaffRole.manager},
  ),
  NavItem(
    icon: Icons.settings_outlined,
    label: 'Settings',
    route: AppRoutes.settings,
    allowedRoles: {StaffRole.owner},
  ),
  NavItem(
    icon: Icons.person_outline,
    label: 'Profile',
    route: AppRoutes.profile,
    allowedRoles: _allStaffRoles,
  ),
];

/// Returns the subset of [kNavItems] visible to [role].
List<NavItem> navItemsForRole(StaffRole role) =>
    kNavItems.where((item) => item.allowedRoles.contains(role)).toList();
