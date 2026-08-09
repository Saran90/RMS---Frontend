import 'package:api_client/api_client.dart';
import 'package:models/models.dart';
import 'package:staff_portal/utils/iso8601_local.dart';

/// Reservation details required when transitioning to [TableStatus.reserved].
class TableReservation {
  const TableReservation({
    required this.name,
    required this.phone,
    required this.reservedFor,
    required this.reservedUntil,
  });
  final String name;
  final String phone;
  final DateTime reservedFor;
  final DateTime reservedUntil;
}

/// Repository for table management.
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.7
class TableRepository {
  const TableRepository({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  Future<List<Table>> getTables() async {
    final raw = await _client.get<dynamic>('/api/v1/tenant/tables');
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      final inner = raw['tables'] ?? raw['data'] ?? raw['items'] ?? [];
      list = inner is List ? inner : [];
    } else {
      list = [];
    }
    return list
        .map((e) => _parseTable(e as Map<String, dynamic>))
        .whereType<Table>()
        .toList();
  }

  Table? _parseTable(Map<String, dynamic> m) {
    try {
      // Normalise field names and types from the backend response:
      // - table_number comes as int → convert to String
      // - active_order_id → current_order_id
      // - qr_code_url → qr_url
      // - reserved_for / reserved_until: strip any timezone designator
      //   so DateTime.parse reads the clock components as-is (matching
      //   the local-as-UTC format produced by toLocalIso8601String).
      final normalised = <String, dynamic>{
        ...m,
        'table_number': m['table_number']?.toString() ?? '',
        'current_order_id': m['current_order_id'] ?? m['active_order_id'],
        'qr_url': m['qr_url'] ?? m['qr_code_url'],
        if (m['reserved_for'] is String)
          'reserved_for': _stripTimeZone(m['reserved_for'] as String),
        if (m['reserved_until'] is String)
          'reserved_until': _stripTimeZone(m['reserved_until'] as String),
      };
      return Table.fromJson(normalised);
    } catch (_) {
      return null;
    }
  }

  /// Removes a trailing `Z` or `+HH:MM`/`-HH:MM` designator so the
  /// remaining string is parsed as a *local* DateTime by [DateTime.parse].
  String _stripTimeZone(String iso) {
    return iso
        .replaceFirst(RegExp(r'Z$'), '')
        .replaceFirst(RegExp(r'[+-]\d{2}:\d{2}$'), '');
  }

  Future<Table> updateTableStatus(String id, TableStatus status,
      {TableReservation? reservation}) async {
    final body = <String, dynamic>{'status': status.jsonValue};
    if (status == TableStatus.reserved && reservation != null) {
      body['reservation'] = {
        'reservation_name': reservation.name,
        'reservation_phone': reservation.phone,
        // Pass the time in the user's local timezone, with the local UTC
        // offset included so the value is a valid ISO 8601 datetime that
        // the backend accepts. The clock time the user picked is what
        // gets stored — no shift to UTC.
        'reserved_for': toLocalIso8601String(reservation.reservedFor),
        'reserved_until': toLocalIso8601String(reservation.reservedUntil),
      };
    }
    final raw = await _client.patch<dynamic>(
      '/api/v1/tenant/tables/$id/status',
      body: body,
    );
    return Table.fromJson(_normalise(_unwrapSingle(raw)));
  }

  Future<Table> editTable(
    String id, {
    int? tableNumber,
    int? capacity,
    String? sectionLabel,
    String? qrCodeUrl,
  }) async {
    final body = <String, dynamic>{};
    if (tableNumber != null) body['table_number'] = tableNumber;
    if (capacity != null) body['capacity'] = capacity;
    if (sectionLabel != null) body['section_label'] = sectionLabel;
    if (qrCodeUrl != null) body['qr_code_url'] = qrCodeUrl;

    if (body.isEmpty) {
      // Nothing to update — fetch fresh and return current state
      final tables = await getTables();
      return tables.firstWhere((t) => t.id == id);
    }

    final raw = await _client.patch<dynamic>(
      '/api/v1/tenant/tables/$id',
      body: body,
    );
    return Table.fromJson(_normalise(_unwrapSingle(raw)));
  }

  Future<void> deleteTable(String id) async {
    await _client.delete<dynamic>('/api/v1/tenant/tables/$id');
  }

  Map<String, dynamic> _normalise(Map<String, dynamic> m) {
    final out = <String, dynamic>{
      ...m,
      'table_number': m['table_number']?.toString() ?? '',
      'current_order_id': m['current_order_id'] ?? m['active_order_id'],
      'qr_url': m['qr_url'] ?? m['qr_code_url'],
    };
    if (m['reserved_for'] is String) {
      out['reserved_for'] = _stripTimeZone(m['reserved_for'] as String);
    }
    if (m['reserved_until'] is String) {
      out['reserved_until'] = _stripTimeZone(m['reserved_until'] as String);
    }
    return out;
  }

  /// Unwraps single-object responses like { "table": {...} } or { "data": {...} }.
  Map<String, dynamic> _unwrapSingle(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      // If response has 'id' at top level it's already unwrapped
      if (raw.containsKey('id')) return raw;
      // Otherwise try common wrapper keys
      for (final key in ['table', 'data', 'result']) {
        if (raw[key] is Map<String, dynamic>) {
          return raw[key] as Map<String, dynamic>;
        }
      }
      return raw;
    }
    return {};
  }

  Future<void> createTable({
    required int tableNumber,
    required int capacity,
    String? sectionLabel,
    String? qrCodeUrl,
  }) async {
    await _client.post<dynamic>(
      '/api/v1/tenant/tables',
      body: {
        'table_number': tableNumber,
        'capacity': capacity,
        if (sectionLabel != null && sectionLabel.isNotEmpty)
          'section_label': sectionLabel,
        if (qrCodeUrl != null && qrCodeUrl.isNotEmpty) 'qr_code_url': qrCodeUrl,
      },
    );
  }

  Future<List<Table>> bulkCreateTables({
    required int count,
    required String sectionLabel,
    required int capacity,
    required int startingNumber,
  }) async {
    await _client.post<dynamic>(
      '/api/v1/tenant/tables/bulk',
      body: {
        'count': count,
        'section_label': sectionLabel,
        'capacity': capacity,
        'starting_number': startingNumber,
      },
    );
    return getTables();
  }
}
