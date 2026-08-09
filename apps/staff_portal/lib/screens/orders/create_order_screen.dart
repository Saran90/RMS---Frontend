// Feature: rms-flutter-frontend
// Implements: Requirements 9.5, 9.6, 9.10

import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:staff_portal/menu/menu_category.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';
import 'package:staff_portal/menu/menu_repository.dart';
import 'package:staff_portal/orders/order_bloc.dart';
import 'package:staff_portal/tables/table_bloc.dart';
import 'package:staff_portal/tables/table_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cart item — one line in the order being built
// ─────────────────────────────────────────────────────────────────────────────

class _CartItem {
  _CartItem({required this.menuItem, this.quantity = 1});
  final MenuItem menuItem;
  int quantity;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Screen for creating a new order.
/// Requirements: 9.5, 9.6, 9.10
class CreateOrderScreen extends StatelessWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menuRepo = context.read<MenuRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderBloc>(
          create: (ctx) => OrderBloc(repository: ctx.read()),
        ),
        BlocProvider<TableBloc>(
          create: (ctx) => TableBloc(repository: ctx.read<TableRepository>())
            ..add(const TablesLoadRequested()),
        ),
        BlocProvider<MenuCategoryBloc>(
          create: (_) => MenuCategoryBloc(repository: menuRepo)
            ..add(const MenuCategoriesLoadRequested()),
        ),
      ],
      child: const _CreateOrderView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _CreateOrderView extends StatefulWidget {
  const _CreateOrderView();
  @override
  State<_CreateOrderView> createState() => _CreateOrderViewState();
}

class _CreateOrderViewState extends State<_CreateOrderView> {
  final _formKey = GlobalKey<FormState>();
  OrderType? _orderType;
  Table? _selectedTable;
  String? _errorMessage;
  bool _submitting = false;

  // Cart: menuItemId → _CartItem
  final Map<String, _CartItem> _cart = {};

  bool get _isDineIn => _orderType == OrderType.dineIn;
  List<_CartItem> get _cartItems => _cart.values.toList();

