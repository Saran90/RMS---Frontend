import 'package:api_client/api_client.dart';

// Report data models
class SalesReportDay {
  const SalesReportDay(
      {required this.date,
      required this.totalOrders,
      required this.totalRevenue});
  final String date;
  final int totalOrders;
  final double totalRevenue;
  factory SalesReportDay.fromJson(Map<String, dynamic> j) => SalesReportDay(
      date: j['date'] as String,
      totalOrders: (j['total_orders'] as num).toInt(),
      totalRevenue: (j['total_revenue'] as num).toDouble());
}

class TopItem {
  const TopItem(
      {required this.name, required this.quantity, required this.revenue});
  final String name;
  final int quantity;
  final double revenue;
  factory TopItem.fromJson(Map<String, dynamic> j) => TopItem(
      name: j['name'] as String,
      quantity: (j['quantity'] as num).toInt(),
      revenue: (j['revenue'] as num).toDouble());
}

class RevenueByType {
  const RevenueByType({required this.orderType, required this.revenue});
  final String orderType;
  final double revenue;
  factory RevenueByType.fromJson(Map<String, dynamic> j) => RevenueByType(
      orderType: j['order_type'] as String,
      revenue: (j['revenue'] as num).toDouble());
}

class StaffPerformance {
  const StaffPerformance(
      {required this.staffName,
      required this.ordersHandled,
      required this.totalRevenue});
  final String staffName;
  final int ordersHandled;
  final double totalRevenue;
  factory StaffPerformance.fromJson(Map<String, dynamic> j) => StaffPerformance(
      staffName: j['staff_name'] as String,
      ordersHandled: (j['orders_handled'] as num).toInt(),
      totalRevenue: (j['total_revenue'] as num).toDouble());
}

class GstSummaryItem {
  const GstSummaryItem(
      {required this.gstRate,
      required this.taxableValue,
      required this.gstCollected,
      required this.netTotal});
  final double gstRate, taxableValue, gstCollected, netTotal;
  factory GstSummaryItem.fromJson(Map<String, dynamic> j) => GstSummaryItem(
      gstRate: (j['gst_rate'] as num).toDouble(),
      taxableValue: (j['taxable_value'] as num).toDouble(),
      gstCollected: (j['gst_collected'] as num).toDouble(),
      netTotal: (j['net_total'] as num).toDouble());
}

/// Requirements: 14.1–14.8
class ReportsRepository {
  const ReportsRepository({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  String get defaultDateFrom {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  String get defaultDateTo {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<SalesReportDay>> getSalesReport(
      {String? dateFrom, String? dateTo}) async {
    final data = await _client
        .get<List<dynamic>>('/api/v1/tenant/reports/sales', queryParams: {
      'date_from': dateFrom ?? defaultDateFrom,
      'date_to': dateTo ?? defaultDateTo
    });
    return data
        .map((e) => SalesReportDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopItem>> getTopItemsReport(
      {String? dateFrom, String? dateTo}) async {
    final data = await _client
        .get<List<dynamic>>('/api/v1/tenant/reports/top-items', queryParams: {
      'date_from': dateFrom ?? defaultDateFrom,
      'date_to': dateTo ?? defaultDateTo
    });
    return data
        .map((e) => TopItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RevenueByType>> getRevenueByTypeReport(
      {String? dateFrom, String? dateTo}) async {
    final data = await _client.get<List<dynamic>>(
        '/api/v1/tenant/reports/revenue-by-type',
        queryParams: {
          'date_from': dateFrom ?? defaultDateFrom,
          'date_to': dateTo ?? defaultDateTo
        });
    return data
        .map((e) => RevenueByType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StaffPerformance>> getStaffPerformanceReport(
      {String? dateFrom, String? dateTo}) async {
    final data = await _client.get<List<dynamic>>(
        '/api/v1/tenant/reports/staff-performance',
        queryParams: {
          'date_from': dateFrom ?? defaultDateFrom,
          'date_to': dateTo ?? defaultDateTo
        });
    return data
        .map((e) => StaffPerformance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GstSummaryItem>> getGstSummaryReport(
      {String? dateFrom, String? dateTo}) async {
    final data = await _client
        .get<List<dynamic>>('/api/v1/tenant/reports/gst-summary', queryParams: {
      'date_from': dateFrom ?? defaultDateFrom,
      'date_to': dateTo ?? defaultDateTo
    });
    return data
        .map((e) => GstSummaryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
