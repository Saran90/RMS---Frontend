import 'package:models/models.dart';

/// Derives the effective occupancy state for each table by combining the
/// backend-reported [Table.status] with the set of currently active
/// [Reservation]s. This makes the Tables screen correctly display the
/// "Reserved" tag for **any** reservation that is in its reserved time
/// window — not just ones created via the per-table reservation sheet.
///
/// Derivation rules (applied per table):
/// 1. If there is an [ReservationStatus.active] (or `seated`) reservation
///    for the table whose `reservedFor <= now < reservedUntil`, the table
///    is treated as [TableStatus.reserved] and the reservation fields are
///    populated. Future reservations never mark the table as reserved
///    before their start time.
/// 2. If the only reservation has been [ReservationStatus.disabled],
///    [ReservationStatus.cancelled] or [ReservationStatus.noShow], the
///    table is left as the backend reported it (typically `available`).
/// 3. If the table is already `occupied` or `cleaning`, those states win
///    over a current reservation — the kitchen already has the table.
List<Table> deriveTableReservationState({
  required List<Table> tables,
  required List<Reservation> reservations,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();

  // Group active reservations by table id, picking the most relevant
  // one if there are multiple. (Two active reservations on the same
  // table is a server-side error, but we degrade gracefully.)
  final byTable = <String, Reservation>{};
  for (final r in reservations) {
    if (r.status != ReservationStatus.active &&
        r.status != ReservationStatus.seated) {
      continue;
    }
    if (!clock.isBefore(r.reservedFor) && clock.isBefore(r.reservedUntil)) {
      // Currently inside the reservation window — mark the table.
      byTable[r.tableId] = r;
    }
    // Future reservations (reservedFor > now) are intentionally ignored:
    // the table must not show as reserved until the window actually starts.
  }

  return tables.map((t) {
    final r = byTable[t.id];
    if (r == null) return t;

    // Don't override a table that is mid-service.
    if (t.status == TableStatus.occupied || t.status == TableStatus.cleaning) {
      return t;
    }

    return t.copyWith(
      status: TableStatus.reserved,
      reservationName: r.guestName,
      reservationPhone: r.guestPhone,
      reservedFor: r.reservedFor,
      reservedUntil: r.reservedUntil,
    );
  }).toList();
}
