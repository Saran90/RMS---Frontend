// Feature: rms-flutter-frontend
// Implements: Requirements 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8,
//             11.9, 11.10, 11.11, 11.12, 11.13

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'billing_bloc.dart';
import 'billing_repository.dart';
import '../orders/order_repository.dart';

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
    print('BillingScreen: build called');
    try {
      final repo = context.read<BillingRepository>();
      print('BillingScreen: got repository');
      return BlocProvider<BillingBloc>(
        create: (ctx) {
          print('BillingScreen: creating bloc');
          final bloc = BillingBloc(repository: repo);
          print('BillingScreen: bloc created, adding event');
          bloc.add(const BillsListRequested());
          print('BillingScreen: event added');
          return bloc;
        },
        child: const _BillingView(),
      );
    } catch (e, stackTrace) {
      print('BillingScreen: Error creating bloc - $e');
      print('BillingScreen: Stack trace - $stackTrace');
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
    final state = context.watch<BillingBloc>().state;
    final showBackButton = state is BillLoaded || state is BillSplit;

    return BlocConsumer<BillingBloc, BillingState>(
      listener: _handleStateChange,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('Billing / POS'),
            automaticallyImplyLeading: !showBackButton,
            leading: showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to Bills List',
                    onPressed: () => context
                        .read<BillingBloc>()
                        .add(const BillsListRequested()),
                  )
                : null,
            actions: _buildAppBarActions(context, state),
          ),
          body: _buildBody(context, state),
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

    // When a bill is fully paid, mark the associated order as completed
    // and return to the bills list.
    if (state is BillLoaded && state.bill.status == 'paid') {
      context.read<OrderRepository>().updateOrderStatus(
            state.bill.orderId,
            OrderStatus.completed,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded — order marked as completed.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      // Navigate back to the bills list
      context.read<BillingBloc>().add(const BillsListRequested());
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context, BillingState state) {
    final actions = <Widget>[];

    // Show "Back to List" button when viewing a bill detail or split bills
    if (state is BillLoaded || state is BillSplit) {
      actions.add(
        TextButton.icon(
          onPressed: () =>
              context.read<BillingBloc>().add(const BillsListRequested()),
          icon: const Icon(Icons.list_alt, color: Colors.white),
          label:
              const Text('Back to List', style: TextStyle(color: Colors.white)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      );
    }

    // Add void button for unpaid bills
    final bill = _extractBill(state);
    if (bill != null && bill.status != 'voided' && bill.status != 'paid') {
      actions.add(
        IconButton(
          icon: const Icon(Icons.block_outlined),
          tooltip: 'Void Bill',
          onPressed: () => _showVoidDialog(context, bill),
        ),
      );
    }

    return actions;
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
    return const Center(child: CircularProgressIndicator());
  }

  Bill? _extractBill(BillingState state) {
    return switch (state) {
      BillLoaded(:final bill) => bill,
      BillingError(:final bill) => bill,
      _ => null,
    };
  }

  void _showVoidDialog(BuildContext context, Bill bill) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<BillingBloc>(),
        child: _VoidBillSheet(bill: bill),
      ),
    );
  }
}

// ── Bills list view ───────────────────────────────────────────────────────────

class _BillsListView extends StatelessWidget {
  const _BillsListView({required this.bills});
  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    final active =
        bills.where((b) => b.status != 'paid' && b.status != 'voided').toList();
    final recent =
        bills.where((b) => b.status == 'paid' || b.status == 'voided').toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        // New bill button
        FilledButton.icon(
          onPressed: () =>
              context.read<BillingBloc>().add(const BillNewRequested()),
          icon: const Icon(Icons.add),
          label: const Text('Generate New Bill'),
        ),
        if (active.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing24),
          Text('Active Bills', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing8),
          ...active.map((bill) => _BillListTile(bill: bill)),
        ],
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing24),
          Text('Recent Bills',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.mutedText)),
          const SizedBox(height: AppTheme.spacing8),
          ...recent.take(5).map((bill) => _BillListTile(bill: bill)),
        ],
        if (bills.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacing32),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 48, color: AppTheme.mutedText),
                  const SizedBox(height: AppTheme.spacing16),
                  Text('No bills yet',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppTheme.mutedText)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BillListTile extends StatelessWidget {
  const _BillListTile({required this.bill});
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: () =>
            context.read<BillingBloc>().add(BillLoadRequested(bill.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill #${bill.id.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${bill.orderId.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.mutedText),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _BillStatusChip(status: bill.status),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '₹${bill.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
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
    } catch (e, stackTrace) {
      print('Error loading orders: $e');
      print('Stack trace: $stackTrace');
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Card(
          elevation: 0,
          color: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 48, color: AppTheme.mutedText),
                  const SizedBox(height: AppTheme.spacing16),
                  Text('Generate Bill',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppTheme.spacing8),
                  Text('Select an order to generate a bill.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.mutedText),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppTheme.spacing24),

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
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.onPrimary),
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
      ),
    );
  }
}

