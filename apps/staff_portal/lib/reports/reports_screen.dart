// Feature: rms-flutter-frontend
// Implements: Requirements 14.1–14.8

import 'package:core_ui/core_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_portal/reports/reports_bloc.dart';
import 'package:staff_portal/reports/reports_repository.dart';

/// Reports screen — sales, top items, revenue by type, staff performance, GST.
///
/// Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReportsBloc>(
      create: (ctx) => ReportsBloc(repository: ctx.read()),
      child: const _ReportsView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report type enum & helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _ReportType {
  sales,
  topItems,
  revenueByType,
  staffPerformance,
  gstSummary;

  String get label => switch (this) {
        sales => 'Sales',
        topItems => 'Top Items',
        revenueByType => 'Revenue by Type',
        staffPerformance => 'Staff Performance',
        gstSummary => 'GST Summary',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view — holds date range state and selected report type
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  _ReportType _selected = _ReportType.sales;

  // Default: first day of current month → today (Req 14.6)
  late DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _fetchReport() {
    final bloc = context.read<ReportsBloc>();
    final from = _fmt(_from);
    final to = _fmt(_to);
    switch (_selected) {
      case _ReportType.sales:
        bloc.add(SalesReportRequested(dateFrom: from, dateTo: to));
      case _ReportType.topItems:
        bloc.add(TopItemsReportRequested(dateFrom: from, dateTo: to));
      case _ReportType.revenueByType:
        bloc.add(RevenueByTypeReportRequested(dateFrom: from, dateTo: to));
      case _ReportType.staffPerformance:
        bloc.add(StaffPerformanceReportRequested(dateFrom: from, dateTo: to));
      case _ReportType.gstSummary:
        bloc.add(GstSummaryReportRequested(dateFrom: from, dateTo: to));
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range == null) return;
    setState(() {
      _from = range.start;
      _to = range.end;
    });
    _fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          // Date range picker button (Req 14.6)
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(
              '${_fmt(_from)}  →  ${_fmt(_to)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Report type tab bar
          _ReportTypeTabs(
            selected: _selected,
            onChanged: (t) {
              setState(() => _selected = t);
              _fetchReport();
            },
          ),
          const Divider(height: 1, color: AppTheme.border),
          // Report content area
          Expanded(
            child: BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) => _buildContent(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReportsState state) {
    return switch (state) {
      ReportsInitial() => const SizedBox.shrink(),
      // Loading indicator while endpoint call is in progress (Req 14.8)
      ReportsLoading() => const Center(child: CircularProgressIndicator()),
      // Empty state — hide chart & table, show message (Req 14.7)
      ReportsEmpty() => _EmptyReportMessage(),
      ReportsError(:final message) => ErrorStateWidget(
          message: message,
          onRetry: _fetchReport,
        ),
      SalesReportLoaded(:final data) => _SalesReportView(data: data),
      TopItemsReportLoaded(:final data) => _TopItemsReportView(data: data),
      RevenueByTypeReportLoaded(:final data) =>
        _RevenueByTypeReportView(data: data),
      StaffPerformanceReportLoaded(:final data) =>
        _StaffPerformanceReportView(data: data),
      GstSummaryReportLoaded(:final data) => _GstSummaryReportView(data: data),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report type tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _ReportTypeTabs extends StatelessWidget {
  const _ReportTypeTabs({
    required this.selected,
    required this.onChanged,
  });

  final _ReportType selected;
  final ValueChanged<_ReportType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
      child: Row(
        children: _ReportType.values.map((t) {
          final isSelected = t == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacing8),
            child: ChoiceChip(
              label: Text(t.label),
              selected: isSelected,
              onSelected: (_) => onChanged(t),
              selectedColor: AppTheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.mutedText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyReportMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_outlined,
              size: 56, color: AppTheme.mutedText),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'No data for selected range',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sales Report — bar chart + data table (Req 14.1)
// ─────────────────────────────────────────────────────────────────────────────

class _SalesReportView extends StatelessWidget {
  const _SalesReportView({required this.data});
  final List<SalesReportDay> data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        _SectionLabel('Daily Sales'),
        const SizedBox(height: AppTheme.spacing16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.totalRevenue,
                      color: AppTheme.primary,
                      width: 14,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      // Show day part only to keep labels short
                      final parts = data[idx].date.split('-');
                      final day = parts.length == 3 ? parts[2] : '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(day,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.mutedText)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (v, meta) => Text(
                      '₹${v.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.mutedText),
                    ),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        _SectionLabel('Daily Totals'),
        const SizedBox(height: AppTheme.spacing8),
        _SalesDataTable(data: data),
      ],
    );
  }
}

class _SalesDataTable extends StatelessWidget {
  const _SalesDataTable({required this.data});
  final List<SalesReportDay> data;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: DataTable(
        columnSpacing: AppTheme.spacing16,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Orders'), numeric: true),
          DataColumn(label: Text('Revenue (₹)'), numeric: true),
        ],
        rows: data.map((d) {
          return DataRow(cells: [
            DataCell(Text(d.date)),
            DataCell(Text('${d.totalOrders}')),
            DataCell(Text(d.totalRevenue.toStringAsFixed(2))),
          ]);
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Items Report — ranked list (Req 14.2)
// ─────────────────────────────────────────────────────────────────────────────

class _TopItemsReportView extends StatelessWidget {
  const _TopItemsReportView({required this.data});
  final List<TopItem> data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        _SectionLabel('Top 10 Items by Quantity Sold'),
        const SizedBox(height: AppTheme.spacing12),
        ...data.asMap().entries.map((e) => _TopItemRow(
              rank: e.key + 1,
              item: e.value,
            )),
      ],
    );
  }
}

class _TopItemRow extends StatelessWidget {
  const _TopItemRow({required this.rank, required this.item});
  final int rank;
  final TopItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? AppTheme.primary.withValues(alpha: 0.12)
                    : AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3 ? AppTheme.primary : AppTheme.mutedText,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            // Item name
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.quantity} sold',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.mutedText)),
                Text('₹${item.revenue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Revenue by Type Report — pie chart (Req 14.3)
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueByTypeReportView extends StatelessWidget {
  const _RevenueByTypeReportView({required this.data});
  final List<RevenueByType> data;

  static const _colors = [
    AppTheme.primary,
    AppTheme.success,
    AppTheme.warning,
    AppTheme.error,
  ];

  static const _labels = {
    'dine_in': 'Dine-in',
    'takeaway': 'Takeaway',
    'delivery': 'Delivery',
  };

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, d) => s + d.revenue);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        _SectionLabel('Revenue by Order Type'),
        const SizedBox(height: AppTheme.spacing24),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: data.asMap().entries.map((e) {
                final color = _colors[e.key % _colors.length];
                final pct = total > 0 ? (e.value.revenue / total * 100) : 0.0;
                return PieChartSectionData(
                  value: e.value.revenue,
                  color: color,
                  title: '${pct.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        // Legend
        ...data.asMap().entries.map((e) {
          final color = _colors[e.key % _colors.length];
          final label = _labels[e.value.orderType] ?? e.value.orderType;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: Row(
              children: [
                Container(
                    width: 14,
                    height: 14,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.bodyMedium)),
                Text('₹${e.value.revenue.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staff Performance Report — table sorted by orders handled desc (Req 14.4)
// ─────────────────────────────────────────────────────────────────────────────

class _StaffPerformanceReportView extends StatelessWidget {
  const _StaffPerformanceReportView({required this.data});
  final List<StaffPerformance> data;

  @override
  Widget build(BuildContext context) {
    // Data is already sorted descending by orders handled per BLoC/API contract.
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        _SectionLabel('Staff Performance'),
        const SizedBox(height: AppTheme.spacing12),
        Card(
          elevation: 0,
          color: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: DataTable(
            columnSpacing: AppTheme.spacing16,
            columns: const [
              DataColumn(label: Text('Staff')),
              DataColumn(label: Text('Orders'), numeric: true),
              DataColumn(label: Text('Revenue (₹)'), numeric: true),
            ],
            rows: data.map((d) {
              return DataRow(cells: [
                DataCell(Text(d.staffName)),
                DataCell(Text('${d.ordersHandled}')),
                DataCell(Text(d.totalRevenue.toStringAsFixed(2))),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GST Summary Report — grouped by slab (Req 14.5)
// ─────────────────────────────────────────────────────────────────────────────

class _GstSummaryReportView extends StatelessWidget {
  const _GstSummaryReportView({required this.data});
  final List<GstSummaryItem> data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        _SectionLabel('GST Summary'),
        const SizedBox(height: AppTheme.spacing12),
        Card(
          elevation: 0,
          color: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: DataTable(
            columnSpacing: AppTheme.spacing16,
            columns: const [
              DataColumn(label: Text('GST Rate')),
              DataColumn(label: Text('Taxable (₹)'), numeric: true),
              DataColumn(label: Text('GST (₹)'), numeric: true),
              DataColumn(label: Text('Net Total (₹)'), numeric: true),
            ],
            rows: data.map((d) {
              return DataRow(cells: [
                DataCell(Text('${d.gstRate.toStringAsFixed(0)}%')),
                DataCell(Text(d.taxableValue.toStringAsFixed(2))),
                DataCell(Text(d.gstCollected.toStringAsFixed(2))),
                DataCell(Text(d.netTotal.toStringAsFixed(2))),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
