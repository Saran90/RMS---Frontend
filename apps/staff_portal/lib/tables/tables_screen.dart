// Feature: rms-flutter-frontend
// Implements: Requirements 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:staff_portal/reservation/reservation_bloc.dart';
import 'package:staff_portal/reservation/reservation_repository.dart';
import 'package:staff_portal/tables/table_bloc.dart';
import 'package:staff_portal/tables/table_repository.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const _kPageBg = Color(0xFFF5F0E8);
const _kCardBg = Color(0xFFFFFFFF);
const _kAvailable = Color(0xFF00BFA5);
const _kOccupied = Color(0xFFF5A623);
const _kReserved = Color(0xFF00B4D8);
const _kCleaning = Color(0xFF9CA3AF);

Color _statusColor(TableStatus s) => switch (s) {
      TableStatus.available => _kAvailable,
      TableStatus.occupied => _kOccupied,
      TableStatus.reserved => _kReserved,
      TableStatus.cleaning => _kCleaning,
    };

String _statusLabel(TableStatus s) => switch (s) {
      TableStatus.available => 'Available',
      TableStatus.occupied => 'Occupied',
      TableStatus.reserved => 'Reserved',
      TableStatus.cleaning => 'Cleaning',
    };

const _kDefaultSectionLabel = 'General';

String _tableSectionKey(Table table) {
  final label = table.sectionLabel?.trim();
  if (label == null || label.isEmpty) return _kDefaultSectionLabel;
  return label;
}

List<(String section, List<Table> tables)> _groupTablesBySection(
  List<Table> tables,
) {
  final grouped = <String, List<Table>>{};
  for (final table in tables) {
    grouped.putIfAbsent(_tableSectionKey(table), () => []).add(table);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => _compareTableNumbers(a.tableNumber, b.tableNumber));
  }
  final keys = grouped.keys.toList()
    ..sort((a, b) {
      if (a == _kDefaultSectionLabel) return 1;
      if (b == _kDefaultSectionLabel) return -1;
      return a.compareTo(b);
    });
  return keys.map((k) => (k, grouped[k]!)).toList();
}

int _compareTableNumbers(String a, String b) {
  final na = int.tryParse(a);
  final nb = int.tryParse(b);
  if (na != null && nb != null) return na.compareTo(nb);
  return a.compareTo(b);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TableBloc>(
      create: (ctx) => TableBloc(
        repository: ctx.read<TableRepository>(),
        reservationRepository: ctx.read<ReservationRepository>(),
      )..add(const TablesLoadRequested()),
      child: BlocListener<ReservationBloc, ReservationState>(
        // Re-load tables whenever the reservation list changes so the
        // "Reserved" tag on a table card appears / disappears in sync
        // with reservations being created, disabled, or re-enabled.
        listenWhen: (prev, curr) {
          // Only refresh when the reservation list actually changes
          // (not on every transient state transition).
          if (prev is ReservationLoaded && curr is ReservationLoaded) {
            return prev.reservations.length != curr.reservations.length ||
                prev.reservations != curr.reservations;
          }
          return curr is ReservationLoaded;
        },
        listener: (context, _) {
          if (!context.mounted) return;
          context.read<TableBloc>().add(const TablesLoadRequested());
        },
        child: const _TablesView(),
      ),
    );
  }
}

class _TablesView extends StatelessWidget {
  const _TablesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: BlocBuilder<TableBloc, TableState>(
        builder: (context, state) => switch (state) {
          TableInitial() ||
          TableLoading() =>
            const Center(child: CircularProgressIndicator()),
          TableError(:final message) => ErrorStateWidget(
              message: message,
              onRetry: () =>
                  context.read<TableBloc>().add(const TablesLoadRequested()),
            ),
          TableLoaded(:final tables, :final refreshError) => Column(
              children: [
                if (refreshError != null) _ErrorBanner(message: refreshError),
                Expanded(child: _TablesBody(tables: tables)),
              ],
            ),
          TableOperationError(:final tables, :final message) => Column(
              children: [
                _ErrorBanner(message: message),
                Expanded(child: _TablesBody(tables: tables)),
              ],
            ),
        },
      ),
    );
  }
}

class _TablesBody extends StatefulWidget {
  const _TablesBody({required this.tables});
  final List<Table> tables;

  @override
  State<_TablesBody> createState() => _TablesBodyState();
}

class _TablesBodyState extends State<_TablesBody> {
  String? _selectedSection;

