import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'bulk_upload_models.dart';
import 'menu_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

sealed class MenuItemEvent {
  const MenuItemEvent();
}

/// Load page 1. Passing new filter values resets the list completely.
final class MenuItemsLoadRequested extends MenuItemEvent {
  const MenuItemsLoadRequested({
    this.q,
    this.categoryId,
    this.categoryIds,
    this.dietaryType,
  });
  final String? q;

  /// Single category UUID — use when there are no duplicates.
  final String? categoryId;

  /// All UUIDs that map to one logical category name (bulk-upload duplicates).
  /// When set, items are fetched for each ID in parallel and merged.
  final List<String>? categoryIds;
  final DietaryType? dietaryType;
}

/// Append the next page using the same filters already in state.
final class MenuItemsNextPageRequested extends MenuItemEvent {
  const MenuItemsNextPageRequested();
}

final class MenuItemCreateRequested extends MenuItemEvent {
  const MenuItemCreateRequested({required this.payload});
  final Map<String, dynamic> payload;
}

final class MenuItemUpdateRequested extends MenuItemEvent {
  const MenuItemUpdateRequested({required this.id, required this.payload});
  final String id;
  final Map<String, dynamic> payload;
}

final class MenuItemAvailabilityToggled extends MenuItemEvent {
  const MenuItemAvailabilityToggled(
      {required this.id, required this.isAvailable});
  final String id;
  final bool isAvailable;
}

final class MenuBulkUploadRequested extends MenuItemEvent {
  const MenuBulkUploadRequested(
      {required this.fileBytes, required this.filename});
  final List<int> fileBytes;
  final String filename;
}

final class _BulkUploadProgressUpdated extends MenuItemEvent {
  const _BulkUploadProgressUpdated(this.progress);
  final double progress;
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class MenuItemState {
  const MenuItemState();
}

final class MenuItemInitial extends MenuItemState {
  const MenuItemInitial();
}

final class MenuItemLoading extends MenuItemState {
  const MenuItemLoading();
}

/// Paginated loaded state. Active filters are stored here so the next-page
/// handler can pass the same params to the API.
final class MenuItemLoaded extends MenuItemState {
  const MenuItemLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.total,
    this.isLoadingMore = false,
    this.q,
    this.categoryId,
    this.categoryIds,
    this.dietaryType,
  });

  final List<MenuItem> items;
  final int currentPage;
  final bool hasMore;
  final int? total;
  final bool isLoadingMore;
  final String? q;
  final String? categoryId;
  final List<String>? categoryIds;
  final DietaryType? dietaryType;

  MenuItemLoaded copyWith({
    List<MenuItem>? items,
    int? currentPage,
    bool? hasMore,
    int? total,
    bool? isLoadingMore,
    Object? q = _keep,
    Object? categoryId = _keep,
    Object? categoryIds = _keep,
    Object? dietaryType = _keep,
  }) =>
      MenuItemLoaded(
        items: items ?? this.items,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
        total: total ?? this.total,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        q: q == _keep ? this.q : q as String?,
        categoryId:
            categoryId == _keep ? this.categoryId : categoryId as String?,
        categoryIds: categoryIds == _keep
            ? this.categoryIds
            : categoryIds as List<String>?,
        dietaryType: dietaryType == _keep
            ? this.dietaryType
            : dietaryType as DietaryType?,
      );

  static const _keep = Object();
}

final class MenuItemError extends MenuItemState {
  const MenuItemError(this.message);
  final String message;
}

final class MenuItemOperationError extends MenuItemState {
  const MenuItemOperationError({
    required this.items,
    required this.message,
    this.currentPage = 1,
    this.hasMore = false,
    this.q,
    this.categoryId,
    this.categoryIds,
    this.dietaryType,
  });
  final List<MenuItem> items;
  final String message;
  final int currentPage;
  final bool hasMore;
  final String? q;
  final String? categoryId;
  final List<String>? categoryIds;
  final DietaryType? dietaryType;
}

final class MenuBulkUploadInProgress extends MenuItemState {
  const MenuBulkUploadInProgress({required this.items, this.progress});
  final List<MenuItem> items;
  final double? progress;
}

