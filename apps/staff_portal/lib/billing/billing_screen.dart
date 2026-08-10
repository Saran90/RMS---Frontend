// Feature: rms-flutter-frontend
// Implements: Requirements 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8,
//             11.9, 11.10, 11.11, 11.12, 11.13

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'billing_bloc.dart';
import 'billing_repository.dart';
import '../onboarding/razorpay_payment_handler.dart';
import '../orders/order_repository.dart';

// ── Billing page design tokens (aligned with dashboard) ─────────────────────

const Color _billingBg = Color(0xFFF5F0E8);
const Color _billingCard = Color(0xFFFFFFFF);
const Color _billingBorder = Color(0xFFE8E0D0);
const Color _billingTitle = Color(0xFF1A1208);
const Color _billingMuted = Color(0xFF9A8060);
const Color _billingAccent = Color(0xFFBF4010);
const Color _billingDivider = Color(0xFFF0E8D8);

String _formatBillId(Bill bill) {
  if (bill.billNumber != null && bill.billNumber!.isNotEmpty) {
    return bill.billNumber!;
  }
  final id = bill.id;
  return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}

String _formatOrderId(String orderId) {
  return orderId.length > 8
      ? orderId.substring(0, 8).toUpperCase()
      : orderId.toUpperCase();
}

double _billOutstanding(Bill bill) {
  final paid = bill.payments.fold<double>(0, (sum, p) => sum + p.amount);
  return (bill.total - paid).clamp(0, double.infinity);
}

Bill? _extractBillFromState(BillingState state) {
  return switch (state) {
    BillLoaded(:final bill) => bill,
    BillingError(:final bill) => bill,
    _ => null,
  };
}

void _showVoidBillSheet(BuildContext context, Bill bill) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _billingCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<BillingBloc>(),
      child: _VoidBillSheet(bill: bill),
    ),
  );
}

