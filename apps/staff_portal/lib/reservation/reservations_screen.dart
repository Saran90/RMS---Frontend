// Feature: rms-flutter-frontend
// Implements: Reservation list with disable + edit capabilities.

import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:staff_portal/reservation/reservation_bloc.dart';
import 'package:staff_portal/tables/table_repository.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const _kPageBg = Color(0xFFF5F0E8);
const _kCardBg = Color(0xFFFFFFFF);
const _kAccent = Color(0xFFE87020);
const _kActive = Color(0xFF00B4D8);
const _kOccupied = Color(0xFFF5A623);
const _kSeated = Color(0xFF00BFA5);
const _kCancelled = Color(0xFFEF4444);
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

String _lifecycleLabel(Reservation r) {
  // Terminal statuses win over time-window heuristics (history entries stay
  // in-window after early cancel).
  switch (r.status) {
    case ReservationStatus.cancelled:
      return 'Cancelled';
    case ReservationStatus.completed:
      return 'Completed';
    case ReservationStatus.disabled:
      return 'Disabled';
    case ReservationStatus.noShow:
      return 'No-show';
    case ReservationStatus.seated:
      return 'Seated';
    case ReservationStatus.active:
      break;
  }
  if (r.isUpcoming) return 'Upcoming';
  if (r.isInReservationWindow ||
      r.tableStatus == TableStatus.occupied ||
      r.tableStatus == TableStatus.reserved) {
    return 'Active';
  }
  return _statusLabel(r.status);
}

Color _lifecycleColor(Reservation r) {
  switch (r.status) {
    case ReservationStatus.cancelled:
      return _kCancelled;
    case ReservationStatus.completed:
      return _kCompleted;
    case ReservationStatus.disabled:
      return _kDisabled;
    case ReservationStatus.noShow:
      return _kNoShow;
    case ReservationStatus.seated:
      return _kSeated;
    case ReservationStatus.active:
      break;
  }
  if (r.isUpcoming) return const Color(0xFF8B5CF6);
  if (r.isInReservationWindow ||
      r.tableStatus == TableStatus.occupied ||
      r.tableStatus == TableStatus.reserved) {
    return _kOccupied;
  }
  return _statusColor(r.status);
}

