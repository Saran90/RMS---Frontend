// Feature: rms-flutter-frontend
// Implements: Reservation list with disable + edit capabilities.

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:staff_portal/reservation/reservation_bloc.dart';
import 'package:staff_portal/reservation/reservation_repository.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const _kPageBg = Color(0xFFF5F0E8);
const _kCardBg = Color(0xFFFFFFFF);
const _kAccent = Color(0xFFE87020);
const _kActive = Color(0xFF00B4D8);
const _kSeated = Color(0xFF00BFA5);
const _kCancelled = Color(0xFFF5A623);
const _kDisabled = Color(0xFF9CA3AF);
const _kNoShow = Color(0xFFEF4444);
const _kCompleted = Color(0xFF6B7280);

Color _statusColor(ReservationStatus s) => switch (s) {
      ReservationStatus.active => _kActive,
      ReservationStatus.seated => _kSeated,
      ReservationStatus.cancelled => _kCancelled,
      ReservationStatus.disabled => _kDisabled,
      ReservationStatus.noShow => _kNoShow,
      ReservationStatus.completed => _kCompleted,
    };

String _statusLabel(ReservationStatus s) => switch (s) {
      ReservationStatus.active => 'Active',
      ReservationStatus.seated => 'Seated',
      ReservationStatus.cancelled => 'Cancelled',
      ReservationStatus.disabled => 'Disabled',
      ReservationStatus.noShow => 'No-show',
      ReservationStatus.completed => 'Completed',
    };

// ── Screen ───────────────────────────────────────────────────────────────────

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the initial load (the bloc itself is provided globally).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<ReservationBloc>().state;
      if (state is ReservationInitial) {
        context.read<ReservationBloc>().add(const ReservationsLoadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _ReservationsView();
  }
}

