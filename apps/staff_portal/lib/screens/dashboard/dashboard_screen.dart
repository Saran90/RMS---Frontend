// Feature: rms-flutter-frontend
// Implements: Requirements 5.1–5.7

import 'package:auth/auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:staff_portal/dashboard/dashboard_bloc.dart';
import 'package:staff_portal/dashboard/dashboard_repository.dart';
import 'package:staff_portal/navigation/role_navigation.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const Color _bg = Color(0xFFF5F0E8);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _cardBorder = Color(0xFFE8E0D0);
const Color _titleColor = Color(0xFF1A1208);
const Color _mutedColor = Color(0xFF9A8060);
const Color _accentOrange = Color(0xFFBF4010);
const Color _divider = Color(0xFFF0E8D8);

// Table status colours (matching mockup)
const Color _tableAvailable = Color(0xFFD8F5E8); // light green
const Color _tableAvailableBorder = Color(0xFF80D8A8);
const Color _tableOccupied = Color(0xFFD8EEFF); // light blue
const Color _tableOccupiedBorder = Color(0xFF80B8E8);
const Color _tableReserved = Color(0xFFFFF8D8); // light yellow
const Color _tableReservedBorder = Color(0xFFD8C040);
const Color _tableCleaning = Color(0xFFF0ECE8); // grey
const Color _tableCleaningBorder = Color(0xFFC0B8B0);
const Color _tableText = Color(0xFF3A2810);

// Chart orange
const Color _barColor = Color(0xFFBF4010);

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (ctx) => DashboardBloc(
        repository: ctx.read<DashboardRepository>(),
      )..add(const DashboardLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: _accentOrange,
            onRefresh: () async => context
                .read<DashboardBloc>()
                .add(const DashboardRefreshRequested()),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _PageHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: _buildBody(state),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(DashboardState state) {
    return switch (state) {
      DashboardInitial() || DashboardLoading() => const _SkeletonBody(),
      DashboardLoaded(:final stats, :final activeOrders, :final tables) =>
        _LoadedBody(stats: stats, activeOrders: activeOrders, tables: tables),
      DashboardPartialError(
        :final stats,
        :final activeOrders,
        :final tables,
        :final statsError,
        :final ordersError,
      ) =>
        _LoadedBody(
          stats: stats,
          activeOrders: activeOrders ?? [],
          tables: tables,
          statsError: statsError,
          ordersError: ordersError,
        ),
      DashboardError(:final message) => _InlineError(message: message),
    };
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final authState = context.watch<AuthBloc>().state;
    final canSwitch = authState is TenantAuthenticated &&
        canSwitchRestaurant(authState.role);
    final headerInitials = authState is TenantAuthenticated
        ? userInitials(authState.displayName)
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                        letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(dateStr,
                    style: const TextStyle(fontSize: 12.5, color: _mutedColor)),
              ],
            ),
          ),
          Row(
            children: [
              if (canSwitch) ...[
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const RestaurantSwitchRequested()),
                  icon: const Icon(Icons.storefront_outlined, size: 16),
                  label: const Text('Switch restaurant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _titleColor,
                    side: const BorderSide(color: _cardBorder),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _HeaderIconBtn(Icons.notifications_outlined),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    headerInitials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Icon(icon, size: 18, color: _mutedColor),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  Widget _box(double h) => Container(
        height: h,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricSkeleton(),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _box(320)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _box(320)),
          ],
        ),
      ],
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 200).floor().clamp(2, 4);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisExtent: 108,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
        ),
      );
    });
  }
}

// ── Loaded body ───────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.stats,
    required this.activeOrders,
    required this.tables,
    this.statsError,
    this.ordersError,
  });

  final DashboardStats? stats;
  final List<Order> activeOrders;
  final List<Table> tables;
  final String? statsError;
  final String? ordersError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric cards
        if (statsError != null)
          _InlineError(message: statsError!)
        else if (stats != null)
          _MetricGrid(stats: stats!),
        const SizedBox(height: 20),

        // Bottom two-panel row
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _TableStatusCard(tables: tables)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _WeeklyRevenueCard(stats: stats)),
              ],
            );
          }
          return Column(
            children: [
              _TableStatusCard(tables: tables),
              const SizedBox(height: 16),
              _WeeklyRevenueCard(stats: stats),
            ],
          );
        }),
      ],
    );
  }
}

// ── Metric grid ───────────────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final avgCheck =
        stats.totalOrders > 0 ? stats.totalRevenue / stats.totalOrders : 0.0;

    final metrics = [
      _Metric(
        icon: Icons.trending_up,
        iconBg: const Color(0xFFFFF3E8),
        iconColor: const Color(0xFFBF4010),
        label: 'Revenue',
        value: '\$${_fmt(stats.totalRevenue)}',
        sub: '+1.2% today',
        subUp: true,
      ),
      _Metric(
        icon: Icons.table_restaurant_outlined,
        iconBg: const Color(0xFFE8F5FF),
        iconColor: const Color(0xFF0084C8),
        label: 'Active Tables',
        value: '${stats.occupiedTables}/${stats.totalTables}',
        sub: 'occupied now',
        subUp: null,
      ),
      _Metric(
        icon: Icons.receipt_long_outlined,
        iconBg: const Color(0xFFE8F8EE),
        iconColor: const Color(0xFF16A34A),
        label: 'Orders Today',
        value: '${stats.totalOrders}',
        sub: '6 pending kitchen',
        subUp: null,
      ),
      _Metric(
        icon: Icons.attach_money,
        iconBg: const Color(0xFFF5E8FF),
        iconColor: const Color(0xFF8040D8),
        label: 'Avg Check',
        value: '\$${_fmt(avgCheck)}',
        sub: 'per table',
        subUp: null,
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 200).floor().clamp(2, 4);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisExtent: 108,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: metrics.length,
        itemBuilder: (_, i) => _MetricCard(m: metrics[i]),
      );
    });
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }
}