// ── Screen ───────────────────────────────────────────────────────────────────

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  Timer? _refreshTimer;

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
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<ReservationBloc>().add(const ReservationsRefreshRequested());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
            curr is ReservationLoaded &&
            (curr.lastDisableId != null ||
                curr.lastCreateId != null ||
                curr.lastReleaseId != null),
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
          if (state is ReservationLoaded && state.lastCreateId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reservation created'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: _kAccent,
              ),
            );
          }
          if (state is ReservationLoaded && state.lastReleaseId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reservation cancelled'),
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
            :final history,
            :final refreshError,
          ) =>
            _ReservationsBody(
              reservations: reservations,
              history: history,
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
                    history: const [],
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

class _ReservationsBody extends StatefulWidget {
  const _ReservationsBody({
    required this.reservations,
    required this.history,
    required this.refreshError,
  });
  final List<Reservation> reservations;
  final List<Reservation> history;
  final String? refreshError;

  @override
  State<_ReservationsBody> createState() => _ReservationsBodyState();
}

enum _UpcomingFilter { all, upcoming, active }

enum _HistoryFilter { all, completed, cancelled }

class _ReservationsBodyState extends State<_ReservationsBody> {
  bool _showHistory = false;
  _UpcomingFilter _upcomingFilter = _UpcomingFilter.all;
  _HistoryFilter _historyFilter = _HistoryFilter.all;

  bool _isActiveReservation(Reservation r) =>
      r.isInReservationWindow ||
      r.tableStatus == TableStatus.occupied ||
      r.tableStatus == TableStatus.reserved;

  bool _isArchivedInHistory(Reservation r) {
    return widget.history.any(
      (h) =>
          h.tableId == r.tableId &&
          h.reservedFor == r.reservedFor &&
          h.reservedUntil == r.reservedUntil,
    );
  }

  bool _belongsInUpcoming(Reservation r) {
    if (r.status == ReservationStatus.cancelled ||
        r.status == ReservationStatus.disabled) {
      return false;
    }
    if (r.isExpired) return false;
    if (_isArchivedInHistory(r)) return false;
    return true;
  }

  List<Reservation> _filterUpcoming(List<Reservation> list) {
    final live = list.where(_belongsInUpcoming).toList();
    switch (_upcomingFilter) {
      case _UpcomingFilter.all:
        return live;
      case _UpcomingFilter.upcoming:
        return live.where((r) => r.isUpcoming).toList();
      case _UpcomingFilter.active:
        return live.where(_isActiveReservation).toList();
    }
  }

  List<Reservation> _filterHistory(List<Reservation> list) {
    switch (_historyFilter) {
      case _HistoryFilter.all:
        return list;
      case _HistoryFilter.completed:
        return list
            .where((r) => r.status == ReservationStatus.completed)
            .toList();
      case _HistoryFilter.cancelled:
        return list
            .where((r) => r.status == ReservationStatus.cancelled)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterUpcoming(widget.reservations);
    filtered.sort((a, b) {
      if (_isActiveReservation(a) && !_isActiveReservation(b)) return -1;
      if (_isActiveReservation(b) && !_isActiveReservation(a)) return 1;
      return a.reservedFor.compareTo(b.reservedFor);
    });

    final historyList = _filterHistory(List<Reservation>.from(widget.history));

    final displayList = _showHistory ? historyList : filtered;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _PageHeader(
            showHistory: _showHistory,
            upcomingFilter: _upcomingFilter,
            historyFilter: _historyFilter,
            onTabChanged: (showHistory) {
              setState(() {
                _showHistory = showHistory;
                _upcomingFilter = _UpcomingFilter.all;
                _historyFilter = _HistoryFilter.all;
              });
              if (showHistory) {
                context
                    .read<ReservationBloc>()
                    .add(const ReservationsRefreshRequested());
              }
            },
            onUpcomingFilterChanged: (f) =>
                setState(() => _upcomingFilter = f),
            onHistoryFilterChanged: (f) =>
                setState(() => _historyFilter = f),
            onRefresh: () => context
                .read<ReservationBloc>()
                .add(const ReservationsRefreshRequested()),
            onCreate: () => _showCreateSheet(context),
          ),
        ),
        if (widget.refreshError != null)
          SliverToBoxAdapter(child: _ErrorBanner(message: widget.refreshError!)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          sliver: displayList.isEmpty
              ? SliverToBoxAdapter(
                  child: _EmptyState(isHistory: _showHistory),
                )
              : SliverList.separated(
                  itemBuilder: (_, i) => _ReservationCard(
                    reservation: displayList[i],
                    showCancelAction: !_showHistory &&
                        (displayList[i].isUpcoming ||
                            _isActiveReservation(displayList[i])),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: displayList.length,
                ),
        ),
      ],
    );
  }
}

void _showCreateSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<ReservationBloc>(),
      child: const _CreateReservationSheet(),
    ),
  );
}