class _ReservationsView extends StatelessWidget {
  const _ReservationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: BlocConsumer<ReservationBloc, ReservationState>(
        listenWhen: (prev, curr) =>
            curr is ReservationLoaded && curr.lastDisableId != null,
        listener: (context, state) {
          if (state is ReservationLoaded && state.lastDisableId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reservation disabled'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: _kAccent,
              ),
            );
          }
        },
        builder: (context, state) => switch (state) {
          ReservationInitial() ||
          ReservationLoading() =>
            const Center(child: CircularProgressIndicator()),
          ReservationError(:final message) => ErrorStateWidget(
              message: message,
              onRetry: () => context
                  .read<ReservationBloc>()
                  .add(const ReservationsLoadRequested()),
            ),
          ReservationLoaded(
            :final reservations,
            :final statusFilter,
            :final refreshError,
          ) =>
            _ReservationsBody(
              reservations: reservations,
              statusFilter: statusFilter,
              refreshError: refreshError,
            ),
          ReservationOperationError(
            :final reservations,
            :final message,
          ) =>
            Column(
              children: [
                _ErrorBanner(message: message),
                Expanded(
                  child: _ReservationsBody(
                    reservations: reservations,
                    statusFilter: null,
                    refreshError: null,
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _ReservationsBody extends StatelessWidget {
  const _ReservationsBody({
    required this.reservations,
    required this.statusFilter,
    required this.refreshError,
  });
  final List<Reservation> reservations;
  final ReservationStatus? statusFilter;
  final String? refreshError;

  @override
  Widget build(BuildContext context) {
    final filtered = statusFilter == null
        ? reservations
        : reservations.where((r) => r.status == statusFilter).toList();
    // Sort: active first, then by reservedFor ascending
    filtered.sort((a, b) {
      if (a.status == ReservationStatus.active &&
          b.status != ReservationStatus.active) return -1;
      if (b.status == ReservationStatus.active &&
          a.status != ReservationStatus.active) return 1;
      return a.reservedFor.compareTo(b.reservedFor);
    });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _PageHeader(
            currentFilter: statusFilter,
            onFilterChanged: (f) => context
                .read<ReservationBloc>()
                .add(ReservationsLoadRequested(statusFilter: f)),
            onRefresh: () => context
                .read<ReservationBloc>()
                .add(const ReservationsLoadRequested()),
          ),
        ),
        if (refreshError != null)
          SliverToBoxAdapter(child: _ErrorBanner(message: refreshError!)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          sliver: filtered.isEmpty
              ? const SliverToBoxAdapter(child: _EmptyState())
              : SliverList.separated(
                  itemBuilder: (_, i) => _ReservationCard(
                    reservation: filtered[i],
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: filtered.length,
                ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onRefresh,
  });
  final ReservationStatus? currentFilter;
  final ValueChanged<ReservationStatus?> onFilterChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reservations',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
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
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: currentFilter == null,
                  onSelected: () => onFilterChanged(null),
                ),
                const SizedBox(width: 8),
                ...ReservationStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: _statusLabel(s),
                      color: _statusColor(s),
                      selected: currentFilter == s,
                      onSelected: () => onFilterChanged(s),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? _kAccent;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : AppTheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM • h:mm a');
    final color = _statusColor(reservation.status);
    final isDisabled = reservation.status == ReservationStatus.disabled;

    return Semantics(
      label:
          'Reservation for ${reservation.guestName}, table ${reservation.tableNumber ?? reservation.tableId}, ${_statusLabel(reservation.status)}',
      button: true,
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: () => _showReservationSheet(context, reservation),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? AppTheme.border
                    : color.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      reservation.tableNumber ?? '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reservation.guestName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDisabled
                                    ? AppTheme.mutedText
                                    : AppTheme.onSurface,
                                decoration: isDisabled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _statusLabel(reservation.status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 13, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              fmt.format(reservation.reservedFor),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              size: 13, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Text(
                            reservation.guestPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.people_outline,
                              size: 13, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Text(
                            '${reservation.partySize}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.event_available_outlined,
              size: 56, color: AppTheme.mutedText),
          const SizedBox(height: AppTheme.spacing12),
          Text('No reservations',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.mutedText)),
          const SizedBox(height: AppTheme.spacing8),
          Text('Bookings will appear here',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.mutedText)),
        ]),
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
      width: double.infinity,
      color: AppTheme.error.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppTheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet ─────────────────────────────────────────────────────────────

void _showReservationSheet(BuildContext context, Reservation reservation) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => BlocProvider.value(
      value: context.read<ReservationBloc>(),
      child: _ReservationBottomSheet(reservation: reservation),
    ),
  );
}

class _ReservationBottomSheet extends StatelessWidget {
  const _ReservationBottomSheet({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM • h:mm a');
    final isDisabled = reservation.status == ReservationStatus.disabled;

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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: Text(
                  reservation.guestName,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _statusColor(reservation.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(reservation.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(reservation.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _DetailRow(
            icon: Icons.table_restaurant_outlined,
            label: 'Table',
            value: reservation.tableNumber ?? reservation.tableId,
          ),
          _DetailRow(
            icon: Icons.phone,
            label: 'Phone',
            value: reservation.guestPhone,
          ),
          _DetailRow(
            icon: Icons.people_outline,
            label: 'Party size',
            value: '${reservation.partySize} guests',
          ),
          _DetailRow(
            icon: Icons.schedule,
            label: 'Reserved for',
            value: fmt.format(reservation.reservedFor),
          ),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'Reserved until',
            value: fmt.format(reservation.reservedUntil),
          ),
          if (reservation.notes != null && reservation.notes!.isNotEmpty)
            _DetailRow(
              icon: Icons.notes,
              label: 'Notes',
              value: reservation.notes!,
            ),
          const SizedBox(height: AppTheme.spacing24),

          // ── Actions ──────────────────────────────────────────────────────
          if (!isDisabled) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.cardSurface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => BlocProvider.value(
                    value: context.read<ReservationBloc>(),
                    child: _EditReservationSheet(reservation: reservation),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Reservation'),
            ),
            const SizedBox(height: AppTheme.spacing8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _kDisabled,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmDisable(context, reservation),
              icon: const Icon(Icons.block),
              label: const Text('Disable Reservation'),
            ),
          ] else ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context
                    .read<ReservationBloc>()
                    .add(ReservationEnableRequested(id: reservation.id));
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Re-enable Reservation'),
            ),
          ],
          const SizedBox(height: AppTheme.spacing8),
        ],
      ),
    );
  }

  void _confirmDisable(BuildContext context, Reservation r) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Disable the reservation for ${r.guestName}? The table will be released back to the available pool. The record is preserved for audit and can be re-enabled later.',
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Guest cancelled, double-booking, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
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
              context.read<ReservationBloc>().add(
                    ReservationDisableRequested(
                      id: r.id,
                      reason: reasonCtrl.text.trim().isEmpty
                          ? null
                          : reasonCtrl.text.trim(),
                    ),
                  );
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.mutedText),
          const SizedBox(width: AppTheme.spacing8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit sheet ───────────────────────────────────────────────────────────────

class _EditReservationSheet extends StatefulWidget {
  const _EditReservationSheet({required this.reservation});
  final Reservation reservation;

  @override
  State<_EditReservationSheet> createState() => _EditReservationSheetState();
}

class _EditReservationSheetState extends State<_EditReservationSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _partyCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _reservedFor;
  late DateTime _reservedUntil;
  bool _loading = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.reservation.guestName);
    _phoneCtrl = TextEditingController(text: widget.reservation.guestPhone);
    _partyCtrl =
        TextEditingController(text: widget.reservation.partySize.toString());
    _notesCtrl = TextEditingController(text: widget.reservation.notes ?? '');
    _reservedFor = widget.reservation.reservedFor;
    _reservedUntil = widget.reservation.reservedUntil;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _partyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final initial = isStart ? _reservedFor : _reservedUntil;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _reservedFor = dt;
        if (!_reservedUntil.isAfter(_reservedFor)) {
          _reservedUntil = _reservedFor.add(const Duration(hours: 2));
        }
      } else {
        _reservedUntil = dt;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_reservedUntil.isAfter(_reservedFor)) {
      setState(() => _error = 'End time must be after start time');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    context.read<ReservationBloc>().add(ReservationEditRequested(
          id: widget.reservation.id,
          guestName: _nameCtrl.text.trim(),
          guestPhone: _phoneCtrl.text.trim(),
          partySize: int.parse(_partyCtrl.text.trim()),
          reservedFor: _reservedFor,
          reservedUntil: _reservedUntil,
          notes: _notesCtrl.text.trim(),
        ));
    context.read<ReservationBloc>().stream.first.then((s) {
      if (!mounted) return;
      if (s is ReservationOperationError) {
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
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('h:mm a');
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing24,
        top: AppTheme.spacing16,
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              Text('Edit Reservation',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacing16),
              if (_error != null) ...[
                _FormError(message: _error!),
                const SizedBox(height: AppTheme.spacing12),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Guest name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) return 'Invalid phone';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _partyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  labelText: 'Party size *',
                  prefixIcon: Icon(Icons.people_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Min 1';
                  if (n > 50) return 'Max 50';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              Row(
                children: [
                  Expanded(
                    child: _DateTimeField(
                      label: 'Start',
                      value:
                          '${dateFmt.format(_reservedFor)}\n${timeFmt.format(_reservedFor)}',
                      onTap: () => _pickDateTime(true),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: _DateTimeField(
                      label: 'End',
                      value:
                          '${dateFmt.format(_reservedUntil)}\n${timeFmt.format(_reservedUntil)}',
                      onTap: () => _pickDateTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.event_outlined, size: 18),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 12, height: 1.4),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppTheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
