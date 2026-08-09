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
import 'package:staff_portal/orders/order_design.dart';
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
      backgroundColor: Colors.transparent,
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
    if (_orderType == null) {
      setState(() => _errorMessage = 'Please select an order type.');
      return;
    }
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

  double get _cartTotal =>
      _cartItems.fold(0.0, (s, c) => s + c.menuItem.basePrice * c.quantity);

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
        backgroundColor: orderBg,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CreateOrderHeader(
                itemCount: _cart.length,
                total: _cartTotal,
                submitting: _submitting,
                onCreate: _submit,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    if (_errorMessage != null) ...[
                      _ErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                    ],
                    OrderSectionCard(
                      title: 'Order type',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OrderChoiceChip(
                            label: 'Dine-in',
                            selected: _orderType == OrderType.dineIn,
                            onTap: () => setState(() {
                              _orderType = OrderType.dineIn;
                              _selectedTable = null;
                            }),
                          ),
                          OrderChoiceChip(
                            label: 'Takeaway',
                            selected: _orderType == OrderType.takeaway,
                            onTap: () => setState(() {
                              _orderType = OrderType.takeaway;
                              _selectedTable = null;
                            }),
                          ),
                          OrderChoiceChip(
                            label: 'Delivery',
                            selected: _orderType == OrderType.delivery,
                            onTap: () => setState(() {
                              _orderType = OrderType.delivery;
                              _selectedTable = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    if (_isDineIn) ...[
                      const SizedBox(height: 16),
                      OrderSectionCard(
                        title: 'Table',
                        child: _TableDropdown(
                          selectedTable: _selectedTable,
                          onChanged: (t) => setState(() => _selectedTable = t),
                          isDineIn: _isDineIn,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OrderSectionCard(
                      title: 'Items',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _openItemPicker,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add items'),
                              style: FilledButton.styleFrom(
                                backgroundColor: orderAccent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 36),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_cartItems.any((c) => !c.menuItem.isAvailable)) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.error.withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber,
                                      size: 18, color: AppTheme.error),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Remove unavailable items before creating the order',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_cart.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: orderDivider,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: orderBorder),
                              ),
                              child: const Text(
                                'No items yet — tap Add items to browse the menu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: orderMuted,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            ..._cartItems.map(
                              (c) => _CartItemRow(
                                cartItem: c,
                                onQtyChanged: (qty) =>
                                    _setQty(c.menuItem.id, qty),
                              ),
                            ),
                          if (_cart.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: orderDivider),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: orderTitle,
                                  ),
                                ),
                                Text(
                                  '₹${_cartTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: orderAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _CreateOrderHeader extends StatelessWidget {
  const _CreateOrderHeader({
    required this.itemCount,
    required this.total,
    required this.submitting,
    required this.onCreate,
  });

  final int itemCount;
  final double total;
  final bool submitting;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Back to orders',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: orderTitle),
            style: IconButton.styleFrom(
              backgroundColor: orderCard,
              side: const BorderSide(color: orderBorder),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New order',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: orderTitle,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  itemCount == 0
                      ? 'Select type and add menu items'
                      : '$itemCount ${itemCount == 1 ? 'item' : 'items'} · ₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12.5, color: orderMuted),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: submitting ? null : onCreate,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Create order'),
            style: FilledButton.styleFrom(
              backgroundColor: orderAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnavailable ? orderDivider.withValues(alpha: 0.5) : orderBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnavailable
              ? AppTheme.error.withValues(alpha: 0.35)
              : orderBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              color: isUnavailable ? AppTheme.error : orderAccent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                child: Row(
                  children: [
                    DietaryBadge(type: item.dietaryType),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isUnavailable ? orderMuted : orderTitle,
                              decoration: isUnavailable
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '₹${item.basePrice.toStringAsFixed(0)} each',
                            style: const TextStyle(
                              fontSize: 12,
                              color: orderMuted,
                            ),
                          ),
                          if (isUnavailable)
                            const Text(
                              'Unavailable',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _QtyStepper(
                      quantity: cartItem.quantity,
                      onDecrement: () => onQtyChanged(cartItem.quantity - 1),
                      onIncrement: () => onQtyChanged(cartItem.quantity + 1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${(item.basePrice * cartItem.quantity).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isUnavailable ? orderMuted : orderAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: orderCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: orderBorder),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 16),
            onPressed: onDecrement,
            color: orderTitle,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: orderTitle,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 16),
            onPressed: onIncrement,
            color: orderAccent,
          ),
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
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: orderCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: orderBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: orderTitle,
                          ),
                        ),
                      ),
                      if (selectedCount > 0)
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: orderAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text('Done ($selectedCount)'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search items…',
                  hintStyle: const TextStyle(color: orderMuted),
                  prefixIcon:
                      const Icon(Icons.search, size: 20, color: orderMuted),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: orderMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            _query = '';
                            _fetchItems();
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: orderBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: orderBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: orderBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: orderAccent, width: 1.5),
                  ),
                ),
              ),
            ),
            BlocBuilder<MenuCategoryBloc, MenuCategoryState>(
              builder: (context, catState) {
                final categories = _uniqueCategories(catState);
                if (categories.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return OrderChoiceChip(
                          label: 'All',
                          selected: _selectedCategory == null,
                          onTap: () => _onCategorySelected(null),
                        );
                      }
                      final cat = categories[i - 1];
                      final isSelected = _selectedCategory != null &&
                          _selectedCategory!.allIds.containsAll(cat.allIds) &&
                          cat.allIds.containsAll(_selectedCategory!.allIds);
                      return OrderChoiceChip(
                        label: cat.name,
                        selected: isSelected,
                        onTap: () =>
                            _onCategorySelected(isSelected ? null : cat),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildItemList(scrollCtrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(ScrollController scrollCtrl) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: orderAccent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 32),
              const SizedBox(height: 12),
              const Text(
                'Failed to load items',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: orderTitle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: orderMuted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _fetchItems,
                style: OutlinedButton.styleFrom(
                  foregroundColor: orderAccent,
                  side: const BorderSide(color: orderAccent),
                ),
                child: const Text('Retry'),
              ),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: orderAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_menu_outlined,
                  color: orderAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _items.isEmpty ? 'No items found' : 'No items available',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: orderTitle,
                ),
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'All items in this category are currently unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: orderMuted),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: availableItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: inCart ? orderAccent.withValues(alpha: 0.06) : orderBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: inCart ? orderAccent.withValues(alpha: 0.35) : orderBorder,
        ),
      ),
      child: Row(
        children: [
          DietaryBadge(type: item.dietaryType),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: orderTitle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${item.basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: orderAccent,
                  ),
                ),
              ],
            ),
          ),
          if (!inCart)
            OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: orderAccent,
                side: const BorderSide(color: orderAccent),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Add'),
            )
          else
            _QtyStepper(
              quantity: qty,
              onDecrement: onDecrement,
              onIncrement: onIncrement,
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
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: orderBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: orderBorder),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: orderAccent,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading tables…',
                  style: TextStyle(fontSize: 13, color: orderMuted),
                ),
              ],
            ),
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
          decoration: InputDecoration(
            labelText: 'Table *',
            labelStyle: const TextStyle(color: orderMuted, fontSize: 13),
            filled: true,
            fillColor: orderBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: orderBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: orderBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: orderAccent, width: 1.5),
            ),
          ),
          dropdownColor: orderCard,
          value: selectedTable,
          hint: const Text('Select a table', style: TextStyle(color: orderMuted)),
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
              child: Text(
                'Table ${table.tableNumber}$suffix',
                style: TextStyle(
                  color: available ? orderTitle : orderMuted,
                  fontSize: 13,
                ),
              ),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: orderTitle,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: orderMuted,
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
