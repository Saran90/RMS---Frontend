import 'package:api_client/api_client.dart';
import 'package:models/models.dart';
import 'package:staff_portal/utils/iso8601_local.dart';

/// Repository for reservation management.
///
/// Endpoints (all under tenant scope):
/// - GET    /api/v1/tenant/reservations
/// - POST   /api/v1/tenant/reservations
/// - PATCH  /api/v1/tenant/reservations/:id
/// - POST   /api/v1/tenant/reservations/:id/disable
/// - POST   /api/v1/tenant/reservations/:id/enable
/// - DELETE /api/v1/tenant/reservations/:id
class ReservationRepository {
  const ReservationRepository({required ApiClient apiClient})
      : _client = apiClient;
  final ApiClient _client;

  /// Fetches the list of reservations. Optionally filter by [status].
  Future<List<Reservation>> getReservations({
    ReservationStatus? status,
    DateTime? from,
    DateTime? until,
  }) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status.jsonValue;
    if (from != null) query['from'] = toLocalIso8601String(from);
    if (until != null) query['until'] = toLocalIso8601String(until);

    final raw = await _client.get<dynamic>(
      '/api/v1/tenant/reservations',
      queryParams: query.isEmpty ? null : query,
    );
    final list = _extractList(raw);
    final out = <Reservation>[];
    for (final item in list) {
      try {
        out.add(Reservation.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries rather than failing the whole list.
      }
    }
    return out;
  }

  /// Fetches a single reservation by ID.
  Future<Reservation> getReservation(String id) async {
    final raw = await _client.get<dynamic>('/api/v1/tenant/reservations/$id');
    return Reservation.fromJson(_unwrapSingle(raw));
  }

  /// Creates a new reservation. Returns the created [Reservation] (with
  /// server-assigned ID and timestamps).
  Future<Reservation> createReservation({
    required String tableId,
    required String guestName,
    required String guestPhone,
    required DateTime reservedFor,
    required DateTime reservedUntil,
    int partySize = 2,
    String? notes,
  }) async {
    final raw = await _client.post<dynamic>(
      '/api/v1/tenant/reservations',
      body: {
        'table_id': tableId,
        'guest_name': guestName,
        'guest_phone': guestPhone,
        'party_size': partySize,
        // Pass the time in the user's local timezone, with the local UTC
        // offset included so the value is a valid ISO 8601 datetime that
        // the backend accepts. The clock time the user picked is what
        // gets stored — no shift to UTC.
        'reserved_for': toLocalIso8601String(reservedFor),
        'reserved_until': toLocalIso8601String(reservedUntil),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return Reservation.fromJson(_unwrapSingle(raw));
  }

  /// Edits a reservation. Only non-null parameters are sent to the server.
  ///
  /// Used for both general edits and for re-activating / changing the
  /// status of an existing reservation.
  Future<Reservation> updateReservation(
    String id, {
    String? tableId,
    String? guestName,
    String? guestPhone,
    int? partySize,
    DateTime? reservedFor,
    DateTime? reservedUntil,
    String? notes,
    ReservationStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (tableId != null) body['table_id'] = tableId;
    if (guestName != null) body['guest_name'] = guestName;
    if (guestPhone != null) body['guest_phone'] = guestPhone;
    if (partySize != null) body['party_size'] = partySize;
    if (reservedFor != null) {
      // Pass the time in the user's local timezone, with the local UTC
      // offset included so the value is a valid ISO 8601 datetime that
      // the backend accepts. The clock time the user picked is what
      // gets stored — no shift to UTC.
      body['reserved_for'] = toLocalIso8601String(reservedFor);
    }
    if (reservedUntil != null) {
      body['reserved_until'] = toLocalIso8601String(reservedUntil);
    }
    if (notes != null) body['notes'] = notes;
    if (status != null) body['status'] = status.jsonValue;

    if (body.isEmpty) return getReservation(id);

    final raw = await _client.patch<dynamic>(
      '/api/v1/tenant/reservations/$id',
      body: body,
    );
    return Reservation.fromJson(_unwrapSingle(raw));
  }

  /// Disables a reservation — sets its status to
  /// [ReservationStatus.disabled] and (server-side) returns the table to
  /// [TableStatus.available] so it can be reassigned.
  ///
  /// This is the "soft" disable flow: the record is preserved for audit
  /// purposes, and can later be re-enabled via [enableReservation].
  Future<Reservation> disableReservation(String id, {String? reason}) async {
    final raw = await _client.post<dynamic>(
      '/api/v1/tenant/reservations/$id/disable',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return Reservation.fromJson(_unwrapSingle(raw));
  }

  /// Re-enables a previously disabled reservation, returning its status
  /// to [ReservationStatus.active] and the table back to
  /// [TableStatus.reserved].
  Future<Reservation> enableReservation(String id) async {
    final raw = await _client.post<dynamic>(
      '/api/v1/tenant/reservations/$id/enable',
    );
    return Reservation.fromJson(_unwrapSingle(raw));
  }

  /// Hard-deletes a reservation record. Prefer [disableReservation] in
  /// normal use so that history is preserved.
  Future<void> deleteReservation(String id) async {
    await _client.delete<dynamic>('/api/v1/tenant/reservations/$id');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      for (final key in ['reservations', 'data', 'items', 'results']) {
        final inner = raw[key];
        if (inner is List) return inner;
      }
    }
    return const <dynamic>[];
  }

  Map<String, dynamic> _unwrapSingle(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('id') && raw['id'] is String) return raw;
      if (raw.containsKey('reservation') &&
          raw['reservation'] is Map<String, dynamic>) {
        return raw['reservation'] as Map<String, dynamic>;
      }
      for (final key in ['data', 'result']) {
        if (raw[key] is Map<String, dynamic>) {
          return raw[key] as Map<String, dynamic>;
        }
      }
      return raw;
    }
    return <String, dynamic>{};
  }
}
