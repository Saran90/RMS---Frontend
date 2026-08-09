import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:models/models.dart';

import 'bulk_upload_models.dart';
import 'menu_category.dart';

/// Repository for menu categories and items.
///
/// Includes a simple in-memory cache so that repeated navigations to the
/// Menu screen return data immediately from cache while a background refresh
/// keeps it fresh. Cache is invalidated on any write operation.
///
/// Requirements: 6.1–6.10, 7.1–7.11
class MenuRepository {
  const MenuRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  // ── Cache ──────────────────────────────────────────────────────────────────

  static List<MenuCategory>? _cachedCategories;
  static List<MenuItem>? _cachedItems;

  /// Clears both caches — called after any write that mutates the data.
  static void _invalidate() {
    _cachedCategories = null;
    _cachedItems = null;
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<MenuCategory>> getCategories() async {
    if (_cachedCategories != null) {
      // Return cache immediately; fire a background refresh.
      _fetchAndCacheCategories().ignore();
      return _cachedCategories!;
    }
    return _fetchAndCacheCategories();
  }

  Future<List<MenuCategory>> _fetchAndCacheCategories() async {
    const limit = 100;
    final all = <MenuCategory>[];
    var page = 1;

    while (true) {
      final data = await _client.get<Map<String, dynamic>>(
        '/api/v1/tenant/menu/categories',
        queryParams: {'page': page, 'limit': limit},
      );
      final batch = (data['categories'] as List<dynamic>? ?? [])
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      all.addAll(batch);

      final pagination = data['pagination'] as Map<String, dynamic>?;
      final totalPages = (pagination?['totalPages'] as num?)?.toInt() ?? 1;
      if (page >= totalPages) break;
      page++;
    }

    all.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    _cachedCategories = all;
    return all;
  }

  Future<MenuCategory> createCategory({
    required String name,
    String? description,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/menu/categories',
      body: {'name': name, if (description != null) 'description': description},
    );
    _invalidate();
    return MenuCategory.fromJson(data);
  }

  Future<MenuCategory> updateCategory({
    required String id,
    required String name,
    String? description,
  }) async {
    final data = await _client.patch<Map<String, dynamic>>(
      '/api/v1/tenant/menu/categories/$id',
      body: {'name': name, if (description != null) 'description': description},
    );
    _invalidate();
    return MenuCategory.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete<dynamic>('/api/v1/tenant/menu/categories/$id');
    _invalidate();
  }

  // ── Items ──────────────────────────────────────────────────────────────────

  static const _itemsPageSize = 50;

  /// Fetches a single page of items.
  ///
  /// Params map directly to the API contract:
  /// - [q]           full-text search (PostgreSQL plainto_tsquery — whole words)
  /// - [categoryId]  exact category UUID filter
  /// - [dietaryType] exact dietary_type filter
  /// - [page]        page number (1-based)
  ///
  /// Staff portal always passes `include_unavailable=true` so managers can
  /// see and toggle unavailable items. The API default is available_only=true
  /// which would hide them.
  Future<({List<MenuItem> items, bool hasMore, int total})> getItemsPage(
    int page, {
    String? q,
    String? categoryId,
    DietaryType? dietaryType,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/api/v1/tenant/menu/items',
      queryParams: {
        'page': page,
        'limit': _itemsPageSize,
        'include_unavailable': true,
        if (q != null && q.isNotEmpty) 'q': q,
        if (categoryId != null) 'category_id': categoryId,
        if (dietaryType != null) 'dietary_type': dietaryType.jsonValue,
      },
      cancelToken: cancelToken,
    );
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>?;
    // API returns the total page count as `pages` (not `totalPages`)
    final totalPages = (pagination?['pages'] as num?)?.toInt() ??
        (pagination?['totalPages'] as num?)?.toInt() ??
        1;
    final total = (pagination?['total'] as num?)?.toInt() ?? items.length;
    return (items: items, hasMore: page < totalPages, total: total);
  }

  /// Fetches ALL items (used by bulk upload refresh). Bypasses pagination.
  Future<List<MenuItem>> getItems() async {
    if (_cachedItems != null) {
      _fetchAndCacheItems().ignore();
      return _cachedItems!;
    }
    return _fetchAndCacheItems();
  }

  Future<List<MenuItem>> _fetchAndCacheItems() async {
    final all = <MenuItem>[];
    var page = 1;
    while (true) {
      final result = await getItemsPage(page);
      all.addAll(result.items);
      if (!result.hasMore) break;
      page++;
    }
    _cachedItems = all;
    return all;
  }

  Future<MenuItem> createItem(Map<String, dynamic> payload) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/menu/items',
      body: payload,
    );
    _invalidate();
    return MenuItem.fromJson(data);
  }

  Future<MenuItem> updateItem(String id, Map<String, dynamic> payload) async {
    final data = await _client.patch<Map<String, dynamic>>(
      '/api/v1/tenant/menu/items/$id',
      body: payload,
    );
    _invalidate();
    return MenuItem.fromJson(data);
  }

  Future<MenuItem> toggleAvailability(String id,
      {required bool isAvailable}) async {
    final data = await _client.patch<Map<String, dynamic>>(
      '/api/v1/tenant/menu/items/$id',
      body: {'is_available': isAvailable},
    );
    // Don't invalidate full cache for a toggle — just patch the cached entry.
    if (_cachedItems != null) {
      final updated = MenuItem.fromJson(data);
      _cachedItems =
          _cachedItems!.map((i) => i.id == id ? updated : i).toList();
    }
    return MenuItem.fromJson(data);
  }

  // ── Bulk Upload ────────────────────────────────────────────────────────────

  Future<BulkUploadTemplate> getBulkUploadTemplate() async {
    final data = await _client
        .get<Map<String, dynamic>>('/api/v1/tenant/menu/bulk-upload/template');
    return BulkUploadTemplate.fromJson(data);
  }

  Future<BulkUploadResult> bulkUploadMenu({
    required List<int> fileBytes,
    required String filename,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'menu_file': MultipartFile.fromBytes(
        fileBytes,
        filename: filename,
        contentType: DioMediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      ),
    });

    final data = await _client.postMultipart<Map<String, dynamic>>(
      '/api/v1/tenant/menu/bulk-upload',
      formData: formData,
      onSendProgress: onSendProgress,
    );
    _invalidate();
    return BulkUploadResult.fromJson(data);
  }
}
