import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// Requirements: 11.1–11.13
class BillingRepository {
  const BillingRepository({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  Future<Bill> generateBill(String orderId) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills',
      body: {'order_id': orderId},
    );
    return Bill.fromJson(data);
  }

  Future<Bill> recordPayment({
    required String billId,
    required String mode,
    required double amount,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/payments',
      body: {'mode': mode, 'amount': amount},
    );
    return Bill.fromJson(data);
  }

  Future<List<Bill>> splitBill(
      {required String billId, required int diners}) async {
    final data = await _client.post<List<dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/split',
      body: {'diners': diners},
    );
    return data.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bill> voidBill(
      {required String billId, required String reason}) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/billing/bills/$billId/void',
      body: {'reason': reason},
    );
    return Bill.fromJson(data);
  }

  Future<Bill> getBill(String billId) async {
    final data = await _client
        .get<Map<String, dynamic>>('/api/v1/tenant/billing/bills/$billId');
    return Bill.fromJson(data);
  }

  Future<List<Bill>> listBills({String? status}) async {
    print('BillingRepository: listBills called with status=$status');
    try {
      final data = await _client.get<Map<String, dynamic>>(
        '/api/v1/tenant/billing/bills',
        queryParams: {
          if (status != null) 'status': status,
          'limit': 100,
        },
      );
      print('BillingRepository: received response data');
      final bills = data['bills'] as List<dynamic>? ?? [];
      print('BillingRepository: parsing ${bills.length} bills');
      final parsed =
          bills.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
      print('BillingRepository: successfully parsed ${parsed.length} bills');
      return parsed;
    } catch (e, stackTrace) {
      print('BillingRepository: Error - $e');
      print('BillingRepository: Stack trace - $stackTrace');
      rethrow;
    }
  }
}
