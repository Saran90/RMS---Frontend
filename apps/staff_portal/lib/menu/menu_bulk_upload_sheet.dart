// Feature: rms-flutter-frontend
// Implements: Menu Bulk Upload UI

import 'package:core_ui/core_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bulk_upload_models.dart';
import 'menu_item_bloc.dart';
import 'menu_repository.dart';

/// Opens the Menu Bulk Upload bottom sheet.
///
/// The sheet walks the user through three stages:
///   1. **Idle** — pick an .xlsx file (with a collapsible template reference).
///   2. **Uploading** — linear progress indicator while the file is sent.
///   3. **Result** — import summary with counts and any non-fatal warnings.
///
/// The caller must ensure [MenuItemBloc] and [MenuRepository] are available
/// in [context].
void showMenuBulkUploadSheet(BuildContext context) {
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
      ],
      child: _BulkUploadSheet(
        repository: context.read<MenuRepository>(),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _BulkUploadSheet extends StatefulWidget {
  const _BulkUploadSheet({required this.repository});
  final MenuRepository repository;

  @override
  State<_BulkUploadSheet> createState() => _BulkUploadSheetState();
}

class _BulkUploadSheetState extends State<_BulkUploadSheet> {
  // ── State ──────────────────────────────────────────────────────────────────
  PlatformFile? _pickedFile;
  BulkUploadTemplate? _template;
  bool _loadingTemplate = false;
  String? _templateError;
  bool _templateExpanded = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true, // load bytes into memory (max 10 MB enforced by server)
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _loadingTemplate = true;
      _templateError = null;
    });
    try {
      final t = await widget.repository.getBulkUploadTemplate();
      setState(() {
        _template = t;
        _templateExpanded = true;
      });
    } catch (e) {
      setState(() => _templateError = e.toString());
    } finally {
      setState(() => _loadingTemplate = false);
    }
  }

  void _upload() {
    final file = _pickedFile;
    if (file == null || file.bytes == null) return;
    context.read<MenuItemBloc>().add(
          MenuBulkUploadRequested(
            fileBytes: file.bytes!,
            filename: file.name,
          ),
        );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => BlocConsumer<MenuItemBloc, MenuItemState>(
          listener: _handleStateChange,
          builder: (context, state) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(AppTheme.spacing24),
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

                  // Title
                  Row(
                    children: [
                      const Icon(Icons.upload_file_outlined,
                          color: AppTheme.primary),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'Bulk Upload Menu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Import the entire menu from an .xlsx file in one shot.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: AppTheme.spacing16),

                  // ── Body — delegates to the appropriate stage widget
                  if (state is MenuBulkUploadSuccess)
                    _ResultView(result: state.result)
                  else if (state is MenuBulkUploadInProgress)
                    _UploadingView(progress: state.progress)
                  else ...[
                    // Error banner (if previous upload failed)
                    if (state is MenuItemOperationError) ...[
                      _ErrorBanner(message: state.message),
                      const SizedBox(height: AppTheme.spacing16),
                    ],

                    // Template reference section
                    _TemplateSection(
                      expanded: _templateExpanded,
                      loading: _loadingTemplate,
                      template: _template,
                      error: _templateError,
                      onToggle: () {
                        if (_template == null && !_loadingTemplate) {
                          _loadTemplate();
                        } else {
                          setState(
                              () => _templateExpanded = !_templateExpanded);
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // File picker
                    _FilePicker(
                      picked: _pickedFile,
                      onPick: _pickFile,
                      onClear: () => setState(() => _pickedFile = null),
                    ),
                    const SizedBox(height: AppTheme.spacing24),

                    // Upload button
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _pickedFile != null ? _upload : null,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Upload & Import'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleStateChange(BuildContext context, MenuItemState state) {
    // On success the result view is shown inline; no auto-close.
    // On error, the BlocConsumer rebuilds with the error banner — no action
    // needed here beyond letting the builder handle it.
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Template reference section
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateSection extends StatelessWidget {
  const _TemplateSection({
    required this.expanded,
    required this.loading,
    required this.template,
    required this.error,
    required this.onToggle,
  });

  final bool expanded;
  final bool loading;
  final BulkUploadTemplate? template;
  final String? error;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Expandable header row
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Template — expected sheet structure',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppTheme.mutedText,
                  ),
              ],
            ),
          ),
        ),

        // Expanded content
        if (expanded && template != null) ...[
          const SizedBox(height: AppTheme.spacing8),
          ...template!.sheets.map((sheet) => _SheetDefCard(def: sheet)),
        ],
        if (expanded && error != null) ...[
          const SizedBox(height: AppTheme.spacing8),
          _ErrorBanner(message: 'Could not load template: $error'),
        ],
      ],
    );
  }
}

