// Feature: rms-flutter-frontend
// Implements: Requirements 7.2, 7.3, 7.4, 7.5, 7.8, 7.9, 7.10

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/menu/menu_category.dart';
import 'package:staff_portal/menu/menu_category_bloc.dart';
import 'package:staff_portal/menu/menu_item_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local edit models (mutable, form-only)
// ─────────────────────────────────────────────────────────────────────────────

/// Mutable variant entry used by the form editor.
class _VariantEntry {
  _VariantEntry({String? id, String sizeLabel = '', String priceDelta = '0'})
      : id = id,
        sizeLabelCtrl = TextEditingController(text: sizeLabel),
        priceDeltaCtrl = TextEditingController(text: priceDelta),
        sizeLabelKey = GlobalKey<FormFieldState<String>>(),
        priceDeltaKey = GlobalKey<FormFieldState<String>>(),
        sizeLabelFocus = FocusNode(),
        priceDeltaFocus = FocusNode();

  final String? id;
  final TextEditingController sizeLabelCtrl;
  final TextEditingController priceDeltaCtrl;
  final GlobalKey<FormFieldState<String>> sizeLabelKey;
  final GlobalKey<FormFieldState<String>> priceDeltaKey;
  final FocusNode sizeLabelFocus;
  final FocusNode priceDeltaFocus;

  void dispose() {
    sizeLabelCtrl.dispose();
    priceDeltaCtrl.dispose();
    sizeLabelFocus.dispose();
    priceDeltaFocus.dispose();
  }
}

/// Mutable modifier option entry used within a group editor.
class _ModifierOptionEntry {
  _ModifierOptionEntry({
    String? id,
    String modifierName = '',
    String priceDelta = '0',
  })  : id = id,
        modifierNameCtrl = TextEditingController(text: modifierName),
        priceDeltaCtrl = TextEditingController(text: priceDelta),
        modifierNameKey = GlobalKey<FormFieldState<String>>(),
        priceDeltaKey = GlobalKey<FormFieldState<String>>(),
        modifierNameFocus = FocusNode(),
        priceDeltaFocus = FocusNode();

  final String? id;
  final TextEditingController modifierNameCtrl;
  final TextEditingController priceDeltaCtrl;
  final GlobalKey<FormFieldState<String>> modifierNameKey;
  final GlobalKey<FormFieldState<String>> priceDeltaKey;
  final FocusNode modifierNameFocus;
  final FocusNode priceDeltaFocus;

  void dispose() {
    modifierNameCtrl.dispose();
    priceDeltaCtrl.dispose();
    modifierNameFocus.dispose();
    priceDeltaFocus.dispose();
  }
}

/// Mutable modifier group entry used by the form editor.
class _ModifierGroupEntry {
  _ModifierGroupEntry({
    String? id,
    String groupName = '',
    int minSelect = 0,
    int maxSelect = 1,
    List<_ModifierOptionEntry>? options,
  })  : id = id,
        groupNameCtrl = TextEditingController(text: groupName),
        groupNameKey = GlobalKey<FormFieldState<String>>(),
        groupNameFocus = FocusNode(),
        minSelect = minSelect,
        maxSelect = maxSelect,
        options = options ?? [_ModifierOptionEntry()];

  final String? id;
  final TextEditingController groupNameCtrl;
  final GlobalKey<FormFieldState<String>> groupNameKey;
  final FocusNode groupNameFocus;
  int minSelect;
  int maxSelect;
  final List<_ModifierOptionEntry> options;

