import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:staff_portal/inventory/inventory_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class InventoryEvent {
  const InventoryEvent();
}

final class IngredientsLoadRequested extends InventoryEvent {
  const IngredientsLoadRequested();
}

final class StockAdjustmentRequested extends InventoryEvent {
  const StockAdjustmentRequested(
      {required this.id, required this.quantity, required this.reason});
  final String id, reason;
  final double quantity;
}

final class RecipeLinkRequested extends InventoryEvent {
  const RecipeLinkRequested(
      {required this.ingredientId,
      required this.menuItemId,
      required this.qtyPerServing});
  final String ingredientId, menuItemId;
  final double qtyPerServing;
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class InventoryState {
  const InventoryState();
}

final class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

final class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

final class InventoryLoaded extends InventoryState {
  const InventoryLoaded(this.ingredients);
  final List<Ingredient> ingredients;

  /// Below-threshold items first (Req 13.3)
  List<Ingredient> get sorted => [
        ...ingredients.where((i) => i.isBelowThreshold),
        ...ingredients.where((i) => !i.isBelowThreshold),
      ];
}

final class InventoryError extends InventoryState {
  const InventoryError(this.message);
  final String message;
}

final class InventoryOperationError extends InventoryState {
  const InventoryOperationError(
      {required this.ingredients, required this.message});
  final List<Ingredient> ingredients;
  final String message;
}

final class RecipeLinkSuccess extends InventoryState {
  const RecipeLinkSuccess(this.ingredients);
  final List<Ingredient> ingredients;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({required InventoryRepository repository})
      : _repo = repository,
        super(const InventoryInitial()) {
    on<IngredientsLoadRequested>(_onLoad);
    on<StockAdjustmentRequested>(_onAdjust);
    on<RecipeLinkRequested>(_onRecipeLink);
  }
  final InventoryRepository _repo;
  List<Ingredient> _current = [];

  Future<void> _onLoad(
      IngredientsLoadRequested e, Emitter<InventoryState> emit) async {
    emit(const InventoryLoading());
    try {
      final i = await _repo.getIngredients();
      _current = i;
      emit(InventoryLoaded(i));
    } on ApiException catch (ex) {
      emit(InventoryError(ex.message));
    } catch (ex) {
      emit(InventoryError(ex.toString()));
    }
  }

  Future<void> _onAdjust(
      StockAdjustmentRequested e, Emitter<InventoryState> emit) async {
    try {
      final updated = await _repo.adjustStock(
          id: e.id, quantity: e.quantity, reason: e.reason);
      _current = _current.map((i) => i.id == e.id ? updated : i).toList();
      emit(InventoryLoaded(_current));
    } on ApiException catch (ex) {
      emit(InventoryOperationError(ingredients: _current, message: ex.message));
    } catch (ex) {
      emit(InventoryOperationError(
          ingredients: _current, message: ex.toString()));
    }
  }

  Future<void> _onRecipeLink(
      RecipeLinkRequested e, Emitter<InventoryState> emit) async {
    try {
      await _repo.createRecipeLink(
          ingredientId: e.ingredientId,
          menuItemId: e.menuItemId,
          qtyPerServing: e.qtyPerServing);
      emit(RecipeLinkSuccess(_current));
    } on ApiException catch (ex) {
      emit(InventoryOperationError(ingredients: _current, message: ex.message));
    } catch (ex) {
      emit(InventoryOperationError(
          ingredients: _current, message: ex.toString()));
    }
  }
}
