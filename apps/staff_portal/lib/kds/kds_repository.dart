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

  Future<void> updateKdsItemStatus(String itemId, KdsItemStatus status) async {
    await _client.patch<Map<String, dynamic>>(
      '/api/v1/tenant/kds/items/$itemId/status',
      body: {'status': status.jsonValue},
    );
  }
}
