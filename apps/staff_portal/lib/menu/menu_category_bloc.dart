import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'menu_category.dart';
import 'menu_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

sealed class MenuCategoryEvent {
  const MenuCategoryEvent();
}

final class MenuCategoriesLoadRequested extends MenuCategoryEvent {
  const MenuCategoriesLoadRequested();
}

final class MenuCategoryCreateRequested extends MenuCategoryEvent {
  const MenuCategoryCreateRequested({required this.name, this.description});
  final String name;
  final String? description;
}

final class MenuCategoryUpdateRequested extends MenuCategoryEvent {
  const MenuCategoryUpdateRequested({
    required this.id,
    required this.name,
    this.description,
  });
  final String id;
  final String name;
  final String? description;
}

final class MenuCategoryDeleteRequested extends MenuCategoryEvent {
  const MenuCategoryDeleteRequested(this.id);
  final String id;
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class MenuCategoryState {
  const MenuCategoryState();
}

final class MenuCategoryInitial extends MenuCategoryState {
  const MenuCategoryInitial();
}

final class MenuCategoryLoading extends MenuCategoryState {
  const MenuCategoryLoading();
}

final class MenuCategoryLoaded extends MenuCategoryState {
  const MenuCategoryLoaded({
    required this.categories,
    this.deletingIds = const {},
  });
  final List<MenuCategory> categories;

  /// IDs of categories with a delete request in flight (Req 6.8).
  final Set<String> deletingIds;

  MenuCategoryLoaded copyWith({
    List<MenuCategory>? categories,
    Set<String>? deletingIds,
  }) =>
      MenuCategoryLoaded(
        categories: categories ?? this.categories,
        deletingIds: deletingIds ?? this.deletingIds,
      );
}

final class MenuCategoryError extends MenuCategoryState {
  const MenuCategoryError(this.message);
  final String message;
}

final class MenuCategoryOperationError extends MenuCategoryState {
  const MenuCategoryOperationError({
    required this.categories,
    required this.message,
    this.deletingIds = const {},
  });
  final List<MenuCategory> categories;
  final String message;
  final Set<String> deletingIds;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

/// Manages the menu categories list with optimistic delete.
///
/// Requirements: 6.1–6.10
class MenuCategoryBloc extends Bloc<MenuCategoryEvent, MenuCategoryState> {
  MenuCategoryBloc({required MenuRepository repository})
      : _repo = repository,
        super(const MenuCategoryInitial()) {
    on<MenuCategoriesLoadRequested>(_onLoad);
    on<MenuCategoryCreateRequested>(_onCreate);
    on<MenuCategoryUpdateRequested>(_onUpdate);
    on<MenuCategoryDeleteRequested>(_onDelete);
  }

  final MenuRepository _repo;

  Future<void> _onLoad(
    MenuCategoriesLoadRequested event,
    Emitter<MenuCategoryState> emit,
  ) async {
    emit(const MenuCategoryLoading());
    try {
      final categories = await _repo.getCategories();
      emit(MenuCategoryLoaded(categories: categories));
    } on ApiException catch (e) {
      emit(MenuCategoryError(e.message));
    } catch (e) {
      emit(MenuCategoryError(e.toString()));
    }
  }

  Future<void> _onCreate(
    MenuCategoryCreateRequested event,
    Emitter<MenuCategoryState> emit,
  ) async {
    final current = state;
    final currentList = current is MenuCategoryLoaded
        ? current.categories
        : current is MenuCategoryOperationError
            ? current.categories
            : <MenuCategory>[];

    try {
      final created = await _repo.createCategory(
        name: event.name,
        description: event.description,
      );
      emit(MenuCategoryLoaded(categories: [...currentList, created]));
    } on ApiException catch (e) {
      emit(MenuCategoryOperationError(
        categories: currentList,
        message: e.message,
      ));
    } catch (e) {
      emit(MenuCategoryOperationError(
        categories: currentList,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(
    MenuCategoryUpdateRequested event,
    Emitter<MenuCategoryState> emit,
  ) async {
    final current = state;
    final currentList = current is MenuCategoryLoaded
        ? current.categories
        : current is MenuCategoryOperationError
            ? current.categories
            : <MenuCategory>[];

    try {
      final updated = await _repo.updateCategory(
        id: event.id,
        name: event.name,
        description: event.description,
      );
      final newList =
          currentList.map((c) => c.id == event.id ? updated : c).toList();
      emit(MenuCategoryLoaded(categories: newList));
    } on ApiException catch (e) {
      emit(MenuCategoryOperationError(
        categories: currentList,
        message: e.message,
      ));
    } catch (e) {
      emit(MenuCategoryOperationError(
        categories: currentList,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    MenuCategoryDeleteRequested event,
    Emitter<MenuCategoryState> emit,
  ) async {
    final current = state;
    if (current is! MenuCategoryLoaded) return;

    // Mark as deleting — keep category visible with delete disabled (Req 6.8)
    final deletingIds = {...current.deletingIds, event.id};
    emit(current.copyWith(deletingIds: deletingIds));

    try {
      await _repo.deleteCategory(event.id);
      // Remove on success (Req 6.7)
      final newList =
          current.categories.where((c) => c.id != event.id).toList();
      final newDeleting = {...current.deletingIds}..remove(event.id);
      emit(MenuCategoryLoaded(
        categories: newList,
        deletingIds: newDeleting,
      ));
    } on ApiException catch (e) {
      // Keep category, clear deleting flag, show error (Req 6.9)
      final newDeleting = {...current.deletingIds}..remove(event.id);
      emit(MenuCategoryOperationError(
        categories: current.categories,
        message: e.message,
        deletingIds: newDeleting,
      ));
    } catch (e) {
      final newDeleting = {...current.deletingIds}..remove(event.id);
      emit(MenuCategoryOperationError(
        categories: current.categories,
        message: e.toString(),
        deletingIds: newDeleting,
      ));
    }
  }
}
