import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// Repository for restaurant listing and selection.
///
/// Requirements: 3.1, 3.2, 3.5, 3.6
class RestaurantRepository {
  const RestaurantRepository({required ApiClient apiClient})
      : _client = apiClient;

  final ApiClient _client;

  /// Calls `GET /api/v1/restaurants` and returns the list of restaurants
  /// accessible by the current Base_JWT.
  ///
  /// Returns an empty list when none are found.
  /// Throws [ApiException] on error.
  Future<List<Restaurant>> getRestaurants() async {
    final raw = await _client.get<dynamic>('/api/v1/restaurants');

    // Normalise response shape:
    //   flat list  →  [ {...}, {...} ]
    //   wrapped    →  { "restaurants": [...] }  or  { "data": [...] }
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      final inner = raw['restaurants'] ?? raw['data'] ?? raw['items'] ?? [];
      list = inner is List ? inner : [];
    } else {
      list = [];
    }

    return list
        .map((e) => _parseRestaurant(e as Map<String, dynamic>))
        .whereType<Restaurant>()
        .toList();
  }

  /// Parses a restaurant map, tolerating common field-name variations from
  /// the backend (e.g. phone_number vs phone, gst vs gst_number).
  Restaurant _parseRestaurant(Map<String, dynamic> m) {
    return Restaurant(
      id: (m['restaurant_id'] ?? m['id'] ?? '') as String,
      name: (m['restaurant_name'] ?? m['name'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      phone: (m['contact_phone'] ?? m['phone'] ?? m['phone_number'] ?? '')
          as String,
      gstNumber: (m['gst_number'] ?? m['gst'] ?? m['gstin'] ?? '') as String,
      logoUrl: m['logo_url'] as String?,
    );
  }
}