void _confirmCancelReservation(BuildContext context, Reservation r) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel reservation?'),
      content: Text(
        'Cancel the reservation for ${r.guestName.isNotEmpty ? r.guestName : 'this guest'} on ${r.tablesLabel}? All linked tables will be freed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Keep'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).maybePop();
            context.read<ReservationBloc>().add(
                  ReservationReleaseRequested(id: r.id),
                );
          },
          child: const Text('Cancel Reservation'),
        ),
      ],
    ),
  );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.showHistory,
    required this.upcomingFilter,
    required this.historyFilter,
    required this.onTabChanged,
    required this.onUpcomingFilterChanged,
    required this.onHistoryFilterChanged,
    required this.onRefresh,
    required this.onCreate,
  });
  final bool showHistory;
  final _UpcomingFilter upcomingFilter;
  final _HistoryFilter historyFilter;
  final ValueChanged<bool> onTabChanged;
  final ValueChanged<_UpcomingFilter> onUpcomingFilterChanged;
  final ValueChanged<_HistoryFilter> onHistoryFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

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
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_outlined, size: 22),
                color: AppTheme.mutedText,
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterChip(
                label: 'Upcoming',
                selected: !showHistory,
                onSelected: () => onTabChanged(false),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'History',
                selected: showHistory,
                onSelected: () => onTabChanged(true),
              ),
            ],
          ),
          if (!showHistory) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: upcomingFilter == _UpcomingFilter.all,
                    onSelected: () =>
                        onUpcomingFilterChanged(_UpcomingFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Upcoming',
                    color: const Color(0xFF8B5CF6),
                    selected: upcomingFilter == _UpcomingFilter.upcoming,
                    onSelected: () =>
                        onUpcomingFilterChanged(_UpcomingFilter.upcoming),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    color: _kOccupied,
                    selected: upcomingFilter == _UpcomingFilter.active,
                    onSelected: () =>
                        onUpcomingFilterChanged(_UpcomingFilter.active),
                  ),
                ],
              ),
            ),
          ],
          if (showHistory) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: historyFilter == _HistoryFilter.all,
                    onSelected: () =>
                        onHistoryFilterChanged(_HistoryFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completed',
                    color: _kCompleted,
                    selected: historyFilter == _HistoryFilter.completed,
                    onSelected: () =>
                        onHistoryFilterChanged(_HistoryFilter.completed),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Cancelled',
                    color: _kCancelled,
                    selected: historyFilter == _HistoryFilter.cancelled,
                    onSelected: () =>
                        onHistoryFilterChanged(_HistoryFilter.cancelled),
                  ),
                ],
              ),
            ),
          ],
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
  const _ReservationCard({
    required this.reservation,
    this.showCancelAction = false,
  });
  final Reservation reservation;
  final bool showCancelAction;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM • h:mm a');
    final color = _lifecycleColor(reservation);
    final label = _lifecycleLabel(reservation);
    final isDisabled = reservation.status == ReservationStatus.disabled;
    final isHistory = reservation.status == ReservationStatus.cancelled ||
        reservation.status == ReservationStatus.completed;
    final endedFmt = DateFormat('EEE, d MMM • h:mm a');

    return Semantics(
      label:
          'Reservation for ${reservation.guestName}, ${reservation.tablesLabel}, $label',
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      reservation.allTableNumbers.length > 1
                          ? '${reservation.allTableNumbers.first}+'
                          : reservation.tableNumber ?? '?',
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
                      Text(
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 13, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isHistory && reservation.updatedAt != null
                                  ? 'Ended ${endedFmt.format(reservation.updatedAt!)}'
                                  : '${fmt.format(reservation.reservedFor)} → ${fmt.format(reservation.reservedUntil)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
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
                            reservation.guestPhone.isNotEmpty
                                ? reservation.guestPhone
                                : 'No phone',
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
                          if (reservation.linkedTableIds.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _kAccent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                reservation.tablesLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _kAccent,
                                ),
                              ),
                            ),
                          ],
                          if (reservation.isOverCapacity) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'Needs ${reservation.tablesNeeded} tables',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    if (showCancelAction) ...[
                      const SizedBox(height: 8),
                      _CancelReservationButton(
                        onPressed: () =>
                            _confirmCancelReservation(context, reservation),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppTheme.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelReservationButton extends StatelessWidget {
  const _CancelReservationButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kCancelled.withValues(alpha: 0.35)),
            color: _kCancelled.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded, size: 14, color: _kCancelled),
              const SizedBox(width: 4),
              Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kCancelled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.isHistory = false});
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.event_available_outlined,
              size: 56, color: AppTheme.mutedText),
          const SizedBox(height: AppTheme.spacing12),
          Text(isHistory ? 'No past reservations' : 'No reservations',
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
    final canManage = reservation.status == ReservationStatus.active;
    final lifecycleLabel = _lifecycleLabel(reservation);
    final lifecycleColor = _lifecycleColor(reservation);
    final guestName = reservation.guestName.isNotEmpty
        ? reservation.guestName
        : 'Guest';
    final guestPhone = reservation.guestPhone.isNotEmpty
        ? reservation.guestPhone
        : 'Not provided';

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
                  guestName,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lifecycleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  lifecycleLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: lifecycleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _DetailRow(
            icon: Icons.table_restaurant_outlined,
            label: 'Table',
            value: reservation.tablesLabel,
          ),
          _DetailRow(
            icon: Icons.phone,
            label: 'Phone',
            value: guestPhone,
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
          if (canManage) ...[
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
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
              ),
              onPressed: () => _confirmCancelReservation(context, reservation),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Reservation'),
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

// ── Create sheet ─────────────────────────────────────────────────────────────

class _CreateReservationSheet extends StatefulWidget {
  const _CreateReservationSheet();

  @override
  State<_CreateReservationSheet> createState() =>
      _CreateReservationSheetState();
}

class _CreateReservationSheetState extends State<_CreateReservationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _partyCtrl;
  int _mode = 0;
  DateTime? _reservedFor;
  DateTime? _reservedUntil;
  String? _selectedTableId;
  Set<String> _additionalTableIds = {};
  List<Table> _tables = [];
  bool _loadingTables = true;
  String? _tablesError;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _partyCtrl = TextEditingController(text: '2');
    _loadTables();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _partyCtrl.dispose();
    super.dispose();
  }

  Table? get _selectedTable {
    if (_selectedTableId == null) return null;
    for (final t in _tables) {
      if (t.id == _selectedTableId) return t;
    }
    return null;
  }

  int get _partySize => int.tryParse(_partyCtrl.text.trim()) ?? 0;

  int _tableCapacity(Table t) => t.capacity ?? 4;

  bool get _exceedsTableCapacity {
    final table = _selectedTable;
    if (table == null || _partySize <= 0) return false;
    return _partySize > _tableCapacity(table);
  }

  int get _tablesNeeded {
    final table = _selectedTable;
    if (table == null || _partySize <= 0) return 1;
    final cap = _tableCapacity(table);
    return (_partySize / cap).ceil();
  }

  int get _totalSelectedCapacity {
    final primary = _selectedTable;
    if (primary == null) return 0;
    var cap = _tableCapacity(primary);
    for (final id in _additionalTableIds) {
      final t = _tables.where((x) => x.id == id).firstOrNull;
      if (t != null) cap += _tableCapacity(t);
    }
    return cap;
  }

  List<Table> get _candidateAdditionalTables =>
      _tables.where((t) => t.id != _selectedTableId).toList();

  void _suggestAdditionalTables() {
    if (_tablesNeeded <= 1) {
      _additionalTableIds = {};
      return;
    }
    final need = _tablesNeeded - 1;
    _additionalTableIds =
        _candidateAdditionalTables.take(need).map((t) => t.id).toSet();
  }

  void _toggleAdditionalTable(String tableId) {
    setState(() {
      if (_additionalTableIds.contains(tableId)) {
        _additionalTableIds.remove(tableId);
      } else {
        _additionalTableIds.add(tableId);
      }
    });
  }

  Future<void> _loadTables() async {
    try {
      final tables = await context.read<TableRepository>().getTables();
      final available = tables
          .where((t) =>
              t.status == TableStatus.available && t.reservedFor == null)
          .toList();
      available.sort((a, b) {
        final an = int.tryParse(a.tableNumber) ?? 0;
        final bn = int.tryParse(b.tableNumber) ?? 0;
        return an.compareTo(bn);
      });
      if (!mounted) return;
      setState(() {
        _tables = available;
        _loadingTables = false;
        if (available.isNotEmpty) {
          _selectedTableId = available.first.id;
          _suggestAdditionalTables();
        }
      });
    } catch (ex) {
      if (!mounted) return;
      setState(() {
        _loadingTables = false;
        _tablesError = ex.toString();
      });
    }
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
        isStart ? now : now.add(const Duration(hours: 2)),
      ),
    );
    if (time == null || !mounted) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _reservedFor = dt;
        if (_reservedUntil != null && !_reservedUntil!.isAfter(dt)) {
          _reservedUntil = dt.add(const Duration(hours: 2));
        }
      } else {
        _reservedUntil = dt;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTableId == null) {
      setState(() => _error = 'Please select a table');
      return;
    }

    if (_tablesNeeded > 1 &&
        _additionalTableIds.length < _tablesNeeded - 1) {
      setState(() =>
          _error = 'Select ${_tablesNeeded - 1} additional table(s) for this party');
      return;
    }
    if (_partySize > _totalSelectedCapacity) {
      setState(() => _error =
          'Selected tables seat $_totalSelectedCapacity guests — need $_partySize');
      return;
    }

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
      reservedFor = _reservedFor!;
      reservedUntil = _reservedUntil!;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    context.read<ReservationBloc>().add(ReservationCreateRequested(
          tableId: _selectedTableId!,
          guestName: _nameCtrl.text.trim(),
          guestPhone: _phoneCtrl.text.trim(),
          reservedFor: reservedFor,
          reservedUntil: reservedUntil,
          partySize: _partySize,
          additionalTableIds: _additionalTableIds.toList(),
        ));
    context.read<ReservationBloc>().stream.first.then((s) {
      if (!mounted) return;
      if (s is ReservationOperationError) {
        setState(() {
          _loading = false;
          _error = s.message;
        });
      } else if (s is ReservationLoaded && s.lastCreateId != null) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM');
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
              Text('New Reservation',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacing16),
              if (_error != null) ...[
                _FormError(message: _error!),
                const SizedBox(height: AppTheme.spacing12),
              ],
              if (_loadingTables)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_tablesError != null)
                _FormError(message: _tablesError!)
              else if (_tables.isEmpty)
                const _FormError(message: 'No available tables to reserve')
              else ...[
                DropdownButtonFormField<String>(
                  value: _selectedTableId,
                  decoration: const InputDecoration(
                    labelText: 'Table *',
                    prefixIcon: Icon(Icons.table_restaurant_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _tables
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            'Table ${t.tableNumber}'
                            ' · seats ${_tableCapacity(t)}'
                            '${t.sectionLabel != null ? ' · ${t.sectionLabel}' : ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (v) => setState(() {
                            _selectedTableId = v;
                            _suggestAdditionalTables();
                          }),
                ),
                if (_tablesNeeded > 1) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'Additional tables (${_additionalTableIds.length} of '
                    '${_tablesNeeded - 1} selected · '
                    '$_totalSelectedCapacity seats)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _candidateAdditionalTables.map((t) {
                      final selected = _additionalTableIds.contains(t.id);
                      return FilterChip(
                        label: Text(
                          'Table ${t.tableNumber} · ${_tableCapacity(t)} seats',
                        ),
                        selected: selected,
                        onSelected: _loading
                            ? null
                            : (_) => _toggleAdditionalTable(t.id),
                        selectedColor:
                            _kAccent.withValues(alpha: 0.15),
                        checkmarkColor: _kAccent,
                      );
                    }).toList(),
                  ),
                  if (_partySize > _totalSelectedCapacity) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add more tables — $_totalSelectedCapacity seats selected '
                      'for $_partySize guests.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ] else if (_exceedsTableCapacity) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Table ${_selectedTable?.tableNumber ?? ''} seats '
                            '${_tableCapacity(_selectedTable!)}. For $_partySize '
                            'guests, plan for $_tablesNeeded table(s) or choose '
                            'a larger table.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacing12),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _ModeTab(
                        label: 'Right Now',
                        selected: _mode == 0,
                        onTap: () => setState(() => _mode = 0),
                      ),
                      _ModeTab(
                        label: 'Future Time',
                        selected: _mode == 1,
                        onTap: () => setState(() => _mode = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
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
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextFormField(
                  controller: _partyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Number of guests *',
                    prefixIcon: Icon(Icons.people_outline),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 6',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(_suggestAdditionalTables),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Enter at least 1 guest';
                    if (n > 50) return 'Enter a realistic party size';
                    return null;
                  },
                ),
                if (_mode == 1) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTimeField(
                          label: 'From',
                          value: _reservedFor == null
                              ? 'Select start'
                              : '${dateFmt.format(_reservedFor!)}\n${timeFmt.format(_reservedFor!)}',
                          onTap: () => _pickDateTime(true),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: _DateTimeField(
                          label: 'Until',
                          value: _reservedUntil == null
                              ? 'Select end'
                              : '${dateFmt.format(_reservedUntil!)}\n${timeFmt.format(_reservedUntil!)}',
                          onTap: () => _pickDateTime(false),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.spacing16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Reservation'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          margin: const EdgeInsets.all(4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.onSurface : AppTheme.mutedText,
            ),
          ),
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
