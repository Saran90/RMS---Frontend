// Feature: rms-flutter-frontend
// Implements: Requirements 6.1–6.10, 7.1, 7.6, 7.7, 7.11

import 'package:api_client/api_client.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/menu/menu_bulk_upload_sheet.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';
import 'package:staff_portal/menu/menu_design.dart';
import 'package:staff_portal/menu/menu_item_bloc.dart';
import 'package:staff_portal/menu/menu_item_form.dart';
import 'package:staff_portal/menu/menu_repository.dart';
import 'package:staff_portal/screens/menu/menu_categories_screen.dart';
import 'package:staff_portal/screens/menu/menu_items_screen.dart';

/// Entry-point for the `/menu` route.
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
        backgroundColor: menuBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MenuPageHeader(),
            Expanded(
              child: TabBarView(
                children: [
                  const MenuCategoriesBodyContent(),
                  const MenuItemsBodyContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _MenuPageHeader extends StatelessWidget {
  const _MenuPageHeader();

  int _categoryCount(MenuCategoryState state) {
    return switch (state) {
      MenuCategoryLoaded(:final categories) => categories.length,
      MenuCategoryOperationError(:final categories) => categories.length,
      _ => 0,
    };
  }

  List<MenuItem> _items(MenuItemState state) {
    return switch (state) {
      MenuItemLoaded(:final items) => items,
      MenuItemOperationError(:final items) => items,
      MenuBulkUploadInProgress(:final items) => items,
      MenuBulkUploadSuccess(:final items) => items,
      _ => [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);

    return BlocBuilder<MenuCategoryBloc, MenuCategoryState>(
      builder: (context, catState) {
        return BlocBuilder<MenuItemBloc, MenuItemState>(
          builder: (context, itemState) {
            final items = _items(itemState);
            final available =
                items.where((i) => i.isAvailable).length;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Menu',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: menuTitle,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage categories, items, and availability',
                              style:
                                  TextStyle(fontSize: 12.5, color: menuMuted),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ListenableBuilder(
                            listenable: tabController,
                            builder: (_, __) {
                              final tabIndex = tabController.index;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        showMenuBulkUploadSheet(context),
                                    icon: const Icon(Icons.upload_file_outlined,
                                        size: 16),
                                    label: const Text('Bulk upload'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: menuTitle,
                                      side: const BorderSide(color: menuBorder),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      if (tabIndex == 0) {
                                        context
                                            .read<MenuCategoryBloc>()
                                            .add(
                                                const MenuCategoriesLoadRequested());
                                      } else {
                                        context
                                            .read<MenuItemBloc>()
                                            .add(const MenuItemsLoadRequested());
                                      }
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: menuTitle,
                                      side: const BorderSide(color: menuBorder),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: () {
                                      if (tabIndex == 0) {
                                        _showAddCategorySheet(context);
                                      } else {
                                        showMenuItemForm(context);
                                      }
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(
                                      tabIndex == 0
                                          ? 'Add category'
                                          : 'Add item',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: menuAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: MenuStatCard(
                          label: 'Categories',
                          value: '${_categoryCount(catState)}',
                          icon: Icons.category_outlined,
                          accent: menuAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MenuStatCard(
                          label: 'Menu items',
                          value: '${items.length}',
                          icon: Icons.restaurant_menu_outlined,
                          accent: menuTitle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MenuStatCard(
                          label: 'Available',
                          value: '$available',
                          icon: Icons.check_circle_outline,
                          accent: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: tabController,
                    builder: (_, __) => Row(
                      children: [
                        MenuChoiceChip(
                          label: 'Categories',
                          icon: Icons.category_outlined,
                          selected: tabController.index == 0,
                          onTap: () => tabController.animateTo(0),
                        ),
                        const SizedBox(width: 8),
                        MenuChoiceChip(
                          label: 'Items',
                          icon: Icons.restaurant_menu_outlined,
                          selected: tabController.index == 1,
                          onTap: () => tabController.animateTo(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MenuCategoryBloc>(),
        child: const _AddCategorySheetContent(),
      ),
    );
  }
}

// ── Add category sheet ────────────────────────────────────────────────────────

class _AddCategorySheetContent extends StatefulWidget {
  const _AddCategorySheetContent();

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
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
    return MenuSheetScaffold(
      title: 'Add category',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              MenuFormError(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category name *',
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 24),
            MenuPrimaryButton(
              label: 'Add category',
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
