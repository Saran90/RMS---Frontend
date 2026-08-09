// Feature: rms-flutter-frontend
// Implements: Requirements 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_portal/inventory/inventory_bloc.dart';
import 'package:staff_portal/inventory/inventory_repository.dart';

/// Inventory Management screen.
///
/// Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InventoryBloc>(
      create: (ctx) => InventoryBloc(repository: ctx.read())
        ..add(const IngredientsLoadRequested()),
      child: const _InventoryView(),
    );
  }
}

// ── Main view ─────────────────────────────────────────────────────────────────

class _InventoryView extends StatelessWidget {
  const _InventoryView();

  void _showStockAdjustmentSheet(
      BuildContext context, List<Ingredient> ingredients) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<InventoryBloc>(),
        child: _StockAdjustmentSheet(
          ingredients: ingredients,
          parentContext: context,
        ),
      ),
    );
  }

  void _showRecipeLinkSheet(
      BuildContext context, List<Ingredient> ingredients) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<InventoryBloc>(),
        child: _RecipeLinkSheet(parentContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<InventoryBloc>()
                .add(const IngredientsLoadRequested()),
          ),
        ],
      ),
      body: BlocConsumer<InventoryBloc, InventoryState>(
        listener: (context, state) {
          // Stock adjustment succeeded (Req 13.4)
          if (state is InventoryLoaded) {
            // Snackbar shown by the sheet on close — handled inside the sheet
          }
          // Recipe link succeeded (Req 13.7)
          if (state is RecipeLinkSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recipe link created'),
                backgroundColor: AppTheme.success,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            InventoryInitial() || InventoryLoading() => const _LoadingView(),
            InventoryLoaded(:final ingredients) ||
            InventoryOperationError(:final ingredients) ||
            RecipeLinkSuccess(:final ingredients) =>
              _IngredientListView(
                ingredients: ingredients,
                onAdjustStock: () => _showStockAdjustmentSheet(
                    context,
                    state is InventoryLoaded
                        ? state.ingredients
                        : state is InventoryOperationError
                            ? state.ingredients
                            : (state as RecipeLinkSuccess).ingredients),
                onLinkRecipe: () => _showRecipeLinkSheet(
                    context,
                    state is InventoryLoaded
                        ? state.ingredients
                        : state is InventoryOperationError
                            ? state.ingredients
                            : (state as RecipeLinkSuccess).ingredients),
              ),
            InventoryError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context
                    .read<InventoryBloc>()
                    .add(const IngredientsLoadRequested()),
              ),
          };
        },
      ),
      // FABs — only when ingredients are loaded
      floatingActionButton: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          final List<Ingredient>? ingredients = switch (state) {
            InventoryLoaded(:final ingredients) => ingredients,
            InventoryOperationError(:final ingredients) => ingredients,
            RecipeLinkSuccess(:final ingredients) => ingredients,
            _ => null,
          };

          if (ingredients == null) return const SizedBox.shrink();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'fab_recipe_link',
                onPressed: () => _showRecipeLinkSheet(context, ingredients),
                icon: const Icon(Icons.link_outlined),
                label: const Text('Link Recipe'),
                backgroundColor: AppTheme.secondary,
                foregroundColor: AppTheme.onSecondary,
              ),
              const SizedBox(height: AppTheme.spacing12),
              FloatingActionButton.extended(
                heroTag: 'fab_adjust_stock',
                onPressed: () =>
                    _showStockAdjustmentSheet(context, ingredients),
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Adjust Stock'),
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Loading — skeleton placeholders (Req 13.2) ────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: const [
        LoadingSkeletonCard(height: 72),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 72),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 72),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 72),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 72),
      ],
    );
  }
}

// ── Ingredient list (Req 13.1, 13.2, 13.3) ───────────────────────────────────

class _IngredientListView extends StatelessWidget {
  const _IngredientListView({
    required this.ingredients,
    required this.onAdjustStock,
    required this.onLinkRecipe,
  });

  final List<Ingredient> ingredients;
  final VoidCallback onAdjustStock;
  final VoidCallback onLinkRecipe;

  @override
  Widget build(BuildContext context) {
    // Use BLoC-provided sorted list: below-threshold first (Req 13.3)
    final sorted = InventoryLoaded(ingredients).sorted;

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 48, color: AppTheme.mutedText),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'No ingredients found.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing16,
        // Extra bottom padding so FABs don't overlap last item
        AppTheme.spacing16 + 120,
      ),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing8),
      itemBuilder: (context, index) =>
          _IngredientTile(ingredient: sorted[index]),
    );
  }
}