  @override
  Widget build(BuildContext context) {
    final sections = _groupTablesBySection(widget.tables);
    final sectionNames = sections.map((e) => e.$1).toList();
    final visibleSections = _selectedSection == null
        ? sections
        : sections.where((e) => e.$1 == _selectedSection).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _PageHeader(onAdd: () => _showAddSheet(context)),
        ),
        if (sectionNames.length > 1)
          SliverToBoxAdapter(
            child: _SectionFilterBar(
              sections: sectionNames,
              selected: _selectedSection,
              onSelected: (value) =>
                  setState(() => _selectedSection = value),
            ),
          ),
        if (widget.tables.isEmpty)
          const SliverToBoxAdapter(child: _EmptyState())
        else
          for (final (section, sectionTables) in visibleSections) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: section,
                count: sectionTables.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _TableCard(table: sectionTables[i]),
                  childCount: sectionTables.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 175,
                  mainAxisExtent: 108,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TableBloc>(),
        child: const _AddTablesSheet(),
      ),
    );
  }
}

class _SectionFilterBar extends StatelessWidget {
  const _SectionFilterBar({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<String> sections;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _SectionChip(
            label: 'All sections',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final section in sections) ...[
            const SizedBox(width: 8),
            _SectionChip(
              label: section,
              selected: selected == section,
              onTap: () => onSelected(section),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : _kCardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count table${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tables',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface)),
                const SizedBox(height: 2),
                Text(today, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_outlined, size: 22),
            color: AppTheme.mutedText,
            onPressed: () =>
                context.read<TableBloc>().add(const TablesLoadRequested()),
          ),
          IconButton(
            tooltip: 'Add Tables',
            icon: const Icon(Icons.add_outlined, size: 22),
            color: AppTheme.mutedText,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});
  final Table table;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(table.status);
    return Semantics(
      label: 'Table ${table.tableNumber}, ${_statusLabel(table.status)}',
      button: true,
      child: GestureDetector(
        onTap: () => _showTableSheet(context, table),
        child: Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(table.tableNumber,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                      height: 1.0)),
              const SizedBox(height: 7),
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(height: 5),
              Text(_statusLabel(table.status),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mutedText)),
              if (table.currentOrderId != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                      table.currentOrderId!.length > 8
                          ? table.currentOrderId!.substring(0, 8)
                          : table.currentOrderId!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.mutedText)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 320,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.table_restaurant_outlined,
                size: 56, color: AppTheme.mutedText),
            const SizedBox(height: AppTheme.spacing12),
            Text('No tables yet',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.mutedText)),
            const SizedBox(height: AppTheme.spacing8),
            Text('Tap + to add tables',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.mutedText)),
          ]),
        ));
  }
}

// ── Table bottom sheet ────────────────────────────────────────────────────────

void _showTableSheet(BuildContext context, Table table) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => BlocProvider.value(
      value: context.read<TableBloc>(),
      child: _TableBottomSheet(table: table),
    ),
  );
}

