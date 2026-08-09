import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// Requirements: 15.1–15.8
class SettingsRepository {
  const SettingsRepository({required ApiClient apiClient})
      : _client = apiClient;
  final ApiClient _client;

  Future<Restaurant> getRestaurant(String id) async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/restaurants/$id');
    return Restaurant.fromJson(data);
  }

  Future<Restaurant> updateRestaurant(
      String id, Map<String, dynamic> payload) async {
    final data = await _client
        .patch<Map<String, dynamic>>('/api/v1/restaurants/$id', body: payload);
    return Restaurant.fromJson(data);
  }
}
