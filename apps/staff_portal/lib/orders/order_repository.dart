import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// Requirements: 9.1–9.11
class OrderRepository {
  const OrderRepository({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  Future<PaginatedResponse<Order>> getOrders({
    int page = 1,
    int limit = 20,
    String? orderType,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (orderType != null) 'order_type': orderType,
      if (status != null) 'status': status,
    };
    final data = await _client.get<Map<String, dynamic>>(
      '/api/v1/tenant/orders',
      queryParams: params,
    );
    final items = (data['orders'] as List<dynamic>? ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
    final paginationRaw = data['pagination'] as Map<String, dynamic>? ?? {};
    return PaginatedResponse<Order>(
      data: items,
      pagination: PaginationMeta.fromJson(paginationRaw),
    );
  }

  Future<Order> getOrder(String id) async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/tenant/orders/$id');
    return Order.fromJson(data);
  }

  Future<Order> createOrder(Map<String, dynamic> payload) async {
    final data = await _client
        .post<Map<String, dynamic>>('/api/v1/tenant/orders', body: payload);
    return Order.fromJson(data);
  }

  Future<Order> updateOrderStatus(String id, OrderStatus status) async {
    final data = await _client.patch<Map<String, dynamic>>(
      '/api/v1/tenant/orders/$id/status',
      body: {'status': status.jsonValue},
    );
    return Order.fromJson(data);
  }

  Future<Order> cancelOrder(String id, {String? reason}) async {
    final data = await _client.patch<Map<String, dynamic>>(
      '/api/v1/tenant/orders/$id/status',
      body: {
        'status': 'cancelled',
        if (reason != null && reason.isNotEmpty) 'cancel_reason': reason,
      },
    );
    return Order.fromJson(data);
  }
}