class _TableBottomSheet extends StatelessWidget {
  const _TableBottomSheet({required this.table});
  final Table table;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing24,
          top: AppTheme.spacing16,
          left: AppTheme.spacing24,
          right: AppTheme.spacing24),
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
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: AppTheme.spacing16),
          Row(children: [
            Text('Table ${table.tableNumber}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: AppTheme.spacing12),
            _StatusChip(status: table.status),
          ]),
          if (table.sectionLabel != null &&
              table.sectionLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing8),
            Row(children: [
              const Icon(Icons.grid_view_outlined,
                  size: 16, color: AppTheme.mutedText),
              const SizedBox(width: AppTheme.spacing4),
              Text('Section: ${table.sectionLabel!.trim()}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedText)),
            ]),
          ],
          if (table.currentOrderId != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            Row(children: [
              const Icon(Icons.receipt_outlined,
                  size: 16, color: AppTheme.mutedText),
              const SizedBox(width: AppTheme.spacing4),
              Text('Order: ${table.currentOrderId}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedText)),
            ]),
          ],
          const SizedBox(height: AppTheme.spacing24),
          ..._transitions(table.status).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                child: SizedBox(
                    height: 48,
                    child: FilledButton.tonal(
                      onPressed: () {
                        if (t.status == TableStatus.reserved) {
                          // Capture the bloc before popping the sheet so
                          // we don't read from a deactivated context.
                          final bloc = context.read<TableBloc>();
                          Navigator.of(context).pop();
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: AppTheme.cardSurface,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20))),
                            builder: (_) => BlocProvider.value(
                              value: bloc,
                              child: _ReservationSheet(tableId: table.id),
                            ),
                          );
                        } else {
                          context.read<TableBloc>().add(
                              TableStatusUpdateRequested(
                                  id: table.id, status: t.status));
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(t.label),
                    )),
              )),
          const SizedBox(height: AppTheme.spacing8),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
                context: context, builder: (_) => _QrCodeDialog(table: table)),
            icon: const Icon(Icons.qr_code_outlined),
            label: const Text('View QR Code'),
          ),
          // Edit Reservation — only shown when table is currently reserved
          if (table.status == TableStatus.reserved) ...[
            const SizedBox(height: AppTheme.spacing8),
            OutlinedButton.icon(
              onPressed: () {
                // Capture the bloc before popping so the new sheet can
                // access it without touching a deactivated context.
                final bloc = context.read<TableBloc>();
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.cardSurface,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: _ReservationSheet(
                      tableId: table.id,
                      existingName: table.reservationName,
                      existingPhone: table.reservationPhone,
                      existingFrom: table.reservedFor,
                      existingUntil: table.reservedUntil,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Edit Reservation'),
            ),
          ],
          const SizedBox(height: AppTheme.spacing8),
          OutlinedButton.icon(
            onPressed: () {
              // Capture the bloc before popping so the new sheet can
              // access it without touching a deactivated context.
              final bloc = context.read<TableBloc>();
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.cardSurface,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: _EditTableSheet(table: table),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Table'),
          ),
          const SizedBox(height: AppTheme.spacing8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
            ),
            onPressed: () => _confirmDelete(context, table),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Table'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Table table) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Table'),
        content:
            Text('Delete Table ${table.tableNumber}? This cannot be undone.\n\n'
                'Note: tables with active orders cannot be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              context.read<TableBloc>().add(
                    TableDeleteRequested(id: table.id),
                  );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<({String label, TableStatus status})> _transitions(TableStatus s) =>
      switch (s) {
        TableStatus.available => [
            (label: 'Mark Occupied', status: TableStatus.occupied),
            (label: 'Mark Reserved', status: TableStatus.reserved),
          ],
        TableStatus.occupied => [
            (label: 'Mark Cleaning', status: TableStatus.cleaning),
            (label: 'Mark Available', status: TableStatus.available),
          ],
        TableStatus.reserved => [
            (label: 'Mark Available', status: TableStatus.available),
            (label: 'Mark Occupied', status: TableStatus.occupied),
          ],
        TableStatus.cleaning => [
            (label: 'Mark Available', status: TableStatus.available),
          ],
      };
}

class _QrCodeDialog extends StatelessWidget {
  const _QrCodeDialog({required this.table});
  final Table table;

  @override
  Widget build(BuildContext context) {
    final url = table.qrUrl ?? 'https://rms.app/order?table=${table.id}';
    return AlertDialog(
      title: Text('QR Code — Table ${table.tableNumber}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        QrImageView(
            data: url,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white),
        const SizedBox(height: AppTheme.spacing12),
        SelectableText(url,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.mutedText),
            textAlign: TextAlign.center),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'))
      ],
    );
  }
}

// ── Add Tables sheet — Single + Bulk tabs ────────────────────────────────────

class _AddTablesSheet extends StatefulWidget {
  const _AddTablesSheet();

  @override
  State<_AddTablesSheet> createState() => _AddTablesSheetState();
}

class _AddTablesSheetState extends State<_AddTablesSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: AppTheme.spacing16),
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: AppTheme.spacing12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
          child: Row(children: [
            Text('Add Tables', style: Theme.of(context).textTheme.titleLarge),
          ]),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFF0EAE0),
                borderRadius: BorderRadius.circular(10)),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.onSurface,
              unselectedLabelColor: AppTheme.mutedText,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              tabs: const [
                Tab(text: 'Single Table'),
                Tab(text: 'Bulk Create'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _tab,
            physics: const NeverScrollableScrollPhysics(),
            children: const [_SingleForm(), _BulkForm()],
          ),
        ),
      ]),
    );
  }
}

// ── Single table form ─────────────────────────────────────────────────────────

class _SingleForm extends StatefulWidget {
  const _SingleForm();

  @override
  State<_SingleForm> createState() => _SingleFormState();
}

