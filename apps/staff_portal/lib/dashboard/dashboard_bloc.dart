import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'dashboard_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

sealed class DashboardEvent {
  const DashboardEvent();
}

final class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

final class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

final class _DashboardPolled extends DashboardEvent {
  const _DashboardPolled();
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class DashboardState {
  const DashboardState();
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.stats,
    required this.activeOrders,
    this.tables = const [],
  });
  final DashboardStats stats;
  final List<Order> activeOrders;
  final List<Table> tables;
}

/// Stats loaded but orders failed (or vice versa).
final class DashboardPartialError extends DashboardState {
  const DashboardPartialError({
    this.stats,
    this.activeOrders,
    this.tables = const [],
    this.statsError,
    this.ordersError,
  });
  final DashboardStats? stats;
  final List<Order>? activeOrders;
  final List<Table> tables;
  final String? statsError;
  final String? ordersError;
}

final class DashboardError extends DashboardState {
  const DashboardError({required this.message});
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

/// Manages dashboard data and 60-second polling.
///
/// Requirements: 5.1, 5.2, 5.4, 5.5, 5.6, 5.7
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required DashboardRepository repository})
      : _repo = repository,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
    on<_DashboardPolled>(_onPolled);
  }

  final DashboardRepository _repo;
  StreamSubscription<void>? _pollSub;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _fetchAll(emit);
    _startPolling();
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchAll(emit);
  }

  Future<void> _onPolled(
    _DashboardPolled event,
    Emitter<DashboardState> emit,
  ) async {
    // Silent refresh — only update if we already have data.
    if (state is DashboardLoaded || state is DashboardPartialError) {
      await _fetchAll(emit);
    }
  }

  // ── Data fetch ─────────────────────────────────────────────────────────────

  /// Fetches stats, orders, and tables in parallel; emits appropriate state.
  Future<void> _fetchAll(Emitter<DashboardState> emit) async {
    final results = await Future.wait([
      _repo.getSummaryStats().then<Object?>((v) => v).catchError((e) => e),
      _repo.getActiveOrders().then<Object?>((v) => v).catchError((e) => e),
      _repo.getTables().then<Object?>((v) => v).catchError((_) => <Table>[]),
    ]);

    final statsResult = results[0];
    final ordersResult = results[1];
    final tablesResult = results[2];

    final stats = statsResult is DashboardStats ? statsResult : null;
    final orders = ordersResult is List<Order> ? ordersResult : null;
    final tables = tablesResult is List<Table> ? tablesResult : <Table>[];

    final statsError = statsResult is ApiException
        ? statsResult.message
        : statsResult is Exception
            ? statsResult.toString()
            : null;

    final ordersError = ordersResult is ApiException
        ? ordersResult.message
        : ordersResult is Exception
            ? ordersResult.toString()
            : null;

    if (stats != null && orders != null) {
      emit(DashboardLoaded(stats: stats, activeOrders: orders, tables: tables));
    } else {
      emit(DashboardPartialError(
        stats: stats,
        activeOrders: orders,
        tables: tables,
        statsError: statsError,
        ordersError: ordersError,
      ));
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  /// Starts 60-second polling (Requirement 5.7).
  void _startPolling() {
    _pollSub?.cancel();
    _pollSub = Stream.periodic(const Duration(seconds: 60))
        .listen((_) => add(const _DashboardPolled()));
  }

  @override
  Future<void> close() {
    _pollSub?.cancel();
    return super.close();
  }
}
