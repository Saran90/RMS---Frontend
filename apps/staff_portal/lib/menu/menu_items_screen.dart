// Feature: rms-flutter-frontend
// Implements: Requirements 7.1–7.11

import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Menu Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<MenuItemBloc>()
                .add(const MenuItemsLoadRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_item_fab',
        onPressed: () => showMenuItemForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: const MenuItemsBodyContent(),
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
                  // ── Search bar ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacing16,
                      AppTheme.spacing12,
                      AppTheme.spacing16,
                      AppTheme.spacing8,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search items…',
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: AppTheme.mutedText),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: AppTheme.mutedText),
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
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing12,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardSurface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // ── Category filter chips ─────────────────────────
                  if (categories.isNotEmpty)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing16),
                        itemCount: categories.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTheme.spacing8),
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            return _FilterChip(
                              label: 'All',
                              selected: _selectedCategory == null,
                              onTap: () => _onCategorySelected(null),
                            );
                          }
                          final cat = categories[i - 1];
                          final isSelected = _selectedCategory?.id == cat.id;
                          return _FilterChip(
                            label: cat.name,
                            selected: isSelected,
                            onTap: () =>
                                _onCategorySelected(isSelected ? null : cat),
                          );
                        },
                      ),
                    ),

                  if (categories.isNotEmpty)
                    const SizedBox(height: AppTheme.spacing8),

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
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppTheme.spacing8,
          mainAxisSpacing: AppTheme.spacing8,
          childAspectRatio: 2.6,
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
                child: _CategorySectionHeader(
                  name: entry.value.categoryName,
                  count: entry.value.items.length,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
                top: showHeaders ? AppTheme.spacing4 : AppTheme.spacing16,
                bottom: AppTheme.spacing4,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: AppTheme.spacing8,
                  mainAxisSpacing: AppTheme.spacing8,
                  childAspectRatio: 2.6,
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
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              child: widget.isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : !widget.hasMore
                      ? Center(
                          child: Text(
                            '${widget.items.length} item${widget.items.length == 1 ? '' : 's'} shown',
                            style: const TextStyle(
                                color: AppTheme.mutedText, fontSize: 12),
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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch || hasCategoryFilter
                ? Icons.search_off
                : Icons.restaurant_menu_outlined,
            size: 56,
            color: AppTheme.mutedText,
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText)),
          if (sub != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(sub,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.mutedText)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category section header
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({required this.name, required this.count});
  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        top: AppTheme.spacing16,
        bottom: AppTheme.spacing4,
      ),
      child: Row(
        children: [
          const Icon(Icons.label_outline, size: 14, color: AppTheme.mutedText),
          const SizedBox(width: AppTheme.spacing4),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text('$count',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.mutedText)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChipData {
  const _CategoryChipData({
    required this.id,
    required this.name,
    required this.allIds,
  });
  final String id; // primary — used for display/selection equality
  final String name;
  final List<String> allIds; // all duplicate UUIDs for this name
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
          border:
              Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppTheme.onPrimary : AppTheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item card
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isAvailable;

    return Semantics(
      label: '${item.name}, ₹${item.basePrice.toStringAsFixed(0)}, '
          '${item.isAvailable ? "available" : "unavailable"}',
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: unavailable ? AppTheme.surfaceVariant : AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: BorderSide(
              color: unavailable ? AppTheme.outline : AppTheme.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: unavailable ? AppTheme.outline : AppTheme.success,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Center(child: DietaryBadge(type: item.dietaryType)),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: unavailable
                                  ? AppTheme.mutedText
                                  : AppTheme.onSurface,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${item.basePrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit_outlined, size: 13),
                    color: AppTheme.primary,
                    tooltip: 'Edit ${item.name}',
                    onPressed: () => showMenuItemForm(context, item: item),
                  ),
                ),
              ),
              Center(
                child: Semantics(
                  label: unavailable
                      ? 'Mark ${item.name} available'
                      : 'Mark ${item.name} unavailable',
                  child: Transform.scale(
                    scale: 0.65,
                    child: Switch(
                      value: item.isAvailable,
                      onChanged: (val) => context.read<MenuItemBloc>().add(
                            MenuItemAvailabilityToggled(
                                id: item.id, isAvailable: val),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
            ],
          ),
        ),
      ),
    );
  }
}
