// Feature: rms-flutter-frontend
// Implements: Requirements 6.1–6.10

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_portal/menu/menu_category.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';

/// Menu Categories screen — standalone entry point.
class MenuCategoriesScreen extends StatelessWidget {
  const MenuCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuCategoryBloc, MenuCategoryState>(
      listener: _handleCategoryError,
      child: BlocBuilder<MenuCategoryBloc, MenuCategoryState>(
        builder: (context, state) => Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(title: const Text('Menu Categories')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCategorySheet(context, category: null),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
          body: _categoryBody(context, state),
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
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
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
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppTheme.spacing8,
          mainAxisSpacing: AppTheme.spacing8,
          childAspectRatio: 1.8,
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category_outlined,
                size: 64, color: AppTheme.mutedText),
            const SizedBox(height: AppTheme.spacing12),
            Text('No categories yet',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.mutedText)),
            const SizedBox(height: AppTheme.spacing8),
            Text('Add a category to organise your menu',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.mutedText)),
          ],
        ),
      );
    }

    // Deduplicate by name (bulk-upload creates duplicates)
    final seen = <String>{};
    final unique =
        categories.where((c) => seen.add(c.name.toLowerCase())).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 720 ? 4 : 3;
      return GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: AppTheme.spacing8,
          mainAxisSpacing: AppTheme.spacing8,
          childAspectRatio: 1.8,
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
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: order badge + action icons
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                  ),
                  child: Text(
                    '#${category.displayOrder}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    color: AppTheme.primary,
                    tooltip: 'Edit',
                    onPressed: isDeleting ? null : () => _showEdit(context),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: isDeleting
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline, size: 14),
                    color: isDeleting ? AppTheme.mutedText : AppTheme.error,
                    tooltip: 'Delete',
                    onPressed:
                        isDeleting ? null : () => _confirmDelete(context),
                  ),
                ),
              ],
            ),
            // Name + description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description != null &&
                    category.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category.description!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<MenuCategoryBloc>(),
        child: _CategorySheet(category: category),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showConfirmationDialog(
      context,
      title: 'Delete Category',
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
    _descCtrl = TextEditingController(text: widget.category?.description ?? '');
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(_isEdit ? 'Edit Category' : 'Add Category',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacing16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error),
                  ),
                  child: Text(_errorMessage!,
                      style:
                          const TextStyle(color: AppTheme.error, fontSize: 13)),
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
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
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
                              strokeWidth: 2, color: AppTheme.onPrimary),
                        )
                      : Text(_isEdit ? 'Save Changes' : 'Add Category'),
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