List<Widget> _billingHeaderActions(BuildContext context, BillingState state) {
  final actions = <Widget>[];
  final bloc = context.read<BillingBloc>();
  final bill = _extractBillFromState(state);

  if (state is! BillsListLoaded && state is! BillingLoading) {
    actions.add(
      OutlinedButton.icon(
        onPressed: () => bloc.add(const BillsListRequested()),
        icon: const Icon(Icons.list_alt, size: 16),
        label: const Text('All bills'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _billingTitle,
          side: const BorderSide(color: _billingBorder),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  if (state is BillsListLoaded) {
    actions.add(
      FilledButton.icon(
        onPressed: () => bloc.add(const BillNewRequested()),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New bill'),
        style: FilledButton.styleFrom(
          backgroundColor: _billingAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  if (bill != null && bill.status != 'voided' && bill.status != 'paid') {
    actions.add(const SizedBox(width: 8));
    actions.add(
      OutlinedButton.icon(
        onPressed: () => _showVoidBillSheet(context, bill),
        icon: const Icon(Icons.block_outlined, size: 16),
        label: const Text('Void'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  return actions;
}

/// Entry-point for the `/billing` route.
///
/// Wraps [_BillingView] with a [BillingBloc] and provides the repository
/// from the nearest [RepositoryProvider].
///
/// Requirements: 11.1–11.6, 11.10, 11.11, 11.13
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final repo = context.read<BillingRepository>();
      return BlocProvider<BillingBloc>(
        create: (ctx) {
          final bloc = BillingBloc(repository: repo);
          bloc.add(const BillsListRequested());
          return bloc;
        },
        child: const _BillingView(),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing')),
        body: Center(child: Text('Error: $e')),
      );
    }
  }
}

/// Detail screen for a specific bill, loaded via `/billing/:id`.
///
/// Requirements: 11.1–11.6, 11.10, 11.11, 11.13
class BillingDetailScreen extends StatelessWidget {
  const BillingDetailScreen({required this.billId, super.key});

  final String billId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillingBloc>(
      create: (ctx) =>
          BillingBloc(repository: ctx.read())..add(BillLoadRequested(billId)),
      child: const _BillingView(),
    );
  }
}

// ── Main view ─────────────────────────────────────────────────────────────────

class _BillingView extends StatelessWidget {
  const _BillingView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BillingBloc, BillingState>(
      listener: _handleStateChange,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _billingBg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BillingPageHeader(state: state),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, BillingState state) {
    if (state is BillingError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildBody(BuildContext context, BillingState state) {
    return switch (state) {
      BillingInitial() => _GenerateBillPrompt(),
      BillingLoading() => _loadingWithBill(null),
      BillsListLoaded(:final bills) => _BillsListView(bills: bills),
      BillLoaded(:final bill) => _BillBody(bill: bill),
      BillSplit(:final originalBill, :final subBills) =>
        _SplitBillBody(originalBill: originalBill, subBills: subBills),
      BillingError(:final bill, :final message) when bill != null =>
        _BillBody(bill: bill, errorMessage: message),
      BillingError() => _GenerateBillPrompt(),
    };
  }

  Widget _loadingWithBill(Bill? bill) {
    return const Center(
      child: CircularProgressIndicator(color: _billingAccent),
    );
  }
}

// ── Page header ─────────────────────────────────────────────────────────────

class _BillingPageHeader extends StatelessWidget {
  const _BillingPageHeader({required this.state});

  final BillingState state;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      BillLoaded(:final bill) => 'Bill #${_formatBillId(bill)}',
      BillSplit() => 'Split bills',
      BillingInitial() => 'Generate bill',
      BillsListLoaded() => 'Billing / POS',
      _ => 'Billing / POS',
    };
    final subtitle = switch (state) {
      BillLoaded(:final bill) =>
        'Order #${_formatOrderId(bill.orderId)} · ${bill.status.toUpperCase()}',
      BillsListLoaded() => 'Collect payments and manage open bills',
      BillingInitial() => 'Select an order to create a bill',
      _ => 'Point of sale and payment collection',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state is! BillsListLoaded && state is! BillingLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: IconButton(
                tooltip: 'Back to bills',
                onPressed: () =>
                    context.read<BillingBloc>().add(const BillsListRequested()),
                icon: const Icon(Icons.arrow_back, color: _billingTitle),
                style: IconButton.styleFrom(
                  backgroundColor: _billingCard,
                  side: const BorderSide(color: _billingBorder),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _billingTitle,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: _billingMuted),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: _billingHeaderActions(context, state),
          ),
        ],
      ),
    );
  }
}

// ── Bills list view ───────────────────────────────────────────────────────────

enum _BillFilter { all, open, paid, voided }

class _BillsListView extends StatefulWidget {
  const _BillsListView({required this.bills});
  final List<Bill> bills;

  @override
  State<_BillsListView> createState() => _BillsListViewState();
}

class _BillsListViewState extends State<_BillsListView> {
  _BillFilter _filter = _BillFilter.open;

  List<Bill> get _filtered {
    return switch (_filter) {
      _BillFilter.all => widget.bills,
      _BillFilter.open => widget.bills
          .where((b) => b.status != 'paid' && b.status != 'voided')
          .toList(),
      _BillFilter.paid =>
        widget.bills.where((b) => b.status == 'paid').toList(),
      _BillFilter.voided =>
        widget.bills.where((b) => b.status == 'voided').toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final openBills =
        widget.bills.where((b) => b.status != 'paid' && b.status != 'voided');
    final paidToday = widget.bills.where((b) => b.status == 'paid');
    final outstanding = openBills.fold<double>(0, (s, b) => s + _billOutstanding(b));
    final collected = paidToday.fold<double>(0, (s, b) => s + b.total);

    return RefreshIndicator(
      color: _billingAccent,
      onRefresh: () async {
        context.read<BillingBloc>().add(const BillsListRequested());
        await context.read<BillingBloc>().stream.firstWhere(
              (s) => s is BillsListLoaded || s is BillingError,
            );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: _BillingStatCard(
                  label: 'Open bills',
                  value: '${openBills.length}',
                  icon: Icons.receipt_long_outlined,
                  accent: _billingAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BillingStatCard(
                  label: 'Outstanding',
                  value: '₹${outstanding.toStringAsFixed(0)}',
                  icon: Icons.pending_actions_outlined,
                  accent: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BillingStatCard(
                  label: 'Collected',
                  value: '₹${collected.toStringAsFixed(0)}',
                  icon: Icons.check_circle_outline,
                  accent: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: _BillFilter.values.map((f) {
              final label = switch (f) {
                _BillFilter.all => 'All',
                _BillFilter.open => 'Open',
                _BillFilter.paid => 'Paid',
                _BillFilter.voided => 'Voided',
              };
              final selected = _filter == f;
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: _billingAccent.withValues(alpha: 0.12),
                checkmarkColor: _billingAccent,
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _billingAccent : _billingMuted,
                ),
                side: BorderSide(
                  color: selected ? _billingAccent : _billingBorder,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_filtered.isEmpty)
            _BillingEmptyState(
              message: widget.bills.isEmpty
                  ? 'No bills yet. Generate a bill from an active order.'
                  : 'No bills match this filter.',
            )
          else
            ..._filtered.map((bill) => _BillListTile(bill: bill)),
        ],
      ),
    );
  }
}

class _BillingStatCard extends StatelessWidget {
  const _BillingStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _billingCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _billingBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _billingTitle,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: _billingMuted)),
        ],
      ),
    );
  }
}

class _BillingEmptyState extends StatelessWidget {
  const _BillingEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _billingCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _billingBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: _billingMuted),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _billingMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _BillListTile extends StatelessWidget {
  const _BillListTile({required this.bill});
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final outstanding = _billOutstanding(bill);
    final isOpen = bill.status != 'paid' && bill.status != 'voided';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _billingCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _billingBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              context.read<BillingBloc>().add(BillLoadRequested(bill.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _billingAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_outlined,
                      color: _billingAccent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill #${_formatBillId(bill)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _billingTitle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order #${_formatOrderId(bill.orderId)}',
                        style: const TextStyle(fontSize: 12, color: _billingMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _BillStatusChip(status: bill.status),
                    const SizedBox(height: 6),
                    Text(
                      isOpen && outstanding < bill.total
                          ? '₹${outstanding.toStringAsFixed(2)} due'
                          : '₹${bill.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _billingTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: _billingMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Generate Bill Prompt ──────────────────────────────────────────────────────

class _GenerateBillPrompt extends StatefulWidget {
  @override
  State<_GenerateBillPrompt> createState() => _GenerateBillPromptState();
}

class _GenerateBillPromptState extends State<_GenerateBillPrompt> {
  final _formKey = GlobalKey<FormState>();
  Order? _selectedOrder;
  bool _submitting = false;

  // Orders loading state
  List<Order> _orders = [];
  bool _loadingOrders = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orderRepo = context.read<OrderRepository>();
      final billingRepo = context.read<BillingRepository>();

      // Load orders and open bills in parallel
      final results = await Future.wait([
        orderRepo.getOrders(limit: 100),
        billingRepo.listBills(status: 'open'),
      ]);

      final orders = (results[0] as PaginatedResponse<Order>).data;
      final openBills = results[1] as List<Bill>;

      // Extract order IDs that already have open bills
      final billedOrderIds = openBills.map((b) => b.orderId).toSet();

      // Filter to billable orders without existing open bills
      final billable = orders
          .where((o) =>
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.completed &&
              !billedOrderIds.contains(o.id))
          .toList();

      if (mounted) {
        setState(() {
          _orders = billable;
          _loadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loadingOrders = false;
        });
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    context.read<BillingBloc>().add(BillGenerateRequested(_selectedOrder!.id));
    context.read<BillingBloc>().stream.first.then((_) {
      if (mounted) setState(() => _submitting = false);
    });
  }

  String _orderLabel(Order order) {
    final id = '#${order.id.substring(0, 8).toUpperCase()}';
    final type = switch (order.orderType) {
      OrderType.dineIn => 'Dine-in',
      OrderType.takeaway => 'Takeaway',
      OrderType.delivery => 'Delivery',
    };
    final status = order.status.jsonValue[0].toUpperCase() +
        order.status.jsonValue.substring(1);
    final amount = '₹${order.subtotal.toStringAsFixed(2)}';
    return '$id · $type · $status · $amount';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _billingCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _billingBorder),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 44, color: _billingAccent),
                const SizedBox(height: 16),
                const Text(
                  'Select an order',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _billingTitle,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose an active order to generate a bill for payment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _billingMuted),
                ),
                const SizedBox(height: 24),

                  // Order dropdown
                  if (_loadingOrders)
                    const InputDecorator(
                      decoration: InputDecoration(labelText: 'Order *'),
                      child: Row(children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Loading orders…'),
                      ]),
                    )
                  else if (_loadError != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Failed to load orders',
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 13)),
                        const SizedBox(height: AppTheme.spacing8),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loadingOrders = true;
                              _loadError = null;
                            });
                            _loadOrders();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    )
                  else if (_orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        'No active orders found. Create an order first.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    DropdownButtonFormField<Order>(
                      decoration: const InputDecoration(labelText: 'Order *'),
                      value: _selectedOrder,
                      isExpanded: true,
                      hint: const Text('Select an order'),
                      items: _orders
                          .map((order) => DropdownMenuItem<Order>(
                                value: order,
                                child: Text(
                                  _orderLabel(order),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (o) => setState(() => _selectedOrder = o),
                      validator: (_) => _selectedOrder == null
                          ? 'Please select an order'
                          : null,
                    ),

                  const SizedBox(height: AppTheme.spacing24),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed:
                          (_submitting || _loadingOrders || _orders.isEmpty)
                              ? null
                              : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _billingAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.receipt_long_outlined),
                      label: const Text('Generate Bill'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays a loaded bill's summary, GST breakdown, and payment section.
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8, 11.12, 11.13
class _BillBody extends StatelessWidget {
  const _BillBody({required this.bill, this.errorMessage});

  final Bill bill;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final canPay = bill.status != 'paid' && bill.status != 'voided';
    final canSplit = canPay && bill.payments.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final summary = _BillSummaryCard(bill: bill);
        final paymentSection = canPay
            ? _PaymentFormCard(bill: bill)
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _BillStatusChip(status: bill.status),
              );
        final actions = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canSplit) ...[
              OutlinedButton.icon(
                onPressed: () => _showSplitDialog(context, bill),
                icon: const Icon(Icons.call_split_outlined),
                label: const Text('Split bill'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _billingTitle,
                  side: const BorderSide(color: _billingBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
            ],
            FilledButton.icon(
              onPressed: () => _printBill(bill),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print receipt'),
              style: FilledButton.styleFrom(
                backgroundColor: _billingTitle,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            if (errorMessage != null) ...[
              _ErrorBanner(message: errorMessage!),
              const SizedBox(height: 12),
            ],
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: summary),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        paymentSection,
                        const SizedBox(height: 12),
                        actions,
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              summary,
              const SizedBox(height: 16),
              paymentSection,
              const SizedBox(height: 12),
              actions,
            ],
          ],
        );
      },
    );
  }

  /// Opens a dialog asking for the number of diners (min 2) and dispatches
  /// [BillSplitRequested] on confirmation.
  ///
  /// Requirements: 11.7, 11.8
  void _showSplitDialog(BuildContext context, Bill bill) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BillingBloc>(),
        child: _SplitDinersDialog(bill: bill),
      ),
    );
  }

  /// Renders the bill's [Print_Payload] into a formatted PDF receipt and
  /// triggers the device print dialog via the [printing] package.
  ///
  /// Requirement: 11.12
  Future<void> _printBill(Bill bill) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => _buildReceipt(bill, format),
    );
  }

  /// Builds a PDF receipt document from [bill] data.
  ///
  /// Shows: restaurant name placeholder, bill ID, order ID,
  /// each GST slab, subtotal, total, and payment records.
  ///
  /// Requirement: 11.12
  static Future<Uint8List> _buildReceipt(
      Bill bill, PdfPageFormat format) async {
    final doc = pw.Document();

    // Helper to format rupee amounts
    String rupees(double v) => '₹${v.toStringAsFixed(2)}';

    // Truncated bill/order IDs for receipt display
    final billShort = bill.id.length > 8 ? bill.id.substring(0, 8) : bill.id;
    final orderShort =
        bill.orderId.length > 8 ? bill.orderId.substring(0, 8) : bill.orderId;

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Text(
                'BILL RECEIPT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),

              // Bill metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill #', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(billShort, style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order #', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(orderShort, style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Status', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    bill.status.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // ── Subtotal ─────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: pw.TextStyle(fontSize: 11)),
                  pw.Text(rupees(bill.subtotal),
                      style: pw.TextStyle(fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 4),

              // ── GST slabs ─────────────────────────────────────────────────
              ...bill.gstBreakdown.map((slab) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '  GST ${slab.gstRate.toStringAsFixed(0)}% '
                          '(on ${rupees(slab.taxableValue)})',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          rupees(slab.gstAmount),
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  )),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // ── Total ─────────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    rupees(bill.total),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // ── Payments ──────────────────────────────────────────────────
              if (bill.payments.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),
                pw.Text('Payments',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                ...bill.payments.map((p) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '  ${(p.mode ?? 'unknown').toUpperCase()}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          rupees(p.amount),
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    )),
              ],

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Text(
                'Thank you for dining with us!',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}

// ── Split Diners Dialog ───────────────────────────────────────────────────────

/// Dialog that asks for the number of diners before splitting the bill.
///
/// Requirements: 11.7, 11.8
class _SplitDinersDialog extends StatefulWidget {
  const _SplitDinersDialog({required this.bill});

  final Bill bill;

  @override
  State<_SplitDinersDialog> createState() => _SplitDinersDialogState();
}

class _SplitDinersDialogState extends State<_SplitDinersDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dinersCtrl = TextEditingController(text: '2');
  bool _submitting = false;

  @override
  void dispose() {
    _dinersCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final diners = int.parse(_dinersCtrl.text.trim());

    setState(() => _submitting = true);
    context.read<BillingBloc>().add(
          BillSplitRequested(billId: widget.bill.id, diners: diners),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Split Bill'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the number of diners (minimum 2) to split the bill equally.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _dinersCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Number of Diners *',
                hintText: 'Min 2',
                prefixIcon: Icon(Icons.people_outline),
              ),
              // Req 11.7: require diners >= 2
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Number of diners is required';
                }
                final n = int.tryParse(v.trim());
                if (n == null || n < 2) {
                  return 'Minimum 2 diners required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.call_split_outlined, size: 18),
          label: const Text('Split'),
        ),
      ],
    );
  }
}

