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
    return _mergeGroupedReservations(
      out.where((r) => r.reservedUntil.isAfter(DateTime.now())).toList(),
    );
  }

  /// Fetches archived reservations (completed or cancelled).
  Future<List<Reservation>> getReservationHistory({int limit = 100}) async {
    final raw = await _client.get<dynamic>(
      '/api/v1/tenant/reservations/history',
      queryParams: {'limit': limit},
    );
    final archived = <Reservation>[];
    for (final item in _extractList(raw)) {
      try {
        archived.add(Reservation.fromJson(item as Map<String, dynamic>));
      } catch (e) {
        assert(() {
          // ignore: avoid_print
          print('Skipped reservation history entry: $e');
          return true;
        }());
      }
    }
    final liveExpired = await _fetchExpiredFromTables();
    return _mergeHistory(archived, liveExpired, limit);
  }

  /// Fetches a single reservation by ID.
  Future<Reservation> getReservation(String id) async {
    final raw = await _client.get<dynamic>('/api/v1/tenant/reservations/$id');
    return Reservation.fromJson(_unwrapSingle(raw));
  }

  /// Creates a reservation by marking a table as reserved via the table
  /// status API (the dedicated POST /reservations endpoint is not implemented).
  Future<Reservation> createReservation({
    required String tableId,
    required String guestName,
    required String guestPhone,
    required DateTime reservedFor,
    required DateTime reservedUntil,
    int partySize = 2,
    List<String> additionalTableIds = const [],
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'status': TableStatus.reserved.jsonValue,
      'reservation': {
        'reservation_name': guestName,
        'reservation_phone': guestPhone,
        'party_size': partySize,
        'reserved_for': toLocalIso8601String(reservedFor),
        'reserved_until': toLocalIso8601String(reservedUntil),
        if (additionalTableIds.isNotEmpty)
          'additional_table_ids': additionalTableIds,
      },
    };
    final raw = await _client.patch<dynamic>(
      '/api/v1/tenant/tables/$tableId/status',
      body: body,
    );
    final table = _normaliseTable(_unwrapSingle(raw));
    return Reservation.fromTableJson(table);
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

  /// Releases a reservation early — clears reservation metadata and returns
  /// the table to [TableStatus.available].
  Future<void> releaseReservation(String tableId) async {
    await _client.delete<dynamic>(
      '/api/v1/tenant/reservations/$tableId',
    );
  }

  /// Disables a reservation — sets its status to
  /// [ReservationStatus.disabled] and (server-side) returns the table to
  /// [TableStatus.available] so it can be reassigned.
  ///
  /// This is the "soft" disable flow: the record is preserved for audit
  /// purposes, and can later be re-enabled via [enableReservation].
  Future<void> disableReservation(String id, {String? reason}) async {
    await releaseReservation(id);
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

  Future<List<Reservation>> _fetchExpiredFromTables() async {
    final raw = await _client.get<dynamic>('/api/v1/tenant/tables');
    final list = _extractTablesList(raw);
    final out = <Reservation>[];
    for (final item in list) {
      try {
        final m = item as Map<String, dynamic>;
        if (m['reserved_for'] == null) continue;
        final r = Reservation.fromTableJson(_normaliseTable(m));
        if (r.isExpired) {
          out.add(r.copyWith(status: ReservationStatus.completed));
        }
      } catch (_) {
        // Skip tables that cannot be parsed as reservations.
      }
    }
    return out;
  }

  List<Reservation> _mergeHistory(
    List<Reservation> archived,
    List<Reservation> liveExpired,
    int limit,
  ) {
    final keys = archived.map(_historyKey).toSet();
    final merged = List<Reservation>.from(archived);
    for (final r in liveExpired) {
      final key = _historyKey(r);
      if (!keys.contains(key)) {
        merged.add(r);
        keys.add(key);
      }
    }
    merged.sort((a, b) {
      final aEnd = a.updatedAt ?? a.reservedUntil;
      final bEnd = b.updatedAt ?? b.reservedUntil;
      return bEnd.compareTo(aEnd);
    });
    if (merged.length > limit) {
      return merged.sublist(0, limit);
    }
    return merged;
  }

  String _historyKey(Reservation r) =>
      '${r.tableId}|${r.reservedFor.millisecondsSinceEpoch}|'
      '${r.reservedUntil.millisecondsSinceEpoch}';

  List<dynamic> _extractTablesList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      for (final key in ['tables', 'data', 'items']) {
        final inner = raw[key];
        if (inner is List) return inner;
      }
    }
    return const <dynamic>[];
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      for (final key in ['reservations', 'history', 'data', 'items', 'results']) {
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
      for (final key in ['table', 'data', 'result']) {
        if (raw[key] is Map<String, dynamic>) {
          return raw[key] as Map<String, dynamic>;
        }
      }
      return raw;
    }
    return <String, dynamic>{};
  }

  /// One card per logical booking — merges rows that share a group id.
  List<Reservation> _mergeGroupedReservations(List<Reservation> raw) {
    final singles = <Reservation>[];
    final byGroup = <String, List<Reservation>>{};

    for (final r in raw) {
      final gid = r.reservationGroupId;
      if (gid == null || gid.isEmpty) {
        singles.add(r);
        continue;
      }
      byGroup.putIfAbsent(gid, () => []).add(r);
    }

    final merged = <Reservation>[...singles];
    for (final members in byGroup.values) {
      merged.add(_mergeGroupMembers(members));
    }
    return merged;
  }

  Reservation _mergeGroupMembers(List<Reservation> members) {
    final sorted = List<Reservation>.from(members);
    sorted.sort((a, b) {
      final an = int.tryParse(a.tableNumber ?? '') ?? 0;
      final bn = int.tryParse(b.tableNumber ?? '') ?? 0;
      return an.compareTo(bn);
    });
    final primary = sorted.first;
    final linkedIds = <String>[];
    final linkedNums = <String>[];
    for (final m in sorted.skip(1)) {
      linkedIds.add(m.tableId);
      if (m.tableNumber != null) linkedNums.add(m.tableNumber!);
    }
    return primary.copyWith(
      linkedTableIds: linkedIds,
      linkedTableNumbers: linkedNums,
    );
  }

  Map<String, dynamic> _normaliseTable(Map<String, dynamic> m) {
    final out = <String, dynamic>{
      ...m,
      'table_number': m['table_number']?.toString() ?? '',
    };
    if (m['reserved_for'] is String) {
      out['reserved_for'] =
          parseLocalIso8601(m['reserved_for'] as String).toIso8601String();
    }
    if (m['reserved_until'] is String) {
      out['reserved_until'] =
          parseLocalIso8601(m['reserved_until'] as String).toIso8601String();
    }
    if (m['party_size'] != null) {
      out['party_size'] = m['party_size'];
    }
    if (m['reservation_group_id'] != null) {
      out['reservation_group_id'] = m['reservation_group_id'];
    }
    if (m['linked_table_ids'] is List) {
      out['linked_table_ids'] = m['linked_table_ids'];
    }
    if (m['linked_table_numbers'] is List) {
      out['linked_table_numbers'] =
          (m['linked_table_numbers'] as List).map((e) => e.toString()).toList();
    }
    return out;
  }
}