// ── Bill Body (main bill display) ─────────────────────────────────────────────

/// Displays a loaded bill's summary, GST breakdown, and payment section.
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8, 11.12, 11.13
class _BillBody extends StatelessWidget {
  const _BillBody({required this.bill, this.errorMessage});

  final Bill bill;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        if (errorMessage != null) ...[
          _ErrorBanner(message: errorMessage!),
          const SizedBox(height: AppTheme.spacing12),
        ],
        _BillSummaryCard(bill: bill),
        const SizedBox(height: AppTheme.spacing16),
        // Show payment form when bill is not yet paid or voided
        if (bill.status != 'paid' && bill.status != 'voided')
          _PaymentFormCard(bill: bill)
        else
          _BillStatusChip(status: bill.status),
        // Split Bill: only for unpaid bills with no payments yet (Req 11.7)
        if (bill.status != 'paid' &&
            bill.status != 'voided' &&
            bill.payments.isEmpty) ...[
          const SizedBox(height: AppTheme.spacing12),
          OutlinedButton.icon(
            onPressed: () => _showSplitDialog(context, bill),
            icon: const Icon(Icons.call_split_outlined),
            label: const Text('Split Bill'),
          ),
        ],
        // Print Bill: available for all bill statuses (Req 11.12)
        ...[
          const SizedBox(height: AppTheme.spacing12),
          FilledButton.icon(
            onPressed: () => _printBill(bill),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print Bill'),
          ),
        ],
      ],
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
                Text(
                    'Bill #${bill.id.length > 8 ? bill.id.substring(0, 8) : bill.id}',
                    style: textTheme.titleMedium),
                _BillStatusChip(status: bill.status),
              ],
            ),
            const Divider(height: AppTheme.spacing24, color: AppTheme.border),
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
            const Divider(height: AppTheme.spacing16, color: AppTheme.border),
            // Total
            _AmountRow(
              label: 'Total',
              amount: bill.total,
              bold: true,
            ),
            if (bill.payments.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing8),
              ...bill.payments.map((p) => _AmountRow(
                    label: 'Paid (${(p.mode ?? 'unknown').toUpperCase()})',
                    amount: p.amount,
                    muted: true,
                  )),
              const Divider(height: AppTheme.spacing16, color: AppTheme.border),
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

  double _outstanding(Bill bill) {
    final paid = bill.payments.fold<double>(0, (sum, p) => sum + p.amount);
    return (bill.total - paid).clamp(0, double.infinity);
  }
}

// ── Payment Form Card ─────────────────────────────────────────────────────────

/// Simple button to record full payment as cash (temporary until Razorpay integration).
///
/// Requirements: 11.3, 11.4, 11.5, 11.6
class _PaymentFormCard extends StatefulWidget {
  const _PaymentFormCard({required this.bill});

  final Bill bill;

  @override
  State<_PaymentFormCard> createState() => _PaymentFormCardState();
}

class _PaymentFormCardState extends State<_PaymentFormCard> {
  bool _submitting = false;

  double get _outstanding {
    final paid =
        widget.bill.payments.fold<double>(0, (sum, p) => sum + p.amount);
    return (widget.bill.total - paid).clamp(0, double.infinity);
  }

  void _submit() {
    setState(() => _submitting = true);
    // Directly record payment with full outstanding amount using cash
    context.read<BillingBloc>().add(BillPaymentRequested(
          billId: widget.bill.id,
          mode: 'cash',
          amount: _outstanding,
        ));
    context.read<BillingBloc>().stream.first.then((_) {
      if (mounted) setState(() => _submitting = false);
    });
  }

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
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Record Payment',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Amount: ₹${_outstanding.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Payment will be recorded as cash',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.onPrimary),
                      )
                    : const Icon(Icons.payment_outlined),
                label: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
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
