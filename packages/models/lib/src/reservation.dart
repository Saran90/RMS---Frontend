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
    this.tableStatus,
    this.notes,
    this.tableCapacity,
    this.reservationGroupId,
    this.linkedTableIds = const [],
    this.linkedTableNumbers = const [],
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

  /// Backend table occupancy status (`available`, `reserved`, etc.).
  final TableStatus? tableStatus;

  /// Optional free-text notes.
  final String? notes;

  /// Seating capacity of the assigned table (for over-capacity warnings).
  final int? tableCapacity;

  /// Shared group id when this reservation spans multiple tables.
  final String? reservationGroupId;

  /// Additional table ids in the same reservation group (excludes [tableId]).
  final List<String> linkedTableIds;

  /// Table numbers for [linkedTableIds], in the same order.
  final List<String> linkedTableNumbers;

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
    TableStatus? tableStatus,
    String? notes,
    int? tableCapacity,
    String? reservationGroupId,
    List<String>? linkedTableIds,
    List<String>? linkedTableNumbers,
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
      tableStatus: tableStatus ?? this.tableStatus,
      notes: notes ?? this.notes,
      tableCapacity: tableCapacity ?? this.tableCapacity,
      reservationGroupId: reservationGroupId ?? this.reservationGroupId,
      linkedTableIds: linkedTableIds ?? this.linkedTableIds,
      linkedTableNumbers: linkedTableNumbers ?? this.linkedTableNumbers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// All table numbers for this booking (primary + linked).
  List<String> get allTableNumbers {
    final nums = <String>[];
    if (tableNumber != null && tableNumber!.isNotEmpty) {
      nums.add(tableNumber!);
    }
    for (final n in linkedTableNumbers) {
      if (n.isNotEmpty && !nums.contains(n)) nums.add(n);
    }
    return nums;
  }

  /// Display label such as "Table 1" or "Tables 1, 2".
  String get tablesLabel {
    final nums = allTableNumbers;
    if (nums.isEmpty) return 'Table ?';
    if (nums.length == 1) return 'Table ${nums.first}';
    return 'Tables ${nums.join(', ')}';
  }

  /// True when party size exceeds the assigned table's seating capacity.
  bool get isOverCapacity {
    if (linkedTableIds.isNotEmpty) return false;
    final cap = tableCapacity;
    if (cap == null || cap <= 0) return false;
    return partySize > cap;
  }

  /// Tables needed when party exceeds single-table capacity (minimum 1).
  int get tablesNeeded {
    final cap = tableCapacity;
    if (cap == null || cap <= 0) return 1;
    return (partySize / cap).ceil();
  }

  /// True when the reservation window has not started yet (table stays available).
  bool get isUpcoming =>
      tableStatus == TableStatus.available &&
      reservedFor.isAfter(DateTime.now());

  /// True when the guest window is currently active.
  bool get isInReservationWindow {
    final now = DateTime.now();
    return !now.isBefore(reservedFor) && now.isBefore(reservedUntil);
  }

  /// True when the reserved window has ended (local clock).
  bool get isExpired =>
      !reservedUntil.isAfter(DateTime.now()) ||
      status == ReservationStatus.completed;

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
    if (json.containsKey('reservation_name') &&
        json['guest_name'] == null) {
      return Reservation.fromTableJson(json);
    }
    return Reservation(
      id: json['id'] as String,
      tableId: json['table_id'] as String,
      tableNumber: json['table_number']?.toString(),
      guestName: (json['guest_name'] as String?) ?? '',
      guestPhone: (json['guest_phone'] as String?) ?? '',
      partySize: (json['party_size'] as num?)?.toInt() ?? 2,
      reservedFor: _parseLocal(json['reserved_for']),
      reservedUntil: _parseLocal(json['reserved_until']),
      status: _parseStatus(json['status']),
      tableStatus: json['table_status'] == null
          ? null
          : _parseTableStatus(json['table_status']),
      notes: json['notes'] as String?,
      tableCapacity: (json['capacity'] as num?)?.toInt() ??
          (json['table_capacity'] as num?)?.toInt(),
      reservationGroupId: json['reservation_group_id'] as String?,
      linkedTableIds: _parseStringList(json['linked_table_ids']),
      linkedTableNumbers: _parseStringList(json['linked_table_numbers']),
      createdAt: json['created_at'] == null
          ? null
          : _parseLocal(json['created_at']),
      updatedAt: json['ended_at'] == null
          ? (json['updated_at'] == null
              ? null
              : _parseLocal(json['updated_at']))
          : _parseLocal(json['ended_at']),
    );
  }

  /// Parses an ISO 8601 string from the API into local [DateTime].
  static DateTime _parseLocal(dynamic raw) {
    if (raw == null) {
      throw const FormatException('Missing reservation datetime');
    }
    final iso = raw is String ? raw : raw.toString();
    return DateTime.parse(iso).toLocal();
  }

  /// Maps a [Table] row returned by the reservations list API.
  factory Reservation.fromTableJson(Map<String, dynamic> json) {
    final tableStatus = _parseTableStatus(json['status']);
    if (json['reserved_for'] == null) {
      return Reservation(
        id: json['id'] as String,
        tableId: json['id'] as String,
        tableNumber: json['table_number']?.toString(),
        guestName: (json['reservation_name'] as String?) ?? '',
        guestPhone: (json['reservation_phone'] as String?) ?? '',
        partySize: (json['party_size'] as num?)?.toInt() ?? 2,
        reservedFor: DateTime.now(),
        reservedUntil: DateTime.now(),
        status: ReservationStatus.completed,
        tableStatus: tableStatus,
        notes: json['notes'] as String?,
        tableCapacity: (json['capacity'] as num?)?.toInt() ??
            (json['table_capacity'] as num?)?.toInt(),
        reservationGroupId: json['reservation_group_id'] as String?,
        linkedTableIds: _parseStringList(json['linked_table_ids']),
        linkedTableNumbers: _parseStringList(json['linked_table_numbers']),
        createdAt: json['created_at'] == null
            ? null
            : _parseLocal(json['created_at']),
        updatedAt: json['updated_at'] == null
            ? null
            : _parseLocal(json['updated_at']),
      );
    }

    final reservedFor = _parseLocal(json['reserved_for']);
    final reservedUntil = json['reserved_until'] != null
        ? _parseLocal(json['reserved_until'])
        : reservedFor.add(const Duration(hours: 2));
    final now = DateTime.now();
    final status = reservedUntil.isBefore(now) || reservedUntil.isAtSameMomentAs(now)
        ? ReservationStatus.completed
        : ReservationStatus.active;

    return Reservation(
      id: json['id'] as String,
      tableId: json['id'] as String,
      tableNumber: json['table_number']?.toString(),
      guestName: (json['reservation_name'] as String?) ?? '',
      guestPhone: (json['reservation_phone'] as String?) ?? '',
      partySize: (json['party_size'] as num?)?.toInt() ?? 2,
      reservedFor: reservedFor,
      reservedUntil: reservedUntil,
      status: status,
      tableStatus: tableStatus,
      notes: json['notes'] as String?,
      tableCapacity: (json['capacity'] as num?)?.toInt() ??
          (json['table_capacity'] as num?)?.toInt(),
      reservationGroupId: json['reservation_group_id'] as String?,
      linkedTableIds: _parseStringList(json['linked_table_ids']),
      linkedTableNumbers: _parseStringList(json['linked_table_numbers']),
      createdAt: json['created_at'] == null
          ? null
          : _parseLocal(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? null
          : _parseLocal(json['updated_at']),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static TableStatus? _parseTableStatus(dynamic raw) {
    if (raw is TableStatus) return raw;
    if (raw is String) {
      for (final s in TableStatus.values) {
        if (s.jsonValue == raw) return s;
      }
    }
    return null;
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
        other.tableStatus == tableStatus &&
        other.notes == notes &&
        other.tableCapacity == tableCapacity &&
        other.reservationGroupId == reservationGroupId &&
        _listEquals(other.linkedTableIds, linkedTableIds) &&
        _listEquals(other.linkedTableNumbers, linkedTableNumbers) &&
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
        tableStatus,
        notes,
        tableCapacity,
        reservationGroupId,
        Object.hashAll(linkedTableIds),
        Object.hashAll(linkedTableNumbers),
        createdAt,
        updatedAt,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Reservation(id: $id, tableId: $tableId, tableNumber: $tableNumber, '
      'guestName: $guestName, guestPhone: $guestPhone, partySize: $partySize, '
      'reservedFor: $reservedFor, reservedUntil: $reservedUntil, '
      'status: $status, notes: $notes)';
}
