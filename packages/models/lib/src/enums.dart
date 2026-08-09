// ignore_for_file: constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

/// Order lifecycle statuses.
///
/// Maps to snake_case JSON values (e.g. [pending] → `"pending"`).
@JsonEnum(valueField: 'jsonValue')
enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  preparing('preparing'),
  ready('ready'),
  served('served'),
  completed('completed'),
  cancelled('cancelled');

  const OrderStatus(this.jsonValue);

  /// The JSON string value used for serialization.
  final String jsonValue;
}

/// Table occupancy statuses.
///
/// Maps to snake_case JSON values (e.g. [available] → `"available"`).
@JsonEnum(valueField: 'jsonValue')
enum TableStatus {
  available('available'),
  occupied('occupied'),
  reserved('reserved'),
  cleaning('cleaning');

  const TableStatus(this.jsonValue);

  /// The JSON string value used for serialization.
  final String jsonValue;
}

/// KDS (Kitchen Display System) item processing statuses.
///
/// Maps to snake_case JSON values (e.g. [queued] → `"queued"`).
@JsonEnum(valueField: 'jsonValue')
enum KdsItemStatus {
  queued('queued'),
  started('started'),
  done('done');

  const KdsItemStatus(this.jsonValue);

  /// The JSON string value used for serialization.
  final String jsonValue;
}

/// Dietary classification for menu items (FSSAI standard).
///
/// Maps to snake_case JSON values (e.g. [nonVeg] → `"non_veg"`).
@JsonEnum(valueField: 'jsonValue')
enum DietaryType {
  veg('veg'),
  nonVeg('non_veg'),
  vegan('vegan'),
  egg('egg');

  const DietaryType(this.jsonValue);

  /// The JSON string value used for serialization.
  final String jsonValue;
}

/// Staff roles controlling navigation visibility and permissions.
///
/// Maps to snake_case JSON values (e.g. [deliveryStaff] → `"delivery_staff"`).
@JsonEnum(valueField: 'jsonValue')
enum StaffRole {
  owner('owner'),
  manager('manager'),
  waiter('waiter'),
  chef('chef'),
  cashier('cashier'),
  deliveryStaff('delivery_staff');

  const StaffRole(this.jsonValue);

  /// The JSON string value used for serialization.
  final String jsonValue;
}

/// Order fulfilment type.
///
/// Maps to snake_case JSON values (e.g. [dineIn] → `"dine_in"`).
@JsonEnum(valueField: 'jsonValue')
enum OrderType {
  dineIn('dine_in'),
  takeaway('takeaway'),
  delivery('delivery');

  const OrderType(this.jsonValue);

  /// The JSON string value used for serialization.
  final String jsonValue;
}

/// Reservation lifecycle statuses.
///
/// Maps to snake_case JSON values (e.g. [disabled] → `"disabled"`).
@JsonEnum(valueField: 'jsonValue')
enum ReservationStatus {
  /// Reservation is upcoming or in-progress.
  active('active'),

  /// Guest checked in and was seated.
  seated('seated'),

  /// Guest arrived after the reserved window — marked as no-show.
  noShow('no_show'),

  /// Guest cancelled the reservation.
  cancelled('cancelled'),

  /// Reservation was disabled by staff (e.g. to free the table or
  /// because the booking is no longer honoured). The table it was
  /// attached to returns to the [TableStatus.available] state.
  disabled('disabled'),

  /// Reservation has been completed.
  completed('completed');

  const ReservationStatus(this.jsonValue);

  /// The JSON string value used for serialization.
  final String jsonValue;
}