class _SingleFormState extends State<_SingleForm> {
  final _key = GlobalKey<FormState>();
  final _numCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '4');
  final _secCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _numCtrl.dispose();
    _capCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    context.read<TableBloc>().add(TableCreateRequested(
          tableNumber: int.parse(_numCtrl.text.trim()),
          capacity: int.parse(_capCtrl.text.trim()),
          sectionLabel:
              _secCtrl.text.trim().isEmpty ? null : _secCtrl.text.trim(),
        ));
    context.read<TableBloc>().stream.first.then((s) {
      if (!mounted) return;
      if (s is TableOperationError) {
        setState(() {
          _loading = false;
          _error = s.message;
        });
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing24, AppTheme.spacing8,
          AppTheme.spacing24, AppTheme.spacing24),
      child: Form(
          key: _key,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) ...[
              _FormError(message: _error!),
              const SizedBox(height: AppTheme.spacing12)
            ],
            Row(children: [
              Expanded(
                  child: _F(
                      ctrl: _numCtrl,
                      label: 'Table Number *',
                      hint: 'e.g. 1',
                      type: TextInputType.number,
                      fmt: [FilteringTextInputFormatter.digitsOnly],
                      val: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        return (n == null || n < 1) ? 'Must be ≥ 1' : null;
                      })),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                  child: _F(
                      ctrl: _capCtrl,
                      label: 'Capacity *',
                      hint: 'Seats',
                      type: TextInputType.number,
                      fmt: [FilteringTextInputFormatter.digitsOnly],
                      val: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        return (n == null || n < 1) ? 'Min 1' : null;
                      })),
            ]),
            const SizedBox(height: AppTheme.spacing12),
            _F(
                ctrl: _secCtrl,
                label: 'Section Label',
                hint: 'e.g. Ground Floor (optional)',
                fmt: [LengthLimitingTextInputFormatter(100)]),
            const SizedBox(height: AppTheme.spacing16),
            _Btn(label: 'Add Table', loading: _loading, onPressed: _submit),
          ])),
    );
  }
}

// ── Bulk form ─────────────────────────────────────────────────────────────────

class _BulkForm extends StatefulWidget {
  const _BulkForm();

  @override
  State<_BulkForm> createState() => _BulkFormState();
}

class _BulkFormState extends State<_BulkForm> {
  final _key = GlobalKey<FormState>();
  final _cntCtrl = TextEditingController(text: '5');
  final _secCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '4');
  final _stCtrl = TextEditingController(text: '1');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cntCtrl.dispose();
    _secCtrl.dispose();
    _capCtrl.dispose();
    _stCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    context.read<TableBloc>().add(TablesBulkCreateRequested(
          count: int.parse(_cntCtrl.text.trim()),
          sectionLabel: _secCtrl.text.trim(),
          capacity: int.parse(_capCtrl.text.trim()),
          startingNumber: int.parse(_stCtrl.text.trim()),
        ));
    context.read<TableBloc>().stream.first.then((s) {
      if (!mounted) return;
      if (s is TableOperationError) {
        setState(() {
          _loading = false;
          _error = s.message;
        });
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cnt = int.tryParse(_cntCtrl.text) ?? 0;
    final st = int.tryParse(_stCtrl.text) ?? 1;
    final sec = _secCtrl.text.trim();
    final preview = cnt > 0
        ? 'Creates tables $st – ${st + cnt - 1}'
            '${sec.isNotEmpty ? ' in "$sec"' : ''}'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacing24, AppTheme.spacing8,
          AppTheme.spacing24, AppTheme.spacing24),
      child: Form(
          key: _key,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) ...[
              _FormError(message: _error!),
              const SizedBox(height: AppTheme.spacing12)
            ],
            _F(
                ctrl: _secCtrl,
                label: 'Section Label *',
                hint: 'e.g. Rooftop, Main Hall',
                fmt: [LengthLimitingTextInputFormatter(100)],
                val: (v) => (v == null || v.trim().isEmpty)
                    ? 'Section label is required'
                    : null,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: AppTheme.spacing12),
            Row(children: [
              Expanded(
                  child: _F(
                      ctrl: _cntCtrl,
                      label: 'No. of Tables *',
                      hint: '1–50',
                      type: TextInputType.number,
                      fmt: [FilteringTextInputFormatter.digitsOnly],
                      val: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        return (n == null || n < 1 || n > 50) ? '1–50' : null;
                      },
                      onChanged: (_) => setState(() {}))),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                  child: _F(
                      ctrl: _capCtrl,
                      label: 'Capacity *',
                      hint: 'Seats',
                      type: TextInputType.number,
                      fmt: [FilteringTextInputFormatter.digitsOnly],
                      val: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        return (n == null || n < 1) ? 'Min 1' : null;
                      })),
            ]),
            const SizedBox(height: AppTheme.spacing12),
            _F(
                ctrl: _stCtrl,
                label: 'Starting Number *',
                hint: 'First table number',
                type: TextInputType.number,
                fmt: [FilteringTextInputFormatter.digitsOnly],
                val: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  return (n == null || n < 1) ? 'Must be ≥ 1' : null;
                },
                onChanged: (_) => setState(() {})),
            if (preview != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAE6FD))),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(preview,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF0369A1)))),
                ]),
              ),
            ],
            const SizedBox(height: AppTheme.spacing16),
            _Btn(label: 'Create Tables', loading: _loading, onPressed: _submit),
          ])),
    );
  }
}

