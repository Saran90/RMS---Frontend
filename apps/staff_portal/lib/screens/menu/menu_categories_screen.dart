// Feature: rms-flutter-frontend
// Implements: Requirements 6.1–6.10

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_portal/menu/menu_category.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';
import 'package:staff_portal/menu/menu_design.dart';

/// Menu Categories screen — standalone entry point.
class MenuCategoriesScreen extends StatelessWidget {
  const MenuCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuCategoryBloc, MenuCategoryState>(
      listener: _handleCategoryError,
      child: BlocBuilder<MenuCategoryBloc, MenuCategoryState>(
        builder: (context, state) => Scaffold(
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
                            'Categories',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: menuTitle,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Organise your menu into sections',
                            style: TextStyle(fontSize: 12.5, color: menuMuted),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showCategorySheet(context, category: null),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add category'),
                      style: FilledButton.styleFrom(
                        backgroundColor: menuAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _categoryBody(context, state)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body-only — embed inside a tab view or other Scaffold parent.
class MenuCategoriesBodyContent extends StatelessWidget {
  const MenuCategoriesBodyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuCategoryBloc, MenuCategoryState>(
      listener: _handleCategoryError,
      child: BlocBuilder<MenuCategoryBloc, MenuCategoryState>(
        builder: (context, state) => _categoryBody(context, state),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

void _handleCategoryError(BuildContext context, MenuCategoryState state) {
  if (state is MenuCategoryOperationError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(state.message),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

Widget _categoryBody(BuildContext context, MenuCategoryState state) {
  return switch (state) {
    MenuCategoryInitial() || MenuCategoryLoading() => _LoadingBody(),
    MenuCategoryLoaded(:final categories, :final deletingIds) =>
      _LoadedBody(categories: categories, deletingIds: deletingIds),
    MenuCategoryOperationError(:final categories, :final deletingIds) =>
      _LoadedBody(categories: categories, deletingIds: deletingIds),
    MenuCategoryError(:final message) => ErrorStateWidget(
        message: message,
        onRetry: () => context
            .read<MenuCategoryBloc>()
            .add(const MenuCategoriesLoadRequested()),
      ),
  };
}

void _showCategorySheet(BuildContext context,
    {required MenuCategory? category}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<MenuCategoryBloc>(),
      child: _CategorySheet(category: category),
    ),
  );
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.4,
        ),
        itemCount: 9,
        itemBuilder: (_, __) =>
            const LoadingSkeletonCard(height: double.infinity),
      ),
    );
  }
}

// ── Loaded grid ───────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.categories, required this.deletingIds});

  final List<MenuCategory> categories;
  final Set<String> deletingIds;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const MenuEmptyState(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        subtitle: 'Add a category to organise your menu items',
      );
    }

    final seen = <String>{};
    final unique =
        categories.where((c) => seen.add(c.name.toLowerCase())).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : 3;
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.4,
        ),
        itemCount: unique.length,
        itemBuilder: (ctx, i) => _CategoryCard(
          category: unique[i],
          isDeleting: deletingIds.contains(unique[i].id),
        ),
      );
    });
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.isDeleting});

  final MenuCategory category;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return MenuCategoryTile(
      name: category.name,
      displayOrder: category.displayOrder,
      description: category.description,
      isDeleting: isDeleting,
      onEdit: () => _showEdit(context),
      onDelete: () => _confirmDelete(context),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MenuCategoryBloc>(),
        child: _CategorySheet(category: category),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showConfirmationDialog(
      context,
      title: 'Delete category',
      message: 'Delete "${category.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        context
            .read<MenuCategoryBloc>()
            .add(MenuCategoryDeleteRequested(category.id));
      }
    });
  }
}

// ── Add / Edit sheet ──────────────────────────────────────────────────────────

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({required this.category});
  final MenuCategory? category;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.category?.description ?? '');
  }

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
    if (_isEdit) {
      bloc.add(MenuCategoryUpdateRequested(
        id: widget.category!.id,
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ));
    } else {
      bloc.add(MenuCategoryCreateRequested(
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ));
    }

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
      title: _isEdit ? 'Edit category' : 'Add category',
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
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 24),
            MenuPrimaryButton(
              label: _isEdit ? 'Save changes' : 'Add category',
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
