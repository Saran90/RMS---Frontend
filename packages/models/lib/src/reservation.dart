import 'package:models/src/enums.dart';

/// A reservation made by a customer for a particular table at a restaurant.
///
/// Unlike the lightweight reservation fields embedded on [Table] (which
/// represent the current "reserved" state of a single table), this entity
/// is a first-class record that lives independently and supports lifecycle
/// states such as [ReservationStatus.disabled].
///
/// Implemented as a hand-rolled immutable value class (instead of freezed)
/// so that it can be added to the models package without requiring a
/// `build_runner` step at runtime. It still provides `copyWith`, value
/// equality, `toString`, and JSON (de)serialization consistent with the
/// other models in this package.
class Reservation {
  const Reservation({
    required this.id,
    required this.tableId,
    this.tableNumber,
    required this.guestName,
    required this.guestPhone,
    this.partySize = 2,
    required this.reservedFor,
    required this.reservedUntil,
    this.status = ReservationStatus.active,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier.
  final String id;

  /// ID of the table this reservation is for.
  final String tableId;

  /// Human-readable table number (for display convenience).
  final String? tableNumber;

  /// Guest name.
  final String guestName;

  /// Guest phone number.
  final String guestPhone;

  /// Number of guests in the party.
  final int partySize;

  /// Start of the reserved time window.
  final DateTime reservedFor;

  /// End of the reserved time window.
  final DateTime reservedUntil;

  /// Lifecycle status.
  final ReservationStatus status;

  /// Optional free-text notes.
  final String? notes;

  /// When the record was created.
  final DateTime? createdAt;

  /// When the record was last updated.
  final DateTime? updatedAt;

  /// Returns a new [Reservation] with the given fields replaced.
  Reservation copyWith({
    String? id,
    String? tableId,
    String? tableNumber,
    String? guestName,
    String? guestPhone,
    int? partySize,
    DateTime? reservedFor,
    DateTime? reservedUntil,
    ReservationStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      partySize: partySize ?? this.partySize,
      reservedFor: reservedFor ?? this.reservedFor,
      reservedUntil: reservedUntil ?? this.reservedUntil,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'table_number': tableNumber,
        'guest_name': guestName,
        'guest_phone': guestPhone,
        'party_size': partySize,
        'reserved_for': reservedFor.toIso8601String(),
        'reserved_until': reservedUntil.toIso8601String(),
        'status': status.jsonValue,
        'notes': notes,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      tableId: json['table_id'] as String,
      tableNumber: json['table_number'] as String?,
      guestName: json['guest_name'] as String,
      guestPhone: json['guest_phone'] as String,
      partySize: (json['party_size'] as num?)?.toInt() ?? 2,
      reservedFor: _parseLocal(json['reserved_for'] as String),
      reservedUntil: _parseLocal(json['reserved_until'] as String),
      status: _parseStatus(json['status']),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : _parseLocal(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : _parseLocal(json['updated_at'] as String),
    );
  }

  /// Parses an ISO 8601 string and returns a *local* [DateTime] whose
  /// clock components match the string.
  ///
  /// Reservation timestamps are exchanged with the backend in the user's
  /// local timezone (formatted with a `Z` designator for ISO 8601
  /// validity). [DateTime.parse] would otherwise treat the `Z` as UTC
  /// and shift the clock time by the local offset when callers read
  /// `year`/`hour`/etc. This helper strips the timezone designator so
  /// the returned DateTime reads back as the same clock time the user
  /// originally picked.
  static DateTime _parseLocal(String iso) {
    // Strip a trailing 'Z' (UTC) or '+HH:MM'/'-HH:MM' (offset) so
    // DateTime.parse constructs a local DateTime from the literal
    // components instead of an absolute moment.
    final stripped = iso
        .replaceFirst(RegExp(r'Z$'), '')
        .replaceFirst(RegExp(r'[+-]\d{2}:\d{2}$'), '');
    return DateTime.parse(stripped);
  }

  static ReservationStatus _parseStatus(dynamic raw) {
    if (raw is ReservationStatus) return raw;
    if (raw is String) {
      for (final s in ReservationStatus.values) {
        if (s.jsonValue == raw) return s;
      }
    }
    return ReservationStatus.active;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reservation &&
        other.id == id &&
        other.tableId == tableId &&
        other.tableNumber == tableNumber &&
        other.guestName == guestName &&
        other.guestPhone == guestPhone &&
        other.partySize == partySize &&
        other.reservedFor == reservedFor &&
        other.reservedUntil == reservedUntil &&
        other.status == status &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        tableId,
        tableNumber,
        guestName,
        guestPhone,
        partySize,
        reservedFor,
        reservedUntil,
        status,
        notes,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'Reservation(id: $id, tableId: $tableId, tableNumber: $tableNumber, '
      'guestName: $guestName, guestPhone: $guestPhone, partySize: $partySize, '
      'reservedFor: $reservedFor, reservedUntil: $reservedUntil, '
      'status: $status, notes: $notes)';
}
