// Feature: rms-flutter-frontend
// Implements: Requirements 6.1–6.10, 7.1, 7.6, 7.7, 7.11

import 'package:api_client/api_client.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_portal/menu/menu_bulk_upload_sheet.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';
import 'package:staff_portal/menu/menu_item_bloc.dart';
import 'package:staff_portal/menu/menu_item_form.dart';
import 'package:staff_portal/menu/menu_repository.dart';
import 'package:staff_portal/screens/menu/menu_categories_screen.dart';
import 'package:staff_portal/screens/menu/menu_items_screen.dart';

/// Entry-point for the `/menu` route.
///
/// Creates [MenuRepository], [MenuCategoryBloc], and [MenuItemBloc] using the
/// ambient [ApiClient], dispatches initial load events, and renders a
/// two-tab [Scaffold] for Categories and Items.
///
/// The body tabs use body-only variants of each screen to avoid nested
/// Scaffolds: [MenuCategoriesBodyContent] and [MenuItemsBodyContent].
///
/// Requirements: 6.1–6.10, 7.1, 7.6, 7.7, 7.11
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final menuRepository = MenuRepository(apiClient: apiClient);

    return RepositoryProvider<MenuRepository>.value(
      value: menuRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MenuCategoryBloc>(
            create: (_) => MenuCategoryBloc(repository: menuRepository)
              ..add(const MenuCategoriesLoadRequested()),
          ),
          BlocProvider<MenuItemBloc>(
            create: (_) => MenuItemBloc(repository: menuRepository)
              ..add(const MenuItemsLoadRequested()),
          ),
        ],
        child: const _MenuTabScaffold(),
      ),
    );
  }
}

// ── Tab scaffold ──────────────────────────────────────────────────────────────

class _MenuTabScaffold extends StatelessWidget {
  const _MenuTabScaffold();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Menu'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.category_outlined),
                iconMargin: EdgeInsets.only(bottom: 2),
                text: 'Categories',
              ),
              Tab(
                icon: Icon(Icons.restaurant_menu_outlined),
                iconMargin: EdgeInsets.only(bottom: 2),
                text: 'Items',
              ),
            ],
          ),
          actions: [
            _BulkUploadButton(),
            _TabAwareRefreshButton(),
          ],
        ),
        body: const TabBarView(
          children: [
            _CategoriesTab(),
            MenuItemsBodyContent(),
          ],
        ),
        floatingActionButton: _AddCategoryFab(),
      ),
    );
  }
}

// ── Categories tab (with FAB proxy) ──────────────────────────────────────────

/// Wraps [MenuCategoriesBodyContent] and exposes the add-category action
/// through the parent Scaffold's FAB (see [_AddCategoryFab]).
class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    return const MenuCategoriesBodyContent();
  }
}

/// FAB visible only when the Categories tab (index 0) is selected.
///
/// Triggers the same add-category bottom sheet as [MenuCategoriesScreen].
class _AddCategoryFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final tabController = DefaultTabController.of(ctx);
        return ListenableBuilder(
          listenable: tabController,
          builder: (_, __) {
            if (tabController.index == 0) {
              return FloatingActionButton.extended(
                heroTag: 'add_category_fab',
                onPressed: () => _showAddCategorySheet(ctx),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              );
            }
            // Items tab (index 1) — open Add Item form
            return FloatingActionButton.extended(
              heroTag: 'add_item_fab',
              onPressed: () => showMenuItemForm(ctx),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            );
          },
        );
      },
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<MenuCategoryBloc>(),
        child: _AddCategorySheetContent(),
      ),
    );
  }
}

/// Minimal category form for the FAB sheet in [MenuScreen].
///
/// Reuses the same form logic that [MenuCategoriesScreen] exposes
/// via [showCategoryAddSheet].
class _AddCategorySheetContent extends StatefulWidget {
  @override
  State<_AddCategorySheetContent> createState() =>
      _AddCategorySheetContentState();
}

class _AddCategorySheetContentState extends State<_AddCategorySheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final bloc = context.read<MenuCategoryBloc>();
    bloc.add(MenuCategoryCreateRequested(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    ));

    bloc.stream.first.then((state) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (state is MenuCategoryLoaded) {
        Navigator.of(context).pop();
      } else if (state is MenuCategoryOperationError) {
        setState(() => _errorMessage = state.message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Add Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: '1–100 characters',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  if (v.trim().length > 100) {
                    return 'Name must be 100 characters or fewer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onPrimary,
                          ),
                        )
                      : const Text('Add Category'),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Per-tab refresh button ────────────────────────────────────────────────────

/// Refresh button whose action depends on the currently selected tab.
class _TabAwareRefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final tabController = DefaultTabController.of(ctx);
        return ListenableBuilder(
          listenable: tabController,
          builder: (_, __) => IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (tabController.index == 0) {
                ctx.read<MenuCategoryBloc>().add(
                      const MenuCategoriesLoadRequested(),
                    );
              } else {
                ctx.read<MenuItemBloc>().add(
                      const MenuItemsLoadRequested(),
                    );
              }
            },
          ),
        );
      },
    );
  }
}

// ── Bulk upload button ────────────────────────────────────────────────────────

/// AppBar action that opens the [showMenuBulkUploadSheet] bottom sheet.
///
/// Uses a [Builder] to guarantee the sheet's [context.read] calls resolve
/// the BLoCs and repository provided by [MenuScreen].
class _BulkUploadButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => Semantics(
        label: 'Bulk upload menu',
        child: IconButton(
          icon: const Icon(Icons.upload_file_outlined),
          tooltip: 'Bulk Upload',
          onPressed: () => showMenuBulkUploadSheet(ctx),
        ),
      ),
    );
  }
}