final class MenuBulkUploadSuccess extends MenuItemState {
  const MenuBulkUploadSuccess({required this.items, required this.result});
  final List<MenuItem> items;
  final BulkUploadResult result;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class MenuItemBloc extends Bloc<MenuItemEvent, MenuItemState> {
  MenuItemBloc({required MenuRepository repository})
      : _repo = repository,
        super(const MenuItemInitial()) {
    on<MenuItemsLoadRequested>(_onLoad);
    on<MenuItemsNextPageRequested>(_onNextPage);
    on<MenuItemCreateRequested>(_onCreate);
    on<MenuItemUpdateRequested>(_onUpdate);
    on<MenuItemAvailabilityToggled>(_onToggle);
    on<MenuBulkUploadRequested>(_onBulkUpload);
    on<_BulkUploadProgressUpdated>(_onBulkUploadProgress);
  }

  final MenuRepository _repo;

  /// Tracks the in-flight load request so it can be cancelled when new
  /// filter params arrive before the previous fetch completes.
  CancelToken? _loadCancelToken;

  @override
  Future<void> close() {
    _loadCancelToken?.cancel('bloc closed');
    return super.close();
  }

  // ── Load page 1 ───────────────────────────────────────────────────────────

  Future<void> _onLoad(
    MenuItemsLoadRequested event,
    Emitter<MenuItemState> emit,
  ) async {
    // Cancel any in-flight request from a previous filter/search.
    _loadCancelToken?.cancel('superseded');
    _loadCancelToken = CancelToken();
    final token = _loadCancelToken!;

    emit(const MenuItemLoading());

    final ids = event.categoryIds ??
        (event.categoryId != null ? [event.categoryId!] : null);

    try {
      List<MenuItem> items;
      bool hasMore;
      int total;

      if (ids == null || ids.length <= 1) {
        final result = await _repo.getItemsPage(
          1,
          q: event.q,
          categoryId: ids?.firstOrNull,
          dietaryType: event.dietaryType,
          cancelToken: token,
        );
        items = result.items;
        hasMore = result.hasMore;
        total = result.total;
      } else {
        // Multiple duplicate UUIDs — fetch all pages for each in parallel.
        final futures = ids.map((id) => _fetchAllPages(
              q: event.q,
              categoryId: id,
              dietaryType: event.dietaryType,
              cancelToken: token,
            ));
        final batches = await Future.wait(futures);
        final seen = <String>{};
        items = [
          for (final batch in batches)
            for (final item in batch)
              if (seen.add(item.id)) item,
        ];
        items.sort((a, b) => a.name.compareTo(b.name));
        hasMore = false;
        total = items.length;
      }

      emit(MenuItemLoaded(
        items: items,
        currentPage: 1,
        hasMore: hasMore,
        total: total,
        q: event.q,
        categoryId: ids?.firstOrNull,
        categoryIds: ids,
        dietaryType: event.dietaryType,
      ));
    } on DioException catch (e) {
      // Request was cancelled by a newer filter — silently discard.
      if (e.type == DioExceptionType.cancel) return;
      emit(MenuItemError(e.message ?? e.toString()));
    } on ApiException catch (e) {
      emit(MenuItemError(e.message));
    } catch (e) {
      emit(MenuItemError(e.toString()));
    }
  }

  /// Fetches all pages for a single category/query combination.
  Future<List<MenuItem>> _fetchAllPages({
    String? q,
    String? categoryId,
    DietaryType? dietaryType,
    CancelToken? cancelToken,
  }) async {
    final all = <MenuItem>[];
    var page = 1;
    while (true) {
      final result = await _repo.getItemsPage(
        page,
        q: q,
        categoryId: categoryId,
        dietaryType: dietaryType,
        cancelToken: cancelToken,
      );
      all.addAll(result.items);
      if (!result.hasMore) break;
      page++;
    }
    return all;
  }

  // ── Load next page ────────────────────────────────────────────────────────

  Future<void> _onNextPage(
    MenuItemsNextPageRequested event,
    Emitter<MenuItemState> emit,
  ) async {
    final current = state;
    if (current is! MenuItemLoaded) return;
    // No pagination when multiple IDs were merged (all data already loaded).
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.currentPage + 1;
      final result = await _repo.getItemsPage(
        nextPage,
        q: current.q,
        categoryId: current.categoryId,
        dietaryType: current.dietaryType,
      );
      emit(current.copyWith(
        items: [...current.items, ...result.items],
        currentPage: nextPage,
        hasMore: result.hasMore,
        total: result.total,
        isLoadingMore: false,
      ));
    } on ApiException catch (e) {
      emit(MenuItemOperationError(
        items: current.items,
        message: e.message,
        currentPage: current.currentPage,
        hasMore: current.hasMore,
        q: current.q,
        categoryId: current.categoryId,
        categoryIds: current.categoryIds,
        dietaryType: current.dietaryType,
      ));
    } catch (e) {
      emit(MenuItemOperationError(
        items: current.items,
        message: e.toString(),
        currentPage: current.currentPage,
        hasMore: current.hasMore,
        q: current.q,
        categoryId: current.categoryId,
        categoryIds: current.categoryIds,
        dietaryType: current.dietaryType,
      ));
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<void> _onCreate(
    MenuItemCreateRequested event,
    Emitter<MenuItemState> emit,
  ) async {
    final currentItems = _currentItems;
    final p = _currentPagination;
    try {
      final created = await _repo.createItem(event.payload);
      emit(MenuItemLoaded(
        items: [...currentItems, created],
        currentPage: p.page,
        hasMore: p.hasMore,
        q: p.q,
        categoryId: p.categoryId,
        categoryIds: p.categoryIds,
        dietaryType: p.dietaryType,
      ));
    } on ApiException catch (e) {
      emit(MenuItemOperationError(items: currentItems, message: e.message));
    } catch (e) {
      emit(MenuItemOperationError(items: currentItems, message: e.toString()));
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> _onUpdate(
    MenuItemUpdateRequested event,
    Emitter<MenuItemState> emit,
  ) async {
    final currentItems = _currentItems;
    final p = _currentPagination;
    try {
      final updated = await _repo.updateItem(event.id, event.payload);
      emit(MenuItemLoaded(
        items: currentItems.map((i) => i.id == event.id ? updated : i).toList(),
        currentPage: p.page,
        hasMore: p.hasMore,
        q: p.q,
        categoryId: p.categoryId,
        categoryIds: p.categoryIds,
        dietaryType: p.dietaryType,
      ));
    } on ApiException catch (e) {
      emit(MenuItemOperationError(items: currentItems, message: e.message));
    } catch (e) {
      emit(MenuItemOperationError(items: currentItems, message: e.toString()));
    }
  }

  // ── Optimistic toggle ─────────────────────────────────────────────────────

  Future<void> _onToggle(
    MenuItemAvailabilityToggled event,
    Emitter<MenuItemState> emit,
  ) async {
    final previousItems = _currentItems;
    final p = _currentPagination;
    final optimistic = previousItems
        .map((i) =>
            i.id == event.id ? i.copyWith(isAvailable: event.isAvailable) : i)
        .toList();
    emit(MenuItemLoaded(
      items: optimistic,
      currentPage: p.page,
      hasMore: p.hasMore,
      q: p.q,
      categoryId: p.categoryId,
      categoryIds: p.categoryIds,
      dietaryType: p.dietaryType,
    ));

    try {
      await _repo.toggleAvailability(event.id, isAvailable: event.isAvailable);
    } on ApiException catch (e) {
      emit(MenuItemOperationError(items: previousItems, message: e.message));
    } catch (e) {
      emit(MenuItemOperationError(items: previousItems, message: e.toString()));
    }
  }

  // ── Bulk upload ───────────────────────────────────────────────────────────

  Future<void> _onBulkUpload(
    MenuBulkUploadRequested event,
    Emitter<MenuItemState> emit,
  ) async {
    final previousItems = _currentItems;
    emit(MenuBulkUploadInProgress(items: previousItems));

    try {
      final result = await _repo.bulkUploadMenu(
        fileBytes: event.fileBytes,
        filename: event.filename,
        onSendProgress: (sent, total) {
          if (total > 0) add(_BulkUploadProgressUpdated(sent / total));
        },
      );
      final fresh = await _repo.getItemsPage(1);
      emit(MenuBulkUploadSuccess(items: fresh.items, result: result));
    } on ApiException catch (e) {
      emit(MenuItemOperationError(items: previousItems, message: e.message));
    } catch (e) {
      emit(MenuItemOperationError(items: previousItems, message: e.toString()));
    }
  }

  void _onBulkUploadProgress(
    _BulkUploadProgressUpdated event,
    Emitter<MenuItemState> emit,
  ) {
    final s = state;
    if (s is MenuBulkUploadInProgress) {
      emit(MenuBulkUploadInProgress(items: s.items, progress: event.progress));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<MenuItem> get _currentItems => switch (state) {
        MenuItemLoaded(:final items) => items,
        MenuItemOperationError(:final items) => items,
        MenuBulkUploadInProgress(:final items) => items,
        MenuBulkUploadSuccess(:final items) => items,
        _ => [],
      };

  ({
    int page,
    bool hasMore,
    String? q,
    String? categoryId,
    List<String>? categoryIds,
    DietaryType? dietaryType
  }) get _currentPagination => switch (state) {
        MenuItemLoaded(
          :final currentPage,
          :final hasMore,
          :final q,
          :final categoryId,
          :final categoryIds,
          :final dietaryType,
        ) =>
          (
            page: currentPage,
            hasMore: hasMore,
            q: q,
            categoryId: categoryId,
            categoryIds: categoryIds,
            dietaryType: dietaryType,
          ),
        MenuItemOperationError(
          :final currentPage,
          :final hasMore,
          :final q,
          :final categoryId,
          :final categoryIds,
          :final dietaryType,
        ) =>
          (
            page: currentPage,
            hasMore: hasMore,
            q: q,
            categoryId: categoryId,
            categoryIds: categoryIds,
            dietaryType: dietaryType,
          ),
        _ => (
            page: 1,
            hasMore: false,
            q: null,
            categoryId: null,
            categoryIds: null,
            dietaryType: null,
          ),
      };
}