  void _openItemPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<MenuCategoryBloc>(),
        child: _ItemPickerSheet(
          cart: _cart,
          onCartChanged: (cart) => setState(() {}),
        ),
      ),
    );
  }

  void _setQty(String menuItemId, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(menuItemId);
      } else {
        _cart[menuItemId]!.quantity = qty;
      }
    });
  }

  void _submit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_cart.isEmpty) {
      setState(() => _errorMessage = 'Add at least one item to the order.');
      return;
    }

    // Check for unavailable items in cart
    final unavailableItems = _cartItems
        .where((c) => !c.menuItem.isAvailable)
        .map((c) => c.menuItem.name)
        .toList();

    if (unavailableItems.isNotEmpty) {
      final itemList = unavailableItems.length == 1
          ? unavailableItems.first
          : unavailableItems.take(unavailableItems.length - 1).join(', ') +
              ' and ${unavailableItems.last}';
      setState(() => _errorMessage =
          'Cannot create order: ${unavailableItems.length == 1 ? 'Item' : 'Items'} $itemList ${unavailableItems.length == 1 ? 'is' : 'are'} currently unavailable. Please remove them from the cart.');
      return;
    }

    final itemsPayload = _cartItems
        .map((c) => {
              'menu_item_id': c.menuItem.id,
              'name': c.menuItem.name,
              'quantity': c.quantity,
              'unit_price': c.menuItem.basePrice,
            })
        .toList();

    final payload = <String, dynamic>{
      'order_type': _orderType!.jsonValue,
      'items': itemsPayload,
      if (_isDineIn && _selectedTable != null) 'table_id': _selectedTable!.id,
    };

    setState(() => _submitting = true);
    context.read<OrderBloc>().add(OrderCreateRequested(payload));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          context.go('/orders/${state.order.id}');
        } else if (state is OrderError) {
          setState(() {
            _errorMessage = state.message;
            _submitting = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('New Order')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            children: [
              if (_errorMessage != null) ...[
                _ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],

              // Order type
              const _SectionLabel(label: 'Order Type'),
              const SizedBox(height: AppTheme.spacing8),
              DropdownButtonFormField<OrderType>(
                decoration: const InputDecoration(labelText: 'Order Type'),
                initialValue: _orderType,
                items: const [
                  DropdownMenuItem(
                      value: OrderType.dineIn, child: Text('Dine-in')),
                  DropdownMenuItem(
                      value: OrderType.takeaway, child: Text('Takeaway')),
                  DropdownMenuItem(
                      value: OrderType.delivery, child: Text('Delivery')),
                ],
                onChanged: (v) => setState(() {
                  _orderType = v;
                  _selectedTable = null;
                }),
                validator: (_) =>
                    _orderType == null ? 'Please select an order type' : null,
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Table (dine-in only)
              if (_isDineIn) ...[
                const _SectionLabel(label: 'Table'),
                const SizedBox(height: AppTheme.spacing8),
                _TableDropdown(
                  selectedTable: _selectedTable,
                  onChanged: (t) => setState(() => _selectedTable = t),
                  isDineIn: _isDineIn,
                ),
                const SizedBox(height: AppTheme.spacing24),
              ],

              // Items section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel(label: 'Items'),
                  FilledButton.icon(
                    onPressed: _openItemPicker,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Items'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),

              // Warning for unavailable items in cart
              if (_cartItems.any((c) => !c.menuItem.isAvailable)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 20, color: AppTheme.error),
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: Text(
                          'Some items in your cart are unavailable and must be removed before creating the order',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onErrorContainer,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
              ],

              if (_cart.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Text(
                        'No items added yet — tap Add Items to browse the menu',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppTheme.mutedText, fontSize: 13)),
                  ),
                )
              else
                ..._cartItems.map((c) => _CartItemRow(
                      cartItem: c,
                      onQtyChanged: (qty) => _setQty(c.menuItem.id, qty),
                    )),

              const SizedBox(height: AppTheme.spacing16),

              // Order total
              if (_cart.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '₹${_cartItems.fold(0.0, (s, c) => s + c.menuItem.basePrice * c.quantity).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.spacing24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.onPrimary))
                    : const Text('Create Order'),
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart item row — shows in the order summary
// ─────────────────────────────────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.cartItem, required this.onQtyChanged});
  final _CartItem cartItem;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    final item = cartItem.menuItem;
    final isUnavailable = !item.isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: isUnavailable
            ? AppTheme.errorContainer.withValues(alpha: 0.1)
            : AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isUnavailable
              ? AppTheme.error.withValues(alpha: 0.3)
              : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DietaryBadge(type: item.dietaryType),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isUnavailable
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isUnavailable ? AppTheme.mutedText : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('₹${item.basePrice.toStringAsFixed(0)} each',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.mutedText)),
                  ],
                ),
              ),
              // Qty stepper
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () => onQtyChanged(cartItem.quantity - 1),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('${cartItem.quantity}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () => onQtyChanged(cartItem.quantity + 1),
                    ),
                  ),
                ],
              ),
              // Line total
              SizedBox(
                width: 64,
                child: Text(
                  '₹${(item.basePrice * cartItem.quantity).toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (isUnavailable) ...[
            const SizedBox(height: AppTheme.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber,
                      size: 14, color: AppTheme.error),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    'This item is currently unavailable',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onErrorContainer,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet({required this.cart, required this.onCartChanged});
  final Map<String, _CartItem> cart;
  final ValueChanged<Map<String, _CartItem>> onCartChanged;

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Current filter state
  String _query = '';
  _CategoryChipData? _selectedCategory; // null = "All"

  // Items managed locally — bypasses the shared MenuItemBloc
  List<MenuItem> _items = [];
  bool _loading = true;
  String? _error;

  // Token to cancel stale fetches when a newer request fires
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetching ──────────────────────────────────────────────────────────────

  /// Fetches all pages for the current [_query] + [_selectedCategory].
  ///
  /// When a category has duplicate UUIDs (bulk-upload artefact) every UUID is
  /// queried in parallel and results are merged so no items are missed.
  ///
  /// A generation counter cancels the previous in-flight request if the user
  /// changes filters before it completes.
  Future<void> _fetchItems() async {
    final generation = ++_fetchGeneration;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final repo = context.read<MenuRepository>();
      final q = _query.isEmpty ? null : _query;
      final cat = _selectedCategory;

      debugPrint(
          '[ItemPicker] _fetchItems gen=$generation q=$q cat=${cat?.name} allIds=${cat?.allIds}');

      List<MenuItem> merged;

      if (cat == null) {
        merged = await _fetchAllPages(repo, q: q, categoryId: null);
      } else if (cat.allIds.length == 1) {
        merged = await _fetchAllPages(repo, q: q, categoryId: cat.allIds.first);
      } else {
        // Duplicate UUIDs — fetch each in parallel and merge
        final results = await Future.wait(
          cat.allIds.map((id) => _fetchAllPages(repo, q: q, categoryId: id)),
        );
        final seen = <String>{};
        merged = [
          for (final batch in results)
            for (final item in batch)
              if (seen.add(item.id)) item,
        ];
      }

      merged.sort((a, b) => a.name.compareTo(b.name));

      debugPrint(
          '[ItemPicker] gen=$generation fetched ${merged.length} items, current gen=$_fetchGeneration');

      // Discard result if a newer fetch has already started
      if (!mounted || generation != _fetchGeneration) return;
      setState(() => _items = merged);
    } catch (e, st) {
      debugPrint('[ItemPicker] ERROR gen=$generation: $e\n$st');
      if (!mounted || generation != _fetchGeneration) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _fetchGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<List<MenuItem>> _fetchAllPages(
    MenuRepository repo, {
    String? q,
    String? categoryId,
  }) async {
    final all = <MenuItem>[];
    var page = 1;
    while (true) {
      debugPrint(
          '[ItemPicker] getItemsPage page=$page q=$q categoryId=$categoryId');
      final result =
          await repo.getItemsPage(page, q: q, categoryId: categoryId);
      debugPrint(
          '[ItemPicker] → ${result.items.length} items, hasMore=${result.hasMore}, total=${result.total}');
      all.addAll(result.items);
      if (!result.hasMore) break;
      page++;
    }
    return all;
  }

  // ── User interactions ─────────────────────────────────────────────────────

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = v.trim();
      if (q == _query) return;
      _query = q; // Set directly — setState will happen inside _fetchItems
      _fetchItems();
    });
  }

  void _onCategorySelected(_CategoryChipData? cat) {
    // Compare by the full set of IDs, not just the primary id
    final sameCategory = cat == null
        ? _selectedCategory == null
        : _selectedCategory != null &&
            cat.allIds.containsAll(_selectedCategory!.allIds) &&
            _selectedCategory!.allIds.containsAll(cat.allIds);
    if (sameCategory) return;
    _selectedCategory = cat; // Set directly — setState in _fetchItems covers it
    _fetchItems();
  }

  // ── Cart helpers ──────────────────────────────────────────────────────────

  void _toggleItem(MenuItem item) {
    setState(() {
      if (widget.cart.containsKey(item.id)) {
        widget.cart.remove(item.id);
      } else {
        widget.cart[item.id] = _CartItem(menuItem: item);
      }
    });
    widget.onCartChanged(widget.cart);
  }

  void _changeQty(MenuItem item, int delta) {
    setState(() {
      if (widget.cart.containsKey(item.id)) {
        final newQty = widget.cart[item.id]!.quantity + delta;
        if (newQty <= 0) {
          widget.cart.remove(item.id);
        } else {
          widget.cart[item.id]!.quantity = newQty;
        }
      } else if (delta > 0) {
        widget.cart[item.id] = _CartItem(menuItem: item, quantity: delta);
      }
    });
    widget.onCartChanged(widget.cart);
  }

  // ── Category chip helpers ─────────────────────────────────────────────────

  List<_CategoryChipData> _uniqueCategories(MenuCategoryState catState) {
    final List<MenuCategory> raw = switch (catState) {
      MenuCategoryLoaded(:final categories) => categories,
      MenuCategoryOperationError(:final categories) => categories,
      _ => const [],
    };

    // Group by normalised name — collapse bulk-upload duplicates into one chip
    // but carry ALL their UUIDs so we can query each one.
    final grouped = <String, List<String>>{};
    final displayNames = <String, String>{};
    for (final c in raw) {
      final key = c.name.toLowerCase();
      grouped.putIfAbsent(key, () => []).add(c.id);
      displayNames[key] = c.name;
    }

    return grouped.entries
        .map((e) => _CategoryChipData(
              id: e.value.first, // stable: list preserves insertion order
              name: displayNames[e.key]!,
              allIds: e.value.toSet(),
            ))
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.cart.length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle bar + title row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spacing16,
                AppTheme.spacing12, AppTheme.spacing16, AppTheme.spacing8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  children: [
                    Expanded(
                        child: Text('Add Items',
                            style: Theme.of(context).textTheme.titleLarge)),
                    if (selectedCount > 0)
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16)),
                        child: Text('Done ($selectedCount)'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16, vertical: AppTheme.spacing4),
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
                        onPressed: () {
                          _searchCtrl.clear();
                          _query = '';
                          _fetchItems();
                        })
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing12),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    borderSide: const BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 1.5)),
              ),
            ),
          ),

          // Category filter chips
          BlocBuilder<MenuCategoryBloc, MenuCategoryState>(
            builder: (context, catState) {
              final categories = _uniqueCategories(catState);
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
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
                          onTap: () => _onCategorySelected(null));
                    }
                    final cat = categories[i - 1];
                    // Use allIds equality so selection survives rebuilds
                    final isSelected = _selectedCategory != null &&
                        _selectedCategory!.allIds.containsAll(cat.allIds) &&
                        cat.allIds.containsAll(_selectedCategory!.allIds);
                    return _FilterChip(
                        label: cat.name,
                        selected: isSelected,
                        onTap: () =>
                            _onCategorySelected(isSelected ? null : cat));
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Item list
          Expanded(child: _buildItemList(scrollCtrl)),
        ],
      ),
    );
  }

  Widget _buildItemList(ScrollController scrollCtrl) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 32),
              const SizedBox(height: AppTheme.spacing8),
              Text('Failed to load items',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppTheme.spacing8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedText)),
              const SizedBox(height: AppTheme.spacing8),
              OutlinedButton(
                  onPressed: _fetchItems, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // Filter to show only available items
    final availableItems = _items.where((item) => item.isAvailable).toList();

    if (availableItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu_outlined,
                  color: AppTheme.mutedText, size: 48),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                _items.isEmpty ? 'No items found' : 'No items available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.mutedText,
                    ),
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'All items in this category are currently unavailable',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, 0, AppTheme.spacing16, AppTheme.spacing32),
      itemCount: availableItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing8),
      itemBuilder: (ctx, i) {
        final item = availableItems[i];
        final cartEntry = widget.cart[item.id];
        return _PickerItemTile(
          item: item,
          qty: cartEntry?.quantity ?? 0,
          onAdd: () => _toggleItem(item),
          onIncrement: () => _changeQty(item, 1),
          onDecrement: () => _changeQty(item, -1),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single item tile in the picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PickerItemTile extends StatelessWidget {
  const _PickerItemTile({
    required this.item,
    required this.qty,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });
  final MenuItem item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final inCart = qty > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: inCart ? AppTheme.primaryContainer : AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: inCart ? AppTheme.primary : AppTheme.border),
      ),
      child: Row(
        children: [
          DietaryBadge(type: item.dietaryType),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('₹${item.basePrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (!inCart)
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: AppTheme.primary),
                ),
                child: const Text('Add'),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: onDecrement,
                  ),
                ),
                SizedBox(
                    width: 28,
                    child: Text('$qty',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: onIncrement,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _TableDropdown extends StatelessWidget {
  const _TableDropdown({
    required this.selectedTable,
    required this.onChanged,
    required this.isDineIn,
  });
  final Table? selectedTable;
  final ValueChanged<Table?> onChanged;
  final bool isDineIn;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TableBloc, TableState>(
      builder: (context, state) {
        if (state is TableInitial || state is TableLoading) {
          return InputDecorator(
            decoration: const InputDecoration(labelText: 'Table'),
            child: Row(children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: AppTheme.spacing8),
              Text('Loading tables…',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.mutedText)),
            ]),
          );
        }
        final tables = switch (state) {
          TableLoaded(:final tables) => tables,
          TableOperationError(:final tables) => tables,
          _ => <Table>[],
        };
        final sorted = [...tables]..sort((a, b) {
            final aAvail = a.status == TableStatus.available ? 0 : 1;
            final bAvail = b.status == TableStatus.available ? 0 : 1;
            if (aAvail != bAvail) return aAvail - bAvail;
            return a.tableNumber.compareTo(b.tableNumber);
          });
        return DropdownButtonFormField<Table>(
          decoration: const InputDecoration(labelText: 'Table *'),
          value: selectedTable,
          hint: const Text('Select a table'),
          isExpanded: true,
          items: sorted.map((table) {
            final available = table.status == TableStatus.available;
            final suffix = switch (table.status) {
              TableStatus.available => '',
              TableStatus.occupied => ' (Occupied)',
              TableStatus.reserved => ' (Reserved)',
              TableStatus.cleaning => ' (Cleaning)',
            };
            return DropdownMenuItem<Table>(
              value: table,
              enabled: available,
              child: Text('Table ${table.tableNumber}$suffix',
                  style: TextStyle(
                      color:
                          available ? AppTheme.onSurface : AppTheme.mutedText)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) => isDineIn && v == null
              ? 'Please select a table for dine-in orders'
              : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChipData {
  const _CategoryChipData(
      {required this.id, required this.name, required this.allIds});
  final String id; // Primary ID (used for API call)
  final String name;
  final Set<String> allIds; // All duplicate IDs with the same name
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.onErrorContainer)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppTheme.onErrorContainer,
            onPressed: onDismiss,
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
