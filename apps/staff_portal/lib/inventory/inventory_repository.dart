import 'package:api_client/api_client.dart';

/// Ingredient model for inventory management.
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.reorderThreshold,
  });
  final String id, name, unit;
  final double currentStock, reorderThreshold;

  bool get isBelowThreshold => currentStock < reorderThreshold;

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: j['id'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String,
        currentStock: (j['current_stock'] as num).toDouble(),
        reorderThreshold: (j['reorder_threshold'] as num).toDouble(),
      );
}

/// Requirements: 13.1–13.8
class InventoryRepository {
  const InventoryRepository({required ApiClient apiClient})
      : _client = apiClient;
  final ApiClient _client;

  Future<List<Ingredient>> getIngredients() async {
    final data = await _client
        .get<List<dynamic>>('/api/v1/tenant/inventory/ingredients');
    return data
        .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Ingredient> adjustStock({
    required String id,
    required double quantity,
    required String reason,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/tenant/inventory/ingredients/$id/adjustments',
      body: {'quantity': quantity, 'reason': reason},
    );
    return Ingredient.fromJson(data);
  }

  Future<void> createRecipeLink({
    required String ingredientId,
    required String menuItemId,
    required double qtyPerServing,
  }) async {
    await _client.post<dynamic>(
      '/api/v1/tenant/inventory/recipe-links',
      body: {
        'ingredient_id': ingredientId,
        'menu_item_id': menuItemId,
        'qty_per_serving': qtyPerServing,
      },
    );
  }
}
