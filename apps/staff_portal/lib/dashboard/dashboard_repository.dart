import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// Summary statistics returned by the dashboard endpoint.
class DashboardStats {
  const DashboardStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.occupiedTables,
    required this.totalTables,
  });

  final int totalOrders;
  final double totalRevenue;
  final int occupiedTables;
  final int totalTables;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      occupiedTables: (json['occupied_tables'] as num?)?.toInt() ?? 0,
      totalTables: (json['total_tables'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Repository for dashboard summary data.
///
/// Requirements: 5.1, 5.2, 5.7
class DashboardRepository {
  const DashboardRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  /// Calls the summary statistics endpoint.
  ///
  /// Requirements: 5.1
  Future<DashboardStats> getSummaryStats() async {
    final raw = await _client.get<dynamic>('/api/v1/tenant/dashboard/stats');

    // Support both flat { total_orders: ... } and wrapped { data: { ... } }
    final Map<String, dynamic> data;
    if (raw is Map<String, dynamic>) {
      data = (raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw);
    } else {
      data = {};
    }

    return DashboardStats.fromJson(data);
  }

  /// Active order statuses shown on the dashboard (excludes completed/cancelled).
  static const activeOrderStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'served',
  ];

  /// Returns active orders (pending/confirmed/preparing/ready/served).
  ///
  /// Sorted newest-first by the server. Requirements: 5.2
  Future<List<Order>> getActiveOrders() async {
    final raw = await _client.get<dynamic>(
      '/api/v1/tenant/orders',
      queryParams: {
        // Backend expects repeated `status` params, not comma-separated.
        'status': activeOrderStatuses,
        'sort': 'created_at:desc',
        'limit': '50',
      },
    );

    // Response shape: { "orders": [...], "pagination": {...} }
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      final inner = raw['orders'] ?? raw['data'] ?? raw['items'] ?? [];
      list = inner is List ? inner : [];
    } else {
      list = [];
    }

    return list
        .map((e) => _parseOrder(e as Map<String, dynamic>))
        .whereType<Order>()
        .toList();
  }

  /// Returns the list of tables for the floor view on the dashboard.
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
      final normalised = {
        ...m,
        'table_number': m['table_number']?.toString() ?? '',
        'current_order_id': m['current_order_id'] ?? m['active_order_id'],
        'qr_url': m['qr_url'] ?? m['qr_code_url'],
      };
      return Table.fromJson(normalised);
    } catch (_) {
      return null;
    }
  }

  Order? _parseOrder(Map<String, dynamic> m) {
    try {
      return Order.fromJson(m);
    } catch (_) {
      return null;
    }
  }
}
