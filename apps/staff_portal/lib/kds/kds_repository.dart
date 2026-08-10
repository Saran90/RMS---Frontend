import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// Requirements: 10.1–10.6
class KdsRepository {
  const KdsRepository({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  Future<List<KdsOrder>> getStationFeed(String stationId) async {
    final data = await _client
        .get<List<dynamic>>('/api/v1/tenant/kds/stations/$stationId/feed');
    return data
        .map((e) => KdsOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Completed / past kitchen orders the chef worked on.
  Future<List<KdsOrder>> getStationHistory(
    String stationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final raw = await _client.get<dynamic>(
      '/api/v1/tenant/kds/stations/$stationId/history',
      queryParams: {'page': page, 'limit': limit},
    );

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
        .map((e) => KdsOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateKdsItemStatus(String itemId, KdsItemStatus status) async {
    await _client.patch<Map<String, dynamic>>(
      '/api/v1/tenant/kds/items/$itemId/status',
      body: {'status': status.jsonValue},
    );
  }
}