class _Metric {
  const _Metric({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
    required this.subUp,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  final bool? subUp;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.m});
  final _Metric m;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: m.iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(m.icon, color: m.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(m.value,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                        letterSpacing: -0.5)),
                const SizedBox(height: 1),
                Text(m.label,
                    style: const TextStyle(fontSize: 11, color: _mutedColor)),
                const SizedBox(height: 3),
                Row(children: [
                  if (m.subUp != null)
                    Icon(m.subUp! ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: m.subUp! ? const Color(0xFF16A34A) : Colors.red),
                  if (m.subUp != null) const SizedBox(width: 2),
                  Text(m.sub,
                      style: TextStyle(
                          fontSize: 10,
                          color: m.subUp == true
                              ? const Color(0xFF16A34A)
                              : _mutedColor)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table Status card ─────────────────────────────────────────────────────────

class _TableStatusCard extends StatelessWidget {
  const _TableStatusCard({required this.tables});
  final List<Table> tables;

  @override
  Widget build(BuildContext context) {
    final available =
        tables.where((t) => t.status == TableStatus.available).length;
    final occupied =
        tables.where((t) => t.status == TableStatus.occupied).length;
    final reserved =
        tables.where((t) => t.status == TableStatus.reserved).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Table Status',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _titleColor)),
              const Spacer(),
              // Legend
              _Legend('Free', _tableAvailableBorder),
              const SizedBox(width: 10),
              _Legend('Busy', _tableOccupiedBorder),
              const SizedBox(width: 10),
              _Legend('Res.', _tableReservedBorder),
            ],
          ),
          const SizedBox(height: 16),

          // Table grid
          if (tables.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No tables configured',
                    style: TextStyle(color: _mutedColor, fontSize: 13)),
              ),
            )
          else
            LayoutBuilder(builder: (context, c) {
              final cols = (c.maxWidth / 72).floor().clamp(3, 8);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: 72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: tables.length,
                itemBuilder: (_, i) => _TableTile(table: tables[i]),
              );
            }),

          const SizedBox(height: 12),
          // Summary counts
          Row(
            children: [
              _CountChip('$available Free', _tableAvailableBorder),
              const SizedBox(width: 8),
              _CountChip('$occupied Busy', _tableOccupiedBorder),
              const SizedBox(width: 8),
              _CountChip('$reserved Res.', _tableReservedBorder),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table});
  final Table table;

  static Color _bg(TableStatus s) => switch (s) {
        TableStatus.available => _tableAvailable,
        TableStatus.occupied => _tableOccupied,
        TableStatus.reserved => _tableReserved,
        TableStatus.cleaning => _tableCleaning,
      };

  static Color _border(TableStatus s) => switch (s) {
        TableStatus.available => _tableAvailableBorder,
        TableStatus.occupied => _tableOccupiedBorder,
        TableStatus.reserved => _tableReservedBorder,
        TableStatus.cleaning => _tableCleaningBorder,
      };

  static Color _dot(TableStatus s) => switch (s) {
        TableStatus.available => Color(0xFF16A34A),
        TableStatus.occupied => Color(0xFF0084C8),
        TableStatus.reserved => Color(0xFFB87800),
        TableStatus.cleaning => Color(0xFF9A8060),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg(table.status),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border(table.status)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            table.tableNumber,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _tableText,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _dot(table.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _label(table.status),
            style: const TextStyle(fontSize: 9, color: _tableText),
          ),
        ],
      ),
    );
  }

  String _label(TableStatus s) => switch (s) {
        TableStatus.available => 'Free',
        TableStatus.occupied => 'Busy',
        TableStatus.reserved => 'Res.',
        TableStatus.cleaning => 'Clean',
      };
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _mutedColor)),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Weekly Revenue card ───────────────────────────────────────────────────────

class _WeeklyRevenueCard extends StatelessWidget {
  const _WeeklyRevenueCard({required this.stats});
  final DashboardStats? stats;

  // Simulated 7-day data; replace with real API data when available.
  static const List<double> _weekData = [
    3200,
    4100,
    2800,
    5600,
    6400,
    7800,
    5200
  ];
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  Widget build(BuildContext context) {
    final maxY = _weekData.reduce((a, b) => a > b ? a : b) * 1.25;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Revenue',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _titleColor)),
          const SizedBox(height: 4),
          const Text('Last 7 days',
              style: TextStyle(fontSize: 11, color: _mutedColor)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: _divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_days[i],
                              style: const TextStyle(
                                  fontSize: 10, color: _mutedColor)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(_weekData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _weekData[i],
                        color: _barColor,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _titleColor,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '\$${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline error ──────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
          ),
          TextButton(
            onPressed: () => context
                .read<DashboardBloc>()
                .add(const DashboardRefreshRequested()),
            child:
                const Text('Retry', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}
