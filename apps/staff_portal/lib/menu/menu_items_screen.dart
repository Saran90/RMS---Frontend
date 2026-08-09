// Feature: rms-flutter-frontend
// Implements: Requirements 7.1–7.11

import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';
import 'package:staff_portal/menu/menu_design.dart';
import 'package:staff_portal/menu/menu_item_bloc.dart';
import 'package:staff_portal/menu/menu_item_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Standalone screen entry point
// ─────────────────────────────────────────────────────────────────────────────

class MenuItemsScreen extends StatelessWidget {
  const MenuItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: menuBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu items',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: menuTitle,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Search, filter, and manage availability',
                        style: TextStyle(fontSize: 12.5, color: menuMuted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<MenuItemBloc>()
                      .add(const MenuItemsLoadRequested()),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: menuTitle,
                    side: const BorderSide(color: menuBorder),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => showMenuItemForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add item'),
                  style: FilledButton.styleFrom(
                    backgroundColor: menuAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: MenuItemsBodyContent()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body content (used inside the tab scaffold)
// ─────────────────────────────────────────────────────────────────────────────

class MenuItemsBodyContent extends StatefulWidget {
  const MenuItemsBodyContent({super.key});

  @override
  State<MenuItemsBodyContent> createState() => _MenuItemsBodyContentState();
}

class _MenuItemsBodyContentState extends State<MenuItemsBodyContent> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _CategoryChipData? _selectedCategory; // null = "All"
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // 300 ms debounce before firing server request.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = value.trim();
      if (q == _query) return;
      setState(() => _query = q);
      _reload();
    });
  }

  void _onCategorySelected(_CategoryChipData? cat) {
    if (cat?.id == _selectedCategory?.id) return;
    setState(() => _selectedCategory = cat);
    _reload();
  }

  void _reload() {
    context.read<MenuItemBloc>().add(MenuItemsLoadRequested(
          q: _query.isEmpty ? null : _query,
          // Pass ALL category IDs so duplicate-UUID categories show all items.
          categoryIds: _selectedCategory?.allIds,
        ));
  }

  List<_CategoryChipData> _uniqueCategories(MenuCategoryState state) {
    final raw = switch (state) {
      MenuCategoryLoaded(:final categories) => categories,
      MenuCategoryOperationError(:final categories) => categories,
      _ => <dynamic>[],
    };
    // Group by normalised name so bulk-upload duplicates collapse into one chip
    // but carry all their UUIDs for multi-ID querying.
    final grouped = <String, List<String>>{};
    final displayNames = <String, String>{};
    for (final c in raw) {
      final key = (c.name as String).toLowerCase();
      grouped.putIfAbsent(key, () => []).add(c.id as String);
      displayNames[key] = c.name as String;
    }
    return grouped.entries
        .map((e) => _CategoryChipData(
              id: e.value.first,
              name: displayNames[e.key]!,
              allIds: e.value,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuItemBloc, MenuItemState>(
      listener: (context, state) {
        if (state is MenuItemOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ));
        }
      },
      child: BlocBuilder<MenuItemBloc, MenuItemState>(
        builder: (context, itemState) {
          return BlocBuilder<MenuCategoryBloc, MenuCategoryState>(
            builder: (context, categoryState) {
              final categories = _uniqueCategories(categoryState);

              final body = switch (itemState) {
                MenuItemInitial() || MenuItemLoading() => const _LoadingBody(),
                MenuItemLoaded(
                  :final items,
                  :final hasMore,
                  :final isLoadingMore
                ) =>
                  _LoadedBody(
                    items: items,
                    categoryState: categoryState,
                    hasMore: hasMore,
                    isLoadingMore: isLoadingMore,
                    activeSearch: _query,
                    activeCategoryId: _selectedCategory?.id,
                  ),
                MenuItemOperationError(:final items) => _LoadedBody(
                    items: items,
                    categoryState: categoryState,
                    hasMore: false,
                    isLoadingMore: false,
                    activeSearch: _query,
                    activeCategoryId: _selectedCategory?.id,
                  ),
                MenuBulkUploadInProgress(:final items) => _LoadedBody(
                    items: items,
                    categoryState: categoryState,
                    hasMore: false,
                    isLoadingMore: false,
                    activeSearch: _query,
                    activeCategoryId: _selectedCategory?.id,
                  ),
                MenuBulkUploadSuccess(:final items) => _LoadedBody(
                    items: items,
                    categoryState: categoryState,
                    hasMore: false,
                    isLoadingMore: false,
                    activeSearch: _query,
                    activeCategoryId: _selectedCategory?.id,
                  ),
                MenuItemError(:final message) => ErrorStateWidget(
                    message: message,
                    onRetry: () => context
                        .read<MenuItemBloc>()
                        .add(const MenuItemsLoadRequested()),
                  ),
              };

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search items…',
                        hintStyle: const TextStyle(color: menuMuted),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: menuMuted,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: menuMuted),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                  _reload();
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: menuCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: menuBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: menuBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: menuAccent, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  if (categories.isNotEmpty)
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            return MenuChoiceChip(
                              label: 'All',
                              selected: _selectedCategory == null,
                              onTap: () => _onCategorySelected(null),
                            );
                          }
                          final cat = categories[i - 1];
                          final isSelected = _selectedCategory?.id == cat.id;
                          return MenuChoiceChip(
                            label: cat.name,
                            selected: isSelected,
                            onTap: () =>
                                _onCategorySelected(isSelected ? null : cat),
                          );
                        },
                      ),
                    ),

                  if (categories.isNotEmpty) const SizedBox(height: 8),

                  Expanded(child: body),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.8,
        ),
        itemCount: 12,
        itemBuilder: (_, __) =>
            const LoadingSkeletonCard(height: double.infinity),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loaded grid  (StatefulWidget — owns the ScrollController)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({
    required this.items,
    required this.categoryState,
    required this.hasMore,
    required this.isLoadingMore,
    required this.activeSearch,
    required this.activeCategoryId,
  });

  final List<MenuItem> items;
  final MenuCategoryState categoryState;
  final bool hasMore;
  final bool isLoadingMore;
  final String activeSearch;
  final String? activeCategoryId;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 300) return;

    // Read live BLoC state — widget.hasMore/isLoadingMore are snapshot values.
    final blocState = context.read<MenuItemBloc>().state;
    if (blocState is! MenuItemLoaded) return;
    if (!blocState.hasMore || blocState.isLoadingMore) return;

    context.read<MenuItemBloc>().add(const MenuItemsNextPageRequested());
  }

  Map<String, String> _categoryNames() {
    final cats = switch (widget.categoryState) {
      MenuCategoryLoaded(:final categories) => categories,
      MenuCategoryOperationError(:final categories) => categories,
      _ => <dynamic>[],
    };
    return {for (final c in cats) c.id as String: c.name as String};
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _EmptyState(
        hasSearch: widget.activeSearch.isNotEmpty,
        hasCategoryFilter: widget.activeCategoryId != null,
        query: widget.activeSearch,
      );
    }

    final catNames = _categoryNames();

    // When filtering by a category that has duplicate UUIDs (bulk-upload
    // artefact), collapse all those UUIDs to a single canonical key so items
    // appear in one group instead of N separate sections.
    final blocState = context.read<MenuItemBloc>().state;
    final activeCategoryIds = switch (blocState) {
      MenuItemLoaded(:final categoryIds) => categoryIds?.toSet(),
      MenuItemOperationError(:final categoryIds) => categoryIds?.toSet(),
      _ => null,
    };

    String _canonicalCategoryId(String id) {
      if (activeCategoryIds != null && activeCategoryIds.contains(id)) {
        return activeCategoryIds.first; // all duplicates → same key
      }
      return id;
    }

    String _categoryName(String id) {
      // Try to find any name from the duplicate set, fall back to the raw id.
      if (activeCategoryIds != null && activeCategoryIds.contains(id)) {
        for (final cid in activeCategoryIds) {
          final name = catNames[cid];
          if (name != null) return name;
        }
      }
      return catNames[id] ?? id;
    }

    final grouped = <String, ({String categoryName, List<MenuItem> items})>{};
    for (final item in widget.items) {
      final key = _canonicalCategoryId(item.categoryId);
      final name = _categoryName(item.categoryId);
      if (grouped.containsKey(key)) {
        grouped[key]!.items.add(item);
      } else {
        grouped[key] = (categoryName: name, items: [item]);
      }
    }

    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => a.value.categoryName
          .toLowerCase()
          .compareTo(b.value.categoryName.toLowerCase()));

    final showHeaders =
        widget.activeCategoryId == null && sortedGroups.length > 1;

    return LayoutBuilder(builder: (_, constraints) {
      final cols = constraints.maxWidth >= 720 ? 4 : 3;

      return CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          for (final entry in sortedGroups) ...[
            if (showHeaders)
              SliverToBoxAdapter(
                child: MenuSectionHeader(
                  name: entry.value.categoryName,
                  count: entry.value.items.length,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: showHeaders ? 4 : 8,
                bottom: 4,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _MenuItemCard(item: entry.value.items[i]),
                  childCount: entry.value.items.length,
                ),
              ),
            ),
          ],

          // Footer: spinner while loading more, or item count when done.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: widget.isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: menuAccent,
                        ),
                      ),
                    )
                  : !widget.hasMore
                      ? Center(
                          child: Text(
                            '${widget.items.length} item${widget.items.length == 1 ? '' : 's'} shown',
                            style: const TextStyle(
                              color: menuMuted,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasSearch,
    required this.hasCategoryFilter,
    required this.query,
  });

  final bool hasSearch;
  final bool hasCategoryFilter;
  final String query;

  @override
  Widget build(BuildContext context) {
    final message = hasSearch
        ? 'No items match "$query"'
        : hasCategoryFilter
            ? 'No items in this category'
            : 'No menu items yet';
    final sub = (!hasSearch && !hasCategoryFilter)
        ? 'Add items or use Bulk Upload to get started'
        : null;

    return MenuEmptyState(
      icon: hasSearch || hasCategoryFilter
          ? Icons.search_off
          : Icons.restaurant_menu_outlined,
      title: message,
      subtitle: sub,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip data
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChipData {
  const _CategoryChipData({
    required this.id,
    required this.name,
    required this.allIds,
  });
  final String id; // primary — used for display/selection equality
  final String name;
  final List<String> allIds;
}

// ─────────────────────────────────────────────────────────────────────────────
// Item card
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      name: item.name,
      price: item.basePrice,
      dietaryType: item.dietaryType,
      isAvailable: item.isAvailable,
      onEdit: () => showMenuItemForm(context, item: item),
      onAvailabilityChanged: (val) => context.read<MenuItemBloc>().add(
            MenuItemAvailabilityToggled(id: item.id, isAvailable: val),
          ),
    );
  }
}