// ── Reservation sheet ─────────────────────────────────────────────────────────

/// Two modes:
/// - "Right now" — reserved_for = now, reserved_until = now + 2 hours
/// - "Future time" — user picks date/time for both fields
class _ReservationSheet extends StatefulWidget {
  const _ReservationSheet({
    required this.tableId,
    this.existingName,
    this.existingPhone,
    this.existingFrom,
    this.existingUntil,
  });
  final String tableId;
  final String? existingName;
  final String? existingPhone;
  final DateTime? existingFrom;
  final DateTime? existingUntil;

  @override
  State<_ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<_ReservationSheet> {
  int _mode = 0;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  DateTime? _reservedFor;
  DateTime? _reservedUntil;
  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.existingName != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingName ?? '');
    _phoneCtrl = TextEditingController(text: widget.existingPhone ?? '');
    if (widget.existingFrom != null) {
      _reservedFor = widget.existingFrom;
      _reservedUntil = widget.existingUntil;
      _mode = 1; // pre-select Future Time when editing
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          isStart ? now : (now.add(const Duration(hours: 2)))),
    );
    if (time == null || !mounted) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _reservedFor = dt;
      } else {
        _reservedUntil = dt;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Use local time so the time selected by the user is the time that
    // gets stored / sent to the backend (no UTC conversion).
    final now = DateTime.now();
    final DateTime reservedFor;
    final DateTime reservedUntil;

    if (_mode == 0) {
      reservedFor = now;
      reservedUntil = now.add(const Duration(hours: 2));
    } else {
      if (_reservedFor == null || _reservedUntil == null) {
        setState(() => _error = 'Please select both start and end times');
        return;
      }
      if (!_reservedUntil!.isAfter(_reservedFor!)) {
        setState(() => _error = 'End time must be after start time');
        return;
      }
      // _reservedFor / _reservedUntil are already in local time (built
      // from the date + TimeOfDay picked by the user). Pass them as-is
      // so the local timezone is preserved end-to-end.
      reservedFor = _reservedFor!;
      reservedUntil = _reservedUntil!;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    context.read<TableBloc>().add(TableStatusUpdateRequested(
          id: widget.tableId,
          status: TableStatus.reserved,
          reservation: TableReservation(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            reservedFor: reservedFor,
            reservedUntil: reservedUntil,
          ),
        ));
    context.read<TableBloc>().stream.first.then((s) {
      if (!mounted) return;
      if (s is TableOperationError) {
        setState(() {
          _loading = false;
          _error = s.message;
        });
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing24,
        top: AppTheme.spacing16,
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: AppTheme.spacing12),
            Text('Reserve Table',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacing16),

            // Mode toggle
            Container(
              height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0EAE0),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                _ModeTab(
                    label: 'Right Now',
                    selected: _mode == 0,
                    onTap: () => setState(() => _mode = 0)),
                _ModeTab(
                    label: 'Future Time',
                    selected: _mode == 1,
                    onTap: () => setState(() => _mode = 1)),
              ]),
            ),
            const SizedBox(height: AppTheme.spacing16),

            if (_error != null) ...[
              _FormError(message: _error!),
              const SizedBox(height: AppTheme.spacing12),
            ],

            // Guest name + phone
            Row(children: [
              Expanded(
                  child: _F(
                ctrl: _nameCtrl,
                label: 'Guest Name *',
                hint: 'John Smith',
                val: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              )),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                  child: _F(
                ctrl: _phoneCtrl,
                label: 'Phone *',
                hint: '9876543210',
                type: TextInputType.phone,
                val: (v) => (v == null || v.trim().isEmpty)
                    ? 'Phone is required'
                    : null,
              )),
            ]),

            // Future time pickers
            if (_mode == 1) ...[
              const SizedBox(height: AppTheme.spacing12),
              Row(children: [
                Expanded(
                    child: _DateTimeButton(
                  label: 'From',
                  value: _reservedFor,
                  onTap: () => _pickDateTime(true),
                )),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                    child: _DateTimeButton(
                  label: 'Until',
                  value: _reservedUntil,
                  onTap: () => _pickDateTime(false),
                )),
              ]),
            ] else ...[
              const SizedBox(height: AppTheme.spacing8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAE6FD))),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    'Reserved now for 2 hours',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                  )),
                ]),
              ),
            ],

            const SizedBox(height: AppTheme.spacing16),
            _Btn(
                label: 'Confirm Reservation',
                loading: _loading,
                onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          selected ? AppTheme.onSurface : AppTheme.mutedText))),
        ),
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'Select time'
        : '${value!.day}/${value!.month} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.access_time, size: 16),
      label: Text('$label: $display', style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        side: BorderSide(
            color: value != null ? AppTheme.primary : AppTheme.outline),
      ),
    );
  }
}