  void dispose() {
    groupNameCtrl.dispose();
    groupNameFocus.dispose();
    for (final opt in options) {
      opt.dispose();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point: showMenuItemForm
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the Add / Edit Item bottom sheet.
///
/// Pass [item] to open in edit mode; pass `null` for add mode.
///
/// The sheet expects [MenuItemBloc] and [MenuCategoryBloc] to be available
/// in [context]. The caller is responsible for providing those BLoCs.
///
/// Requirements: 7.2, 7.3, 7.4, 7.5, 7.8, 7.9, 7.10
void showMenuItemForm(
  BuildContext context, {
  MenuItem? item,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<MenuItemBloc>()),
        BlocProvider.value(value: context.read<MenuCategoryBloc>()),
      ],
      child: _MenuItemFormSheet(item: item),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// StatefulWidget: _MenuItemFormSheet
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItemFormSheet extends StatefulWidget {
  const _MenuItemFormSheet({this.item});
  final MenuItem? item;

  @override
  State<_MenuItemFormSheet> createState() => _MenuItemFormSheetState();
}

class _MenuItemFormSheetState extends State<_MenuItemFormSheet> {
  // ── Form key
  final _formKey = GlobalKey<FormState>();

  // ── Core field controllers & keys
  late final TextEditingController _nameCtrl;
  late final TextEditingController _basePriceCtrl;
  late final TextEditingController _gstRateCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageUrlCtrl;

  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _basePriceKey = GlobalKey<FormFieldState<String>>();
  final _categoryKey = GlobalKey<FormFieldState<String>>();
  final _dietaryKey = GlobalKey<FormFieldState<DietaryType>>();

  final _nameFocus = FocusNode();
  final _basePriceFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _dietaryFocus = FocusNode();
  final _gstRateFocus = FocusNode();
  final _descFocus = FocusNode();
  final _imageUrlFocus = FocusNode();

  // ── Dropdown selections
  String? _selectedCategoryId;
  DietaryType? _selectedDietaryType;
  bool _isAvailable = true;

  // ── Variant & modifier lists
  final List<_VariantEntry> _variants = [];
  final List<_ModifierGroupEntry> _modifierGroups = [];

  // ── UI state
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _basePriceCtrl = TextEditingController(
        text: item != null ? item.basePrice.toStringAsFixed(2) : '');
    _gstRateCtrl = TextEditingController(
        text: item != null ? item.gstRate.toStringAsFixed(2) : '0.00');
    _descCtrl = TextEditingController(text: '');
    _imageUrlCtrl = TextEditingController(text: item?.imageUrl ?? '');
    _selectedCategoryId = item?.categoryId;
    _selectedDietaryType = item?.dietaryType;
    _isAvailable = item?.isAvailable ?? true;

    if (item != null) {
      for (final v in item.variants) {
        _variants.add(_VariantEntry(
          id: v.id,
          sizeLabel: v.sizeLabel,
          priceDelta: v.priceDelta.toStringAsFixed(2),
        ));
      }
      for (final g in item.modifierGroups) {
        _modifierGroups.add(_ModifierGroupEntry(
          id: g.id,
          groupName: g.groupName,
          minSelect: g.minSelect,
          maxSelect: g.maxSelect,
          options: g.options
              .map((o) => _ModifierOptionEntry(
                    id: o.id,
                    modifierName: o.modifierName,
                    priceDelta: o.priceDelta.toStringAsFixed(2),
                  ))
              .toList(),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _basePriceCtrl.dispose();
    _gstRateCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _nameFocus.dispose();
    _basePriceFocus.dispose();
    _categoryFocus.dispose();
    _dietaryFocus.dispose();
    _gstRateFocus.dispose();
    _descFocus.dispose();
    _imageUrlFocus.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    for (final g in _modifierGroups) {
      g.dispose();
    }
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  void _submit() {
    setState(() => _errorMessage = null);

    // Build the ordered field list for FormValidator.submitAndFocus()
    // Required fields: name, category, base_price, dietary_type
    final fields = <FormFieldEntry?>[
      FormFieldEntry(fieldKey: _nameKey, focusNode: _nameFocus),
      FormFieldEntry(fieldKey: _categoryKey, focusNode: _categoryFocus),
      FormFieldEntry(fieldKey: _basePriceKey, focusNode: _basePriceFocus),
      FormFieldEntry(fieldKey: _dietaryKey, focusNode: _dietaryFocus),
    ];

    // Validate core fields first (Req 7.4 — focus moves to first error)
    final coreValid = FormValidator.submitAndFocus(_formKey, fields);
    if (!coreValid) return;

    // Validate all variant sub-fields
    for (int i = 0; i < _variants.length; i++) {
      final v = _variants[i];
      bool variantOk = true;
      if (v.sizeLabelKey.currentState?.validate() == false) variantOk = false;
      if (v.priceDeltaKey.currentState?.validate() == false) variantOk = false;
      if (!variantOk) {
        v.sizeLabelFocus.requestFocus();
        return;
      }
    }

    // Validate all modifier group sub-fields
    for (int gi = 0; gi < _modifierGroups.length; gi++) {
      final g = _modifierGroups[gi];
      bool groupOk = true;
      if (g.groupNameKey.currentState?.validate() == false) groupOk = false;

      // Req 7.10 — block save when max_select < min_select
      if (g.maxSelect < g.minSelect) {
        setState(() {
          _errorMessage =
              'Modifier group "${g.groupNameCtrl.text}" has max selections '
              '(${g.maxSelect}) less than min selections (${g.minSelect}).';
        });
        g.groupNameFocus.requestFocus();
        return;
      }

      for (int oi = 0; oi < g.options.length; oi++) {
        final o = g.options[oi];
        if (o.modifierNameKey.currentState?.validate() == false) {
          groupOk = false;
        }
        if (o.priceDeltaKey.currentState?.validate() == false) {
          groupOk = false;
        }
      }

      if (!groupOk) {
        g.groupNameFocus.requestFocus();
        return;
      }
    }

    // Build payload
    final payload = _buildPayload();
    setState(() => _submitting = true);

    final bloc = context.read<MenuItemBloc>();
    if (_isEdit) {
      bloc.add(MenuItemUpdateRequested(id: widget.item!.id, payload: payload));
    } else {
      bloc.add(MenuItemCreateRequested(payload: payload));
    }

    // Listen for result
    bloc.stream.first.then((state) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (state is MenuItemLoaded) {
        Navigator.of(context).pop();
      } else if (state is MenuItemOperationError) {
        // Retain form data on error (Req 7.5)
        setState(() => _errorMessage = state.message);
      }
    });
  }

  Map<String, dynamic> _buildPayload() {
    final variantList = _variants.map((v) {
      return {
        if (v.id != null) 'id': v.id,
        'size_label': v.sizeLabelCtrl.text.trim(),
        'price_delta': double.parse(v.priceDeltaCtrl.text.trim()),
      };
    }).toList();

    final groupList = _modifierGroups.map((g) {
      return {
        if (g.id != null) 'id': g.id,
        'group_name': g.groupNameCtrl.text.trim(),
        'min_select': g.minSelect,
        'max_select': g.maxSelect,
        'options': g.options.map((o) {
          return {
            if (o.id != null) 'id': o.id,
            'modifier_name': o.modifierNameCtrl.text.trim(),
            'price_delta': double.parse(o.priceDeltaCtrl.text.trim()),
          };
        }).toList(),
      };
    }).toList();

    return {
      'name': _nameCtrl.text.trim(),
      'category_id': _selectedCategoryId,
      'base_price': double.parse(_basePriceCtrl.text.trim()),
      'gst_rate': double.parse(_gstRateCtrl.text.trim()),
      'dietary_type': _selectedDietaryType!.jsonValue,
      'is_available': _isAvailable,
      if (_descCtrl.text.trim().isNotEmpty)
        'description': _descCtrl.text.trim(),
      if (_imageUrlCtrl.text.trim().isNotEmpty)
        'image_url': _imageUrlCtrl.text.trim(),
      'variants': variantList,
      'modifier_groups': groupList,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Handle bar
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
                  _isEdit ? 'Edit Item' : 'Add Item',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Required fields are marked *',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedText),
                ),
                const SizedBox(height: AppTheme.spacing16),

                // ── API error banner (retained on error, Req 7.5)
                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: AppTheme.spacing12),
                ],

                // ── Core fields
                _buildCoreFields(),
                const SizedBox(height: AppTheme.spacing24),

                // ── Variants section
                _SectionHeader(
                  title: 'Variants',
                  subtitle: '1–20 size variants (optional)',
                  onAdd: _variants.length < 20
                      ? () => setState(() => _variants.add(_VariantEntry()))
                      : null,
                ),
                const SizedBox(height: AppTheme.spacing8),
                ..._buildVariantEditors(),
                if (_variants.isEmpty)
                  _EmptySection(
                    label: 'No variants added',
                    hint: 'Tap + to add a size variant',
                  ),
                const SizedBox(height: AppTheme.spacing24),

                // ── Modifier groups section
                _SectionHeader(
                  title: 'Modifier Groups',
                  subtitle: 'Add-ons and customisation options',
                  onAdd: () => setState(
                    () => _modifierGroups.add(_ModifierGroupEntry()),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                ..._buildModifierGroupEditors(),
                if (_modifierGroups.isEmpty)
                  _EmptySection(
                    label: 'No modifier groups added',
                    hint: 'Tap + to add a modifier group',
                  ),
                const SizedBox(height: AppTheme.spacing32),

                // ── Submit button
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
                        : Text(_isEdit ? 'Save Changes' : 'Add Item'),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core fields builder
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCoreFields() {
    final categoryState = context.watch<MenuCategoryBloc>().state;
    final categories = switch (categoryState) {
      MenuCategoryLoaded(:final categories) => categories,
      MenuCategoryOperationError(:final categories) => categories,
      _ => <MenuCategory>[],
    };

    // Deduplicate by name (same bulk-upload issue as the categories screen)
    final seen = <String>{};
    final uniqueCategories =
        categories.where((c) => seen.add(c.name.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name *
        TextFormField(
          key: _nameKey,
          controller: _nameCtrl,
          focusNode: _nameFocus,
          decoration: const InputDecoration(
            labelText: 'Item Name *',
            hintText: '1–100 characters',
          ),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Item name is required';
            if (v.trim().length > 100)
              return 'Name must be 100 characters or fewer';
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Category *
        DropdownButtonFormField<String>(
          key: _categoryKey,
          focusNode: _categoryFocus,
          initialValue: _selectedCategoryId,
          decoration: const InputDecoration(labelText: 'Category *'),
          hint: const Text('Select category'),
          items: uniqueCategories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategoryId = val),
          validator: (v) =>
              v == null || v.isEmpty ? 'Category is required' : null,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Base Price *
        TextFormField(
          key: _basePriceKey,
          controller: _basePriceCtrl,
          focusNode: _basePriceFocus,
          decoration: const InputDecoration(
            labelText: 'Base Price (₹) *',
            hintText: '0.00',
            prefixText: '₹ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Base price is required';
            final d = double.tryParse(v.trim());
            if (d == null || d < 0) return 'Enter a valid price';
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Dietary Type *
        DropdownButtonFormField<DietaryType>(
          key: _dietaryKey,
          focusNode: _dietaryFocus,
          initialValue: _selectedDietaryType,
          decoration: const InputDecoration(labelText: 'Dietary Type *'),
          hint: const Text('Select type'),
          items: DietaryType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  DietaryBadge(type: t),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(_dietaryLabel(t)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedDietaryType = val),
          validator: (v) => v == null ? 'Dietary type is required' : null,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // GST Rate
        TextFormField(
          controller: _gstRateCtrl,
          focusNode: _gstRateFocus,
          decoration: const InputDecoration(
            labelText: 'GST Rate (%)',
            hintText: '0.00',
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final d = double.tryParse(v.trim());
            if (d == null || d < 0 || d > 100)
              return 'Enter a valid rate (0–100)';
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Description
        TextFormField(
          controller: _descCtrl,
          focusNode: _descFocus,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
          ),
          maxLines: 2,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Image URL (CDN)
        TextFormField(
          controller: _imageUrlCtrl,
          focusNode: _imageUrlFocus,
          decoration: const InputDecoration(
            labelText: 'Image URL (optional)',
            hintText: 'https://cdn.example.com/image.jpg',
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Availability
        SwitchListTile(
          value: _isAvailable,
          onChanged: (val) => setState(() => _isAvailable = val),
          title: const Text('Available for ordering'),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppTheme.onPrimary,
          activeTrackColor: AppTheme.primary,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Variant editor builders
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _buildVariantEditors() {
    return _variants.asMap().entries.map((entry) {
      final i = entry.key;
      final v = entry.value;
      return Padding(
        key: ValueKey('variant_$i'),
        padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
        child: _VariantCard(
          entry: v,
          index: i,
          onRemove: () => setState(() {
            v.dispose();
            _variants.removeAt(i);
          }),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Modifier group editor builders
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _buildModifierGroupEditors() {
    return _modifierGroups.asMap().entries.map((entry) {
      final gi = entry.key;
      final g = entry.value;
      return Padding(
        key: ValueKey('modifier_group_$gi'),
        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
        child: _ModifierGroupCard(
          entry: g,
          index: gi,
          onRemove: () => setState(() {
            g.dispose();
            _modifierGroups.removeAt(gi);
          }),
          onChanged: () => setState(() {}),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static String _dietaryLabel(DietaryType t) {
    switch (t) {
      case DietaryType.veg:
        return 'Vegetarian';
      case DietaryType.nonVeg:
        return 'Non-Vegetarian';
      case DietaryType.vegan:
        return 'Vegan';
      case DietaryType.egg:
        return 'Egg';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VariantCard widget (req 7.8: 1–20 variants, sizeLabel 1–50, priceDelta range)
// ─────────────────────────────────────────────────────────────────────────────

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.entry,
    required this.index,
    required this.onRemove,
  });

  final _VariantEntry entry;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Variant ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Semantics(
                  label: 'Remove variant ${index + 1}',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: AppTheme.error,
                      tooltip: 'Remove variant',
                      onPressed: onRemove,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Size Label (1–50 chars) — Req 7.8
            TextFormField(
              key: entry.sizeLabelKey,
              controller: entry.sizeLabelCtrl,
              focusNode: entry.sizeLabelFocus,
              decoration: const InputDecoration(
                labelText: 'Size Label *',
                hintText: 'e.g. Small, Large (1–50 chars)',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Size label is required';
                }
                if (v.trim().length > 50) {
                  return 'Size label must be 50 characters or fewer';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Price Delta (-999.99–9999.99) — Req 7.8
            TextFormField(
              key: entry.priceDeltaKey,
              controller: entry.priceDeltaCtrl,
              focusNode: entry.priceDeltaFocus,
              decoration: const InputDecoration(
                labelText: 'Price Delta (₹) *',
                hintText: '-999.99 to 9999.99',
                prefixText: '₹ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
              ],
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Price delta is required';
                }
                final d = double.tryParse(v.trim());
                if (d == null) return 'Enter a valid number';
                if (d < -999.99) return 'Minimum is -999.99';
                if (d > 9999.99) return 'Maximum is 9999.99';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ModifierGroupCard widget (req 7.9, 7.10)
// ─────────────────────────────────────────────────────────────────────────────

class _ModifierGroupCard extends StatefulWidget {
  const _ModifierGroupCard({
    required this.entry,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  final _ModifierGroupEntry entry;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_ModifierGroupCard> createState() => _ModifierGroupCardState();
}

class _ModifierGroupCardState extends State<_ModifierGroupCard> {
  _ModifierGroupEntry get _g => widget.entry;

  @override
  Widget build(BuildContext context) {
    final minExceedsMax = _g.maxSelect < _g.minSelect;

    return Card(
      elevation: 0,
      color: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: BorderSide(
          color: minExceedsMax ? AppTheme.error : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Group header
            Row(
              children: [
                Text(
                  'Modifier Group ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Semantics(
                  label: 'Remove modifier group ${widget.index + 1}',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: AppTheme.error,
                      tooltip: 'Remove group',
                      onPressed: widget.onRemove,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),

            // ── Group name
            TextFormField(
              key: _g.groupNameKey,
              controller: _g.groupNameCtrl,
              focusNode: _g.groupNameFocus,
              decoration: const InputDecoration(
                labelText: 'Group Name *',
                hintText: 'e.g. Add-ons, Spice Level',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Group name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing12),

            // ── Min / Max selectors side by side
            Row(
              children: [
                Expanded(
                  child: _SelectionCounter(
                    label: 'Min Select',
                    value: _g.minSelect,
                    min: 0,
                    max: 20,
                    onDecrement: _g.minSelect > 0
                        ? () => setState(() => _g.minSelect--)
                        : null,
                    onIncrement: _g.minSelect < 20
                        ? () => setState(() => _g.minSelect++)
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _SelectionCounter(
                    label: 'Max Select',
                    value: _g.maxSelect,
                    min: 1,
                    max: 20,
                    onDecrement: _g.maxSelect > 1
                        ? () => setState(() => _g.maxSelect--)
                        : null,
                    onIncrement: _g.maxSelect < 20
                        ? () => setState(() => _g.maxSelect++)
                        : null,
                  ),
                ),
              ],
            ),

            // ── Req 7.10: show error when max < min
            if (minExceedsMax) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Max selections must be ≥ min selections',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.error),
              ),
            ],

            const SizedBox(height: AppTheme.spacing12),
            const Divider(),
            const SizedBox(height: AppTheme.spacing8),

            // ── Modifier options
            Row(
              children: [
                Text(
                  'Options (${_g.options.length}/30)',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                if (_g.options.length < 30)
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _g.options.add(_ModifierOptionEntry()),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Option'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing4),
            ..._g.options.asMap().entries.map((optEntry) {
              final oi = optEntry.key;
              final o = optEntry.value;
              return Padding(
                key: ValueKey('modifier_option_${widget.index}_$oi'),
                padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                child: _ModifierOptionRow(
                  entry: o,
                  index: oi,
                  canRemove: _g.options.length > 1,
                  onRemove: () => setState(() {
                    o.dispose();
                    _g.options.removeAt(oi);
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ModifierOptionRow widget (req 7.9: modifier_name 1–50, price_delta 0–9999.99)
// ─────────────────────────────────────────────────────────────────────────────

class _ModifierOptionRow extends StatelessWidget {
  const _ModifierOptionRow({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final _ModifierOptionEntry entry;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modifier name — 1–50 chars (Req 7.9)
        Expanded(
          flex: 5,
          child: TextFormField(
            key: entry.modifierNameKey,
            controller: entry.modifierNameCtrl,
            focusNode: entry.modifierNameFocus,
            decoration: InputDecoration(
              labelText: 'Option ${index + 1} *',
              hintText: 'e.g. Extra Cheese',
              isDense: true,
            ),
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Name required';
              }
              if (v.trim().length > 50) {
                return '≤ 50 chars';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),

        // Price delta — 0.00–9999.99 (Req 7.9)
        Expanded(
          flex: 3,
          child: TextFormField(
            key: entry.priceDeltaKey,
            controller: entry.priceDeltaCtrl,
            focusNode: entry.priceDeltaFocus,
            decoration: const InputDecoration(
              labelText: '+₹',
              hintText: '0.00',
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final d = double.tryParse(v.trim());
              if (d == null || d < 0) return '≥ 0';
              if (d > 9999.99) return '≤ 9999.99';
              return null;
            },
          ),
        ),

        // Remove button
        Semantics(
          label: 'Remove option ${index + 1}',
          child: SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: canRemove ? AppTheme.error : AppTheme.mutedText,
              tooltip:
                  canRemove ? 'Remove option' : 'At least 1 option required',
              onPressed: canRemove ? onRemove : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SelectionCounter — min/max stepper widget
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionCounter extends StatelessWidget {
  const _SelectionCounter({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppTheme.mutedText),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outline),
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Decrease $label',
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    padding: EdgeInsets.zero,
                    onPressed: onDecrement,
                  ),
                ),
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Semantics(
                label: 'Increase $label',
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    padding: EdgeInsets.zero,
                    onPressed: onIncrement,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
        if (onAdd != null)
          Semantics(
            label: 'Add $title',
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: onAdd != null ? AppTheme.primary : AppTheme.mutedText,
                tooltip: onAdd != null ? 'Add' : 'Maximum reached',
                onPressed: onAdd,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label, required this.hint});
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        color: AppTheme.surfaceVariant,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.error, fontSize: 13),
      ),
    );
  }
}
