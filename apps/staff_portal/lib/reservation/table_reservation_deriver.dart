import 'package:models/models.dart';

bool _isReservationExpired(Table table, DateTime clock) {
  final until = table.reservedUntil;
  return until != null && !clock.isBefore(until);
}

/// When a reservation window has ended, clears metadata and moves the table to
/// [TableStatus.cleaning] unless an open order is still linked.
List<Table> reconcileExpiredTableReservations(
  List<Table> tables, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  return tables.map((t) => _reconcileExpiredTable(t, clock)).toList();
}

Table _reconcileExpiredTable(Table table, DateTime clock) {
  if (!_isReservationExpired(table, clock)) return table;

  final cleared = table.copyWith(
    reservationName: null,
    reservationPhone: null,
    reservedFor: null,
    reservedUntil: null,
  );

  // Open order still running — stay occupied; backend clears metadata when done.
  if (table.currentOrderId != null) {
    return cleared;
  }

  if (table.status == TableStatus.available) {
    return cleared;
  }

  if (table.status == TableStatus.cleaning) {
    return cleared;
  }

  // Reservation ended with no active order — needs cleaning.
  return cleared.copyWith(status: TableStatus.cleaning);
}

/// Derives effective table occupancy from active [Reservation]s.
List<Table> deriveTableReservationState({
  required List<Table> tables,
  required List<Reservation> reservations,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final reconciled = reconcileExpiredTableReservations(tables, now: clock);

  final byTable = <String, Reservation>{};
  for (final r in reservations) {
    if (r.status != ReservationStatus.active &&
        r.status != ReservationStatus.seated) {
      continue;
    }
    if (!clock.isBefore(r.reservedFor) && clock.isBefore(r.reservedUntil)) {
      byTable[r.tableId] = r;
    }
  }

  return reconciled.map((t) {
    // Expired reservation on this row — don't re-apply occupied overlay.
    if (_isReservationExpired(t, clock) && t.currentOrderId == null) {
      return t;
    }

    final r = byTable[t.id];
    if (r == null) return t;

    if (t.status == TableStatus.occupied || t.status == TableStatus.cleaning) {
      return t.copyWith(
        reservationName: r.guestName,
        reservationPhone: r.guestPhone,
        reservedFor: r.reservedFor,
        reservedUntil: r.reservedUntil,
      );
    }

    return t.copyWith(
      status: TableStatus.occupied,
      reservationName: r.guestName,
      reservationPhone: r.guestPhone,
      reservedFor: r.reservedFor,
      reservedUntil: r.reservedUntil,
    );
  }).toList();
}

bool isActiveTableReservation(Table table, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (table.reservedFor == null || table.reservedUntil == null) return false;
  return !clock.isBefore(table.reservedFor!) &&
      clock.isBefore(table.reservedUntil!);
}

bool isExpiredTableReservation(Table table, {DateTime? now}) {
  return _isReservationExpired(table, now ?? DateTime.now());
}