class _SheetDefCard extends StatelessWidget {
  const _SheetDefCard({required this.def});
  final BulkUploadSheetDef def;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                def.sheet,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing4, vertical: 2),
                decoration: BoxDecoration(
                  color: def.required
                      ? AppTheme.primaryContainer
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                  border: Border.all(
                    color: def.required ? AppTheme.primary : AppTheme.outline,
                  ),
                ),
                child: Text(
                  def.required ? 'Required' : 'Optional',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: def.required
                            ? AppTheme.primary
                            : AppTheme.mutedText,
                      ),
                ),
              ),
            ],
          ),
          if (def.columns.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing4),
            Wrap(
              spacing: AppTheme.spacing4,
              runSpacing: AppTheme.spacing4,
              children: def.columns.map((col) {
                final name = col['name'] as String? ?? col.toString();
                final required = col['required'] as bool? ?? false;
                return Chip(
                  label: Text(
                    required ? '$name *' : name,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppTheme.surfaceVariant,
                  side: const BorderSide(color: AppTheme.border),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// File picker tile
// ─────────────────────────────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.picked,
    required this.onPick,
    required this.onClear,
  });

  final PlatformFile? picked;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (picked == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.attach_file),
        label: const Text('Choose .xlsx file'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      );
    }

    final sizeKb = ((picked!.size) / 1024).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  picked!.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$sizeKb KB',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Remove selected file',
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.mutedText,
                tooltip: 'Remove file',
                onPressed: onClear,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Uploading view
// ─────────────────────────────────────────────────────────────────────────────

class _UploadingView extends StatelessWidget {
  const _UploadingView({this.progress});
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.spacing24),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.surfaceVariant,
        ),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          progress != null
              ? 'Uploading… ${(progress! * 100).toInt()}%'
              : 'Uploading…',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.mutedText),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Do not close this sheet',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.mutedText),
        ),
        const SizedBox(height: AppTheme.spacing24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result view
// ─────────────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final BulkUploadResult result;

  @override
  Widget build(BuildContext context) {
    final s = result.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success header
        Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.success, size: 28),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                result.message,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.success),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Summary counts
        _SummaryGrid(summary: s),
        const SizedBox(height: AppTheme.spacing16),

        // Warnings
        if (s.warnings.isNotEmpty) ...[
          Text(
            'Warnings (${s.warnings.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.warning,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: AppTheme.warningContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.warning),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppTheme.spacing12),
              itemCount: s.warnings.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacing4),
              itemBuilder: (_, i) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      size: 14, color: AppTheme.warning),
                  const SizedBox(width: AppTheme.spacing4),
                  Expanded(
                    child: Text(
                      s.warnings[i],
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Done button
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});
  final BulkUploadSummary summary;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Categories', summary.categoriesCreated, Icons.category_outlined),
      ('Items', summary.itemsCreated, Icons.restaurant_menu_outlined),
      ('Variants', summary.variantsCreated, Icons.tune_outlined),
      (
        'Modifier Groups',
        summary.modifierGroupsCreated,
        Icons.add_circle_outline
      ),
      ('Modifiers', summary.modifiersCreated, Icons.add_box_outlined),
    ];

    return Wrap(
      spacing: AppTheme.spacing8,
      runSpacing: AppTheme.spacing8,
      children: entries.map((e) {
        final (label, count, icon) = e;
        return Container(
          constraints: const BoxConstraints(minWidth: 100),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing12,
            vertical: AppTheme.spacing8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.mutedText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