// ── Bill Summary Card ─────────────────────────────────────────────────────────

/// Shows subtotal, one line per GST slab, and grand total.
///
/// Requirements: 11.1, 11.13
class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _billingCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _billingBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bill #${_formatBillId(bill)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _billingTitle,
                  ),
                ),
                _BillStatusChip(status: bill.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Order #${_formatOrderId(bill.orderId)}',
              style: const TextStyle(fontSize: 12.5, color: _billingMuted),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: _billingDivider),
            ),
            // Subtotal
            _AmountRow(label: 'Subtotal', amount: bill.subtotal, muted: true),
            const SizedBox(height: AppTheme.spacing8),
            // GST breakdown — one line per distinct slab (Req 11.13)
            ...bill.gstBreakdown.map((slab) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
                  child: _AmountRow(
                    label: 'GST ${slab.gstRate.toStringAsFixed(0)}%'
                        ' (on ₹${slab.taxableValue.toStringAsFixed(2)})',
                    amount: slab.gstAmount,
                    muted: true,
                    indent: true,
                  ),
                )),
            const Divider(height: 16, color: _billingDivider),
            // Total
            _AmountRow(
              label: 'Total',
              amount: bill.total,
              bold: true,
            ),
            if (bill.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bill.payments.map((p) => _AmountRow(
                    label: 'Paid (${(p.mode ?? 'unknown').toUpperCase()})',
                    amount: p.amount,
                    muted: true,
                  )),
              const Divider(height: 16, color: _billingDivider),
              _AmountRow(
                label: 'Outstanding',
                amount: _outstanding(bill),
                bold: true,
                color:
                    _outstanding(bill) > 0 ? AppTheme.error : AppTheme.success,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _outstanding(Bill bill) => _billOutstanding(bill);
}

// ── Payment Form Card ─────────────────────────────────────────────────────────

/// Staff POS payment recording (cash / UPI / card) plus on-screen payment QR.
///
/// Requirements: 11.3, 11.4, 11.5, 11.6
class _PaymentFormCard extends StatefulWidget {
  const _PaymentFormCard({required this.bill});

  final Bill bill;

  @override
  State<_PaymentFormCard> createState() => _PaymentFormCardState();
}

class _PaymentFormCardState extends State<_PaymentFormCard> {
  static const _modes = ['cash', 'upi', 'card'];

  String _mode = 'cash';
  bool _submitting = false;

  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _outstanding.toStringAsFixed(2),
    );
    _referenceController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _PaymentFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bill.id != widget.bill.id ||
        oldWidget.bill.total != widget.bill.total ||
        oldWidget.bill.payments.length != widget.bill.payments.length) {
      _amountController.text = _outstanding.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  double get _outstanding {
    final paid =
        widget.bill.payments.fold<double>(0, (sum, p) => sum + p.amount);
    return (widget.bill.total - paid).clamp(0, double.infinity);
  }

  bool get _canShowPaymentQr =>
      widget.bill.status == 'open' && _outstanding > 0;

  String? _modeHint(String mode) {
    return switch (mode) {
      'upi' => _canShowPaymentQr
          ? 'Ask the customer to scan the QR below, then record payment once '
              'confirmed.'
          : _outstanding <= 0 && widget.bill.total > 0
              ? 'This bill is fully paid — no QR needed.'
              : 'Bill total is ₹0 — add items to the order and regenerate the bill '
                  'to show a payment QR.',
      'card' =>
        'Swipe or tap the card on your Pine Labs terminal, then record the '
            'payment here.',
      'cash' => 'Count cash received from the customer, then record payment.',
      _ => null,
    };
  }

  String _billLabel() {
    final label = widget.bill.billNumber ??
        (widget.bill.id.length > 8
            ? widget.bill.id.substring(0, 8).toUpperCase()
            : widget.bill.id.toUpperCase());
    return 'Bill #$label';
  }

  void _submitManualPayment() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount')),
      );
      return;
    }
    if (amount > _outstanding) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot exceed outstanding balance '
            '(₹${_outstanding.toStringAsFixed(2)})',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    context.read<BillingBloc>().add(BillPaymentRequested(
          billId: widget.bill.id,
          mode: _mode,
          amount: amount,
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
        ));
    context.read<BillingBloc>().stream
        .firstWhere((s) => s is BillLoaded || s is BillingError)
        .then((state) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (state is BillLoaded && state.bill.status == 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hint = _modeHint(_mode);
    final showInlineQr = _mode == 'upi' && _canShowPaymentQr;

    return Container(
      decoration: BoxDecoration(
        color: _billingCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _billingBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.payment_outlined,
                    size: 18, color: _billingAccent),
                const SizedBox(width: 8),
                const Text(
                  'Collect payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _billingTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _billingBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _billingBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding',
                      style: TextStyle(color: _billingMuted, fontSize: 13)),
                  Text(
                    '₹${_outstanding.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _billingTitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment mode',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _billingMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _modes.map((m) {
                final selected = _mode == m;
                return ChoiceChip(
                  label: Text(m.toUpperCase()),
                  selected: selected,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _mode = m),
                  selectedColor: _billingAccent.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _billingAccent : _billingMuted,
                  ),
                  side: BorderSide(
                    color: selected ? _billingAccent : _billingBorder,
                  ),
                );
              }).toList(),
            ),
            if (hint != null) ...[
              const SizedBox(height: 10),
              Text(hint,
                  style: const TextStyle(fontSize: 12, color: _billingMuted)),
            ],
            if (showInlineQr) ...[
              const SizedBox(height: 16),
              _InlineBillPaymentQr(
                bill: widget.bill,
                billLabel: _billLabel(),
                amountRupees: _outstanding,
              ),
            ] else if (_mode == 'upi' && widget.bill.status == 'open') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppTheme.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _outstanding <= 0 && widget.bill.total > 0
                            ? 'Outstanding balance is ₹0 — payment QR is not '
                                'available.'
                            : 'Payment QR cannot be generated for a ₹0 bill. Add '
                                'items to the order, then generate a new bill.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _billingTitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              enabled: !_submitting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextFormField(
              controller: _referenceController,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: _mode == 'cash'
                    ? 'Note (optional)'
                    : 'Terminal / txn reference (optional)',
                hintText: _mode == 'cash'
                    ? 'e.g. rounded change'
                    : 'e.g. Pine Labs approval code',
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submitManualPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: _billingAccent,
                  foregroundColor: Colors.white,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Record payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inline payment QR (UPI mode) ────────────────────────────────────────────

class _InlineBillPaymentQr extends StatefulWidget {
  const _InlineBillPaymentQr({
    required this.bill,
    required this.billLabel,
    required this.amountRupees,
  });

  final Bill bill;
  final String billLabel;
  final double amountRupees;

  @override
  State<_InlineBillPaymentQr> createState() => _InlineBillPaymentQrState();
}

class _InlineBillPaymentQrState extends State<_InlineBillPaymentQr> {
  BillPaymentQrResponse? _qr;
  String? _error;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadQr();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollBill());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQr() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final qr = await context.read<BillingRepository>().createBillPaymentQr(
            widget.bill.id,
          );
      if (mounted) {
        setState(() {
          _qr = qr;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.statusCode == 502
              ? 'Payment gateway unavailable'
              : e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pollBill() async {
    if (!mounted) return;
    try {
      final bill =
          await context.read<BillingRepository>().getBill(widget.bill.id);
      if (bill.status == 'paid') {
        _pollTimer?.cancel();
        if (!mounted) return;
        context.read<BillingBloc>().add(BillLoadRequested(widget.bill.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment received — bill marked as paid.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _billingBorder),
      ),
      child: Column(
        children: [
          Text(
            'Scan to pay · ₹${widget.amountRupees.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _billingTitle,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Customer scans with any UPI app',
            style: TextStyle(fontSize: 12, color: _billingMuted),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: _billingAccent),
            )
          else if (_error != null)
            Column(
              children: [
                Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.error, fontSize: 13)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _loadQr, child: const Text('Retry')),
              ],
            )
          else if (_qr != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _billingDivider),
                  ),
                  child: QrImageView(
                    data: _qr!.qrPayload,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _qr!.shortUrl,
                  style: const TextStyle(fontSize: 11, color: _billingMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Payment QR dialog ─────────────────────────────────────────────────────────

/// Full-screen-style dialog showing a Razorpay payment-link QR for customer scan.
class _BillPaymentQrDialog extends StatefulWidget {
  const _BillPaymentQrDialog({
    required this.bill,
    required this.outstanding,
    required this.billLabel,
  });

  final Bill bill;
  final double outstanding;
  final String billLabel;

  @override
  State<_BillPaymentQrDialog> createState() => _BillPaymentQrDialogState();
}

class _BillPaymentQrDialogState extends State<_BillPaymentQrDialog> {
  BillPaymentQrResponse? _qr;
  String? _error;
  bool _loading = true;
  bool _refreshing = false;
  bool _checkoutFallback = false;
  bool _checkoutOpening = false;
  Timer? _pollTimer;
  RazorpayPaymentHandler? _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = RazorpayPaymentHandler(
      onSuccess: _onCheckoutSuccess,
      onFailure: _onCheckoutFailure,
      onDismiss: () {
        if (mounted) setState(() => _checkoutOpening = false);
      },
    );
    _razorpay?.init();
    _loadQr();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollBill());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _razorpay?.dispose();
    super.dispose();
  }

  Future<void> _loadQr() async {
    setState(() {
      _loading = true;
      _error = null;
      _checkoutFallback = false;
    });
    try {
      final qr = await context.read<BillingRepository>().createBillPaymentQr(
            widget.bill.id,
          );
      if (mounted) {
        setState(() {
          _qr = qr;
          _loading = false;
        });
      }
    } on BillPaymentQrUnavailableException {
      if (mounted) {
        setState(() {
          _loading = false;
          _checkoutFallback = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.statusCode == 502
              ? 'Payment gateway unavailable'
              : e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openCheckoutFallback() async {
    setState(() {
      _checkoutOpening = true;
      _error = null;
    });
    try {
      final initiate = await context
          .read<BillingRepository>()
          .initiateBillPayment(widget.bill.id);
      _razorpay?.open(
        initiate.toCheckoutParams(description: widget.billLabel),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _checkoutOpening = false;
          _error = e.statusCode == 502
              ? 'Payment gateway unavailable'
              : e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkoutOpening = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _onCheckoutSuccess({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      await context.read<BillingRepository>().verifyBillPayment(
            billId: widget.bill.id,
            razorpayPaymentId: paymentId,
            razorpayOrderId: orderId,
            razorpaySignature: signature,
          );
      _pollTimer?.cancel();
      if (!mounted) return;
      context.read<BillingBloc>().add(BillLoadRequested(widget.bill.id));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified — bill marked as paid.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _checkoutOpening = false;
          _error = e.statusCode == 400
              ? 'Payment verification failed'
              : e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkoutOpening = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onCheckoutFailure(String message) {
    if (mounted) {
      setState(() {
        _checkoutOpening = false;
        _error = message;
      });
    }
  }

  Future<void> _pollBill() async {
    if (!mounted) return;
    try {
      final bill = await context.read<BillingRepository>().getBill(widget.bill.id);
      if (bill.status == 'paid') {
        _pollTimer?.cancel();
        if (!mounted) return;
        context.read<BillingBloc>().add(BillLoadRequested(widget.bill.id));
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment received — bill marked as paid.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // Ignore transient poll errors.
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _refreshing = true);
    await _pollBill();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _qr != null
        ? '₹${_qr!.amountRupees.toStringAsFixed(2)}'
        : '₹${widget.outstanding.toStringAsFixed(2)}';

    return AlertDialog(
      title: Text('Payment QR — ${widget.billLabel}'),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppTheme.spacing24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _checkoutFallback
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payment_outlined,
                          size: 40, color: AppTheme.mutedText),
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        'QR payment link is not available. Open Razorpay '
                        'Checkout as a fallback.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      FilledButton.icon(
                        onPressed:
                            _checkoutOpening ? null : _openCheckoutFallback,
                        icon: _checkoutOpening
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.open_in_new_outlined),
                        label: const Text('Open Razorpay Checkout'),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppTheme.spacing12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ],
                    ],
                  )
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.error, size: 40),
                      const SizedBox(height: AppTheme.spacing12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: AppTheme.spacing16),
                      OutlinedButton(
                        onPressed: _loadQr,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        amount,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Ask the customer to scan and pay',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.mutedText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      QrImageView(
                        data: _qr!.qrPayload,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      SelectableText(
                        _qr!.shortUrl,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.mutedText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        'Payment status updates automatically when the customer '
                        'completes payment.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (!_loading && _error == null && !_checkoutFallback)
          FilledButton.icon(
            onPressed: _refreshing ? null : _refreshStatus,
            icon: _refreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Check status'),
          ),
      ],
    );
  }
}

// ── Bill Status Chip ──────────────────────────────────────────────────────────

/// Small colour-coded badge showing the bill's current status.
///
/// Requirements: 11.1, 11.10
class _BillStatusChip extends StatelessWidget {
  const _BillStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, fgColor) = switch (status) {
      'open' => ('Open', AppTheme.warningContainer, AppTheme.warning),
      'paid' => ('Paid', AppTheme.successContainer, AppTheme.success),
      'voided' => ('Voided', AppTheme.errorContainer, AppTheme.error),
      _ => ('Unknown', AppTheme.surfaceVariant, AppTheme.mutedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fgColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Amount Row ────────────────────────────────────────────────────────────────

/// A single line showing a label on the left and a ₹amount on the right.
///
/// Requirements: 11.1, 11.13
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.muted = false,
    this.indent = false,
    this.bold = false,
    this.color,
  });

  final String label;
  final double amount;
  final bool muted;
  final bool indent;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = muted ? textTheme.bodySmall : textTheme.bodyMedium;
    final effectiveStyle = baseStyle?.copyWith(
      fontWeight: bold ? FontWeight.w700 : baseStyle.fontWeight,
      color: color ?? baseStyle.color,
    );

    return Padding(
      padding: EdgeInsets.only(left: indent ? AppTheme.spacing16 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: effectiveStyle),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: effectiveStyle,
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

/// Amber/red banner surfacing an error message to the user.
///
/// Requirements: 11.2, 11.4, 11.11
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 18, color: AppTheme.error),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Change Due Banner ─────────────────────────────────────────────────────────

// ── Void Bill Sheet ───────────────────────────────────────────────────────────

/// Bottom sheet for the void-bill flow.
///
/// Requirements: 11.10, 11.11
class _VoidBillSheet extends StatefulWidget {
  const _VoidBillSheet({required this.bill});

  final Bill bill;

  @override
  State<_VoidBillSheet> createState() => _VoidBillSheetState();
}

class _VoidBillSheetState extends State<_VoidBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Void Bill',
      message:
          'Are you sure you want to void bill #${widget.bill.id.length > 8 ? widget.bill.id.substring(0, 8) : widget.bill.id}? This action cannot be undone.',
      confirmLabel: 'Void',
      cancelLabel: 'Cancel',
    );

    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    try {
      context.read<BillingBloc>().add(BillVoidRequested(
            billId: widget.bill.id,
            reason: _reasonCtrl.text.trim(),
          ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
        top: AppTheme.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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
              'Void Bill',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Please provide a reason for voiding this bill.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Void Reason *',
                hintText: 'e.g. Customer cancelled order',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'A reason is required to void this bill'
                  : null,
            ),
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: AppTheme.onError,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.onError),
                          )
                        : const Text('Void Bill'),
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

// ── Split Bill Body ───────────────────────────────────────────────────────────

/// Displays the original bill alongside all resulting sub-bills after a split.
///
/// Requirements: 11.9
class _SplitBillBody extends StatelessWidget {
  const _SplitBillBody({
    required this.originalBill,
    required this.subBills,
  });

  final Bill originalBill;
  final List<Bill> subBills;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        // Header
        Text('Split Bill', style: textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'Original bill split into ${subBills.length} parts.',
          style: textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Original bill summary (collapsed)
        _BillSummaryCard(bill: originalBill),
        const SizedBox(height: AppTheme.spacing16),

        // Sub-bills
        ...subBills.asMap().entries.map((entry) {
          final index = entry.key;
          final sub = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: _SubBillCard(index: index + 1, bill: sub),
          );
        }),
      ],
    );
  }
}

/// A compact card showing one sub-bill from a split.
class _SubBillCard extends StatelessWidget {
  const _SubBillCard({required this.index, required this.bill});

  final int index;
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Split $index', style: textTheme.titleSmall),
                _BillStatusChip(status: bill.status),
              ],
            ),
            const Divider(height: AppTheme.spacing16, color: AppTheme.border),
            _AmountRow(label: 'Subtotal', amount: bill.subtotal, muted: true),
            const SizedBox(height: AppTheme.spacing4),
            // GST breakdown per slab (Req 11.13)
            ...bill.gstBreakdown.map((slab) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
                  child: _AmountRow(
                    label:
                        'GST ${slab.gstRate.toStringAsFixed(0)}% (on ₹${slab.taxableValue.toStringAsFixed(2)})',
                    amount: slab.gstAmount,
                    muted: true,
                    indent: true,
                  ),
                )),
            const Divider(height: AppTheme.spacing12, color: AppTheme.border),
            _AmountRow(label: 'Total', amount: bill.total, bold: true),
          ],
        ),
      ),
    );
  }
}