// ── Edit table sheet ──────────────────────────────────────────────────────────

class _EditTableSheet extends StatefulWidget {
  const _EditTableSheet({required this.table});
  final Table table;

  @override
  State<_EditTableSheet> createState() => _EditTableSheetState();
}

class _EditTableSheetState extends State<_EditTableSheet> {
  late final TextEditingController _numCtrl;
  late final TextEditingController _capCtrl;
  late final TextEditingController _secCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _numCtrl = TextEditingController(text: widget.table.tableNumber);
    _capCtrl = TextEditingController();
    _secCtrl = TextEditingController(text: widget.table.sectionLabel ?? '');
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _capCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _loading = true;
      _error = null;
    });
    final num = int.tryParse(_numCtrl.text.trim());
    final cap = int.tryParse(_capCtrl.text.trim());
    final sec = _secCtrl.text.trim();
    context.read<TableBloc>().add(TableEditRequested(
          id: widget.table.id,
          tableNumber: num,
          capacity: cap,
          sectionLabel: sec.isEmpty ? null : sec,
        ));
    context.read<TableBloc>().stream.first.then((s) {
      if (!mounted) return;
      if (s is TableOperationError) {
        setState(() {
          _loading = false;
          _error = s.message;
        });
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing24,
        top: AppTheme.spacing16,
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
      ),
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
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: AppTheme.spacing16),
          Text('Edit Table ${widget.table.tableNumber}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacing4),
          Text('Leave a field blank to keep the current value.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.mutedText)),
          const SizedBox(height: AppTheme.spacing16),
          if (_error != null) ...[
            _FormError(message: _error!),
            const SizedBox(height: AppTheme.spacing12),
          ],
          Row(children: [
            Expanded(
                child: _F(
              ctrl: _numCtrl,
              label: 'Table Number',
              hint: 'Current: ${widget.table.tableNumber}',
              type: TextInputType.number,
              fmt: [FilteringTextInputFormatter.digitsOnly],
            )),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
                child: _F(
              ctrl: _capCtrl,
              label: 'Capacity',
              hint: 'New capacity',
              type: TextInputType.number,
              fmt: [FilteringTextInputFormatter.digitsOnly],
            )),
          ]),
          const SizedBox(height: AppTheme.spacing12),
          _F(
              ctrl: _secCtrl,
              label: 'Section Label',
              hint: 'New section label (optional)',
              fmt: [LengthLimitingTextInputFormatter(100)]),
          const SizedBox(height: AppTheme.spacing16),
          _Btn(label: 'Save Changes', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TableStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Text(_statusLabel(status),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
        child: Row(children: [
          const Icon(Icons.warning_amber_outlined,
              color: AppTheme.error, size: 18),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13))),
        ]),
      ),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.error)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: AppTheme.error, fontSize: 12.5))),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(
      {required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.onPrimary))
              : const Icon(Icons.check_outlined),
          label: Text(label),
        ));
  }
}

// _F is a top-level helper function — not a class method
Widget _F({
  required TextEditingController ctrl,
  required String label,
  required String hint,
  TextInputType? type,
  List<TextInputFormatter>? fmt,
  FormFieldValidator<String>? val,
  ValueChanged<String>? onChanged,
}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: type,
    inputFormatters: fmt,
    validator: val,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}
