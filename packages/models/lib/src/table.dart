import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:models/src/enums.dart';

part 'table.freezed.dart';
part 'table.g.dart';

/// A physical or virtual table in the restaurant floor plan.
@freezed
class Table with _$Table {
  const factory Table({
    /// Unique identifier.
    required String id,

    /// Human-readable table label (e.g. "T-01").
    @JsonKey(name: 'table_number') required String tableNumber,

    /// Floor section (e.g. "Main Hall", "Outdoor").
    @JsonKey(name: 'section_label') String? sectionLabel,

    /// Current occupancy status.
    required TableStatus status,

    /// ID of the active order on this table, if any.
    @JsonKey(name: 'current_order_id') String? currentOrderId,

    /// URL of the QR code customers scan for self-ordering.
    @JsonKey(name: 'qr_url') String? qrUrl,

    // ── Reservation fields (populated when status == reserved) ────────────
    @JsonKey(name: 'reservation_name') String? reservationName,
    @JsonKey(name: 'reservation_phone') String? reservationPhone,
    @JsonKey(name: 'reserved_for') DateTime? reservedFor,
    @JsonKey(name: 'reserved_until') DateTime? reservedUntil,
  }) = _Table;

  factory Table.fromJson(Map<String, dynamic> json) => _$TableFromJson(json);
}
