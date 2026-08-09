import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Convenience accessors for semantic and status colours used across screens.
///
/// All colours are sourced from [AppTheme] — this class simply groups them
/// by domain so screen code stays readable.
abstract final class AppColors {
  AppColors._();

  // ── Order status ──────────────────────────────────────────────────────────
  static const Color orderPending = AppTheme.statusReserved; // blue
  static const Color orderConfirmed = AppTheme.success; // green
  static const Color orderPreparing = AppTheme.statusOccupied; // amber
  static const Color orderReady = AppTheme.statusReady; // violet
  static const Color orderServed = AppTheme.statusServed; // teal
  static const Color orderCompleted = AppTheme.mutedText; // grey

  // ── Table status ──────────────────────────────────────────────────────────
  static const Color tableAvailable = AppTheme.statusAvailable; // green
  static const Color tableOccupied = AppTheme.statusOccupied; // amber
  static const Color tableReserved = AppTheme.statusReserved; // blue
  static const Color tableCleaning = AppTheme.statusCleaning; // grey

  // ── KDS item status ───────────────────────────────────────────────────────
  static const Color kdsQueued = AppTheme.statusQueued; // grey
  static const Color kdsStarted = AppTheme.statusStarted; // amber
  // 'done' items are removed from the display — no colour needed

  // ── Staff role badge colours ───────────────────────────────────────────────
  static const Color roleOwner = Color(0xFF7C3AED); // violet
  static const Color roleManager = AppTheme.primary; // slate blue
  static const Color roleWaiter = AppTheme.info; // sky blue
  static const Color roleChef = Color(0xFFEA580C); // orange
  static const Color roleCashier = AppTheme.success; // green
  static const Color roleDeliveryStaff = Color(0xFF0891B2); // cyan

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the colour that corresponds to the given order status string.
  static Color forOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return orderPending;
      case 'confirmed':
        return orderConfirmed;
      case 'preparing':
        return orderPreparing;
      case 'ready':
        return orderReady;
      case 'served':
        return orderServed;
      case 'completed':
        return orderCompleted;
      default:
        return AppTheme.mutedText;
    }
  }

  /// Returns the colour that corresponds to the given table status string.
  static Color forTableStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return tableAvailable;
      case 'occupied':
        return tableOccupied;
      case 'reserved':
        return tableReserved;
      case 'cleaning':
        return tableCleaning;
      default:
        return AppTheme.mutedText;
    }
  }

  /// Returns the colour for the given staff role string.
  static Color forRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return roleOwner;
      case 'manager':
        return roleManager;
      case 'waiter':
        return roleWaiter;
      case 'chef':
        return roleChef;
      case 'cashier':
        return roleCashier;
      case 'delivery_staff':
        return roleDeliveryStaff;
      default:
        return AppTheme.mutedText;
    }
  }
}