// ── Ingredient tile ───────────────────────────────────────────────────────────

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    final isBelowThreshold = ingredient.isBelowThreshold;

    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: BorderSide(
          color: isBelowThreshold ? AppTheme.warning : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            // Low-stock warning icon (Req 13.3)
            if (isBelowThreshold) ...[
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warning,
                size: 20,
                semanticLabel: 'Low stock warning',
              ),
              const SizedBox(width: AppTheme.spacing8),
            ],
            // Ingredient name and unit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isBelowThreshold
                              ? AppTheme.onSurface
                              : AppTheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ingredient.unit,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
            // Current stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ingredient.currentStock % 1 == 0
                      ? ingredient.currentStock.toStringAsFixed(0)
                      : ingredient.currentStock.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isBelowThreshold
                            ? AppTheme.warning
                            : AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (isBelowThreshold)
                  Text(
                    'Reorder: ${ingredient.reorderThreshold % 1 == 0 ? ingredient.reorderThreshold.toStringAsFixed(0) : ingredient.reorderThreshold.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.warning,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stock Adjustment bottom sheet (Req 13.4, 13.5, 13.6) ──────────────────────

class _StockAdjustmentSheet extends StatefulWidget {
  const _StockAdjustmentSheet({
    required this.ingredients,
    required this.parentContext,
  });

  final List<Ingredient> ingredients;
  final BuildContext parentContext;

  @override
  State<_StockAdjustmentSheet> createState() => _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends State<_StockAdjustmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  Ingredient? _selectedIngredient;
  String? _serverError;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedIngredient == null) return;

    final quantity = double.tryParse(_quantityController.text.trim())!;

    context.read<InventoryBloc>().add(
          StockAdjustmentRequested(
            id: _selectedIngredient!.id,
            quantity: quantity,
            reason: _reasonController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        // On success: close sheet and show snackbar (Req 13.4)
        if (state is InventoryLoaded) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(
              content: Text('Stock adjusted successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
        // On error: show inline error, keep form open (Req 13.6)
        if (state is InventoryOperationError) {
          setState(() => _serverError = state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is InventoryLoading;

        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacing24,
            right: AppTheme.spacing24,
            top: AppTheme.spacing24,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adjust Stock',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Ingredient dropdown
                DropdownButtonFormField<Ingredient>(
                  initialValue: _selectedIngredient,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient',
                    hintText: 'Select an ingredient',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: widget.ingredients
                      .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text(i.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedIngredient = v),
                  validator: (v) =>
                      v == null ? 'Please select an ingredient' : null,
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Quantity field — numeric, non-zero (Req 13.5)
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g. 10 or -5',
                    prefixIcon: Icon(Icons.numbers_outlined),
                    helperText: 'Use negative value to decrease stock',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Quantity is required';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Enter a valid numeric quantity';
                    }
                    if (parsed == 0) {
                      return 'Quantity must be non-zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Reason field
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'e.g. Received delivery, Wastage',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Reason is required';
                    }
                    return null;
                  },
                ),

                // Inline server error (Req 13.6)
                if (_serverError != null) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    _serverError!,
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spacing24),

                // Submit button
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onPrimary,
                          ),
                        )
                      : const Text('Submit Adjustment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Recipe Link bottom sheet (Req 13.7, 13.8) ─────────────────────────────────

class _RecipeLinkSheet extends StatefulWidget {
  const _RecipeLinkSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_RecipeLinkSheet> createState() => _RecipeLinkSheetState();
}

class _RecipeLinkSheetState extends State<_RecipeLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ingredientIdController = TextEditingController();
  final _menuItemIdController = TextEditingController();
  final _qtyPerServingController = TextEditingController();

  String? _serverError;

  @override
  void dispose() {
    _ingredientIdController.dispose();
    _menuItemIdController.dispose();
    _qtyPerServingController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final qty = double.tryParse(_qtyPerServingController.text.trim())!;

    context.read<InventoryBloc>().add(
          RecipeLinkRequested(
            ingredientId: _ingredientIdController.text.trim(),
            menuItemId: _menuItemIdController.text.trim(),
            qtyPerServing: qty,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        // On success: close sheet, parent shows snackbar (Req 13.7)
        if (state is RecipeLinkSuccess) {
          Navigator.of(context).pop();
        }
        // On error: show inline error, keep form open (Req 13.8)
        if (state is InventoryOperationError) {
          setState(() => _serverError = state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is InventoryLoading;

        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacing24,
            right: AppTheme.spacing24,
            top: AppTheme.spacing24,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Link Recipe',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Ingredient ID
                TextFormField(
                  controller: _ingredientIdController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient ID',
                    hintText: 'Enter ingredient ID',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingredient ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Menu item ID
                TextFormField(
                  controller: _menuItemIdController,
                  decoration: const InputDecoration(
                    labelText: 'Menu Item ID',
                    hintText: 'Enter menu item ID',
                    prefixIcon: Icon(Icons.restaurant_menu_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Menu Item ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Quantity per serving — numeric
                TextFormField(
                  controller: _qtyPerServingController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantity per Serving',
                    hintText: 'e.g. 0.25',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Quantity per serving is required';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Enter a valid numeric quantity';
                    }
                    if (parsed <= 0) {
                      return 'Quantity must be greater than zero';
                    }
                    return null;
                  },
                ),

                // Inline server error (Req 13.8)
                if (_serverError != null) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    _serverError!,
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spacing24),

                // Submit button
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onPrimary,
                          ),
                        )
                      : const Text('Create Link'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
