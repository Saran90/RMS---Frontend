import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'reservation_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

sealed class ReservationEvent {
  const ReservationEvent();
}

/// Load the list of reservations, optionally filtered.
final class ReservationsLoadRequested extends ReservationEvent {
  const ReservationsLoadRequested({this.statusFilter, this.includeDisabled = true});
  final ReservationStatus? statusFilter;
  final bool includeDisabled;
}

/// Reload with the previously-applied filter (used after operations).
final class ReservationsRefreshRequested extends ReservationEvent {
  const ReservationsRefreshRequested();
}

/// Create a new reservation for an available table.
final class ReservationCreateRequested extends ReservationEvent {
  const ReservationCreateRequested({
    required this.tableId,
    required this.guestName,
    required this.guestPhone,
    required this.reservedFor,
    required this.reservedUntil,
    this.partySize = 2,
    this.additionalTableIds = const [],
    this.notes,
  });
  final String tableId;
  final String guestName;
  final String guestPhone;
  final DateTime reservedFor;
  final DateTime reservedUntil;
  final int partySize;
  final List<String> additionalTableIds;
  final String? notes;
}

/// Edit a reservation's core fields (name, phone, party size, time window).
final class ReservationEditRequested extends ReservationEvent {
  const ReservationEditRequested({
    required this.id,
    this.guestName,
    this.guestPhone,
    this.partySize,
    this.reservedFor,
    this.reservedUntil,
    this.notes,
  });
  final String id;
  final String? guestName;
  final String? guestPhone;
  final int? partySize;
  final DateTime? reservedFor;
  final DateTime? reservedUntil;
  final String? notes;
}

/// Release a reservation early and free the table.
final class ReservationReleaseRequested extends ReservationEvent {
  const ReservationReleaseRequested({required this.id});
  final String id;
}

/// Disable a reservation (soft-delete; preserved for audit).
final class ReservationDisableRequested extends ReservationEvent {
  const ReservationDisableRequested({required this.id, this.reason});
  final String id;
  final String? reason;
}

/// Re-enable a previously disabled reservation.
final class ReservationEnableRequested extends ReservationEvent {
  const ReservationEnableRequested({required this.id});
  final String id;
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class ReservationState {
  const ReservationState();
}

final class ReservationInitial extends ReservationState {
  const ReservationInitial();
}

final class ReservationLoading extends ReservationState {
  const ReservationLoading();
}

final class ReservationLoaded extends ReservationState {
  const ReservationLoaded({
    required this.reservations,
    this.history = const [],
    this.statusFilter,
    this.refreshError,
    this.lastDisableId,
    this.lastCreateId,
    this.lastReleaseId,
  });
  final List<Reservation> reservations;
  final List<Reservation> history;
  final ReservationStatus? statusFilter;
  final String? refreshError;

  /// ID of the most recently disabled reservation, used to surface a
  /// success snackbar in the UI without having to thread an event back.
  final String? lastDisableId;

  /// ID of the most recently created reservation.
  final String? lastCreateId;

  /// ID of the most recently released reservation.
  final String? lastReleaseId;

  ReservationLoaded copyWith({
    List<Reservation>? reservations,
    List<Reservation>? history,
    ReservationStatus? statusFilter,
    bool clearStatusFilter = false,
    String? refreshError,
    bool clearRefreshError = false,
    String? lastDisableId,
    bool clearLastDisableId = false,
    String? lastCreateId,
    bool clearLastCreateId = false,
    String? lastReleaseId,
    bool clearLastReleaseId = false,
  }) {
    return ReservationLoaded(
      reservations: reservations ?? this.reservations,
      history: history ?? this.history,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      refreshError:
          clearRefreshError ? null : (refreshError ?? this.refreshError),
      lastDisableId:
          clearLastDisableId ? null : (lastDisableId ?? this.lastDisableId),
      lastCreateId:
          clearLastCreateId ? null : (lastCreateId ?? this.lastCreateId),
      lastReleaseId:
          clearLastReleaseId ? null : (lastReleaseId ?? this.lastReleaseId),
    );
  }
}

final class ReservationError extends ReservationState {
  const ReservationError(this.message);
  final String message;
}

final class ReservationOperationError extends ReservationState {
  const ReservationOperationError({
    required this.reservations,
    required this.message,
  });
  final List<Reservation> reservations;
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  ReservationBloc({required ReservationRepository repository})
      : _repo = repository,
        super(const ReservationInitial()) {
    on<ReservationsLoadRequested>(_onLoad);
    on<ReservationsRefreshRequested>(_onRefresh);
    on<ReservationCreateRequested>(_onCreate);
    on<ReservationEditRequested>(_onEdit);
    on<ReservationReleaseRequested>(_onRelease);
    on<ReservationDisableRequested>(_onDisable);
    on<ReservationEnableRequested>(_onEnable);
  }

  final ReservationRepository _repo;

  Future<({List<Reservation> reservations, List<Reservation> history})>
      _loadLists(ReservationStatus? filter) async {
    final reservations = await _repo.getReservations(status: filter);
    final history = await _repo.getReservationHistory();
    return (reservations: reservations, history: history);
  }

  Future<void> _onLoad(
    ReservationsLoadRequested e,
    Emitter<ReservationState> emit,
  ) async {
    emit(const ReservationLoading());
    try {
      final data = await _loadLists(e.statusFilter);
      // If we're not including disabled, filter client-side too.
      final filtered = e.includeDisabled
          ? data.reservations
          : data.reservations
              .where((r) => r.status != ReservationStatus.disabled)
              .toList();
      emit(ReservationLoaded(
        reservations: filtered,
        history: data.history,
        statusFilter: e.statusFilter,
      ));
    } on ApiException catch (ex) {
      emit(ReservationError(ex.message));
    } catch (ex) {
      emit(ReservationError(ex.toString()));
    }
  }

  Future<void> _onRefresh(
    ReservationsRefreshRequested e,
    Emitter<ReservationState> emit,
  ) async {
    final filter = state is ReservationLoaded
        ? (state as ReservationLoaded).statusFilter
        : null;
    try {
      final data = await _loadLists(filter);
      emit(ReservationLoaded(
        reservations: data.reservations,
        history: data.history,
        statusFilter: filter,
      ));
    } on ApiException catch (ex) {
      final current = state is ReservationLoaded
          ? (state as ReservationLoaded).reservations
          : <Reservation>[];
      emit(ReservationOperationError(
        reservations: current,
        message: ex.message,
      ));
    } catch (ex) {
      final current = state is ReservationLoaded
          ? (state as ReservationLoaded).reservations
          : <Reservation>[];
      emit(ReservationOperationError(
        reservations: current,
        message: ex.toString(),
      ));
    }
  }

  Future<void> _onCreate(
    ReservationCreateRequested e,
    Emitter<ReservationState> emit,
  ) async {
    final filter = state is ReservationLoaded
        ? (state as ReservationLoaded).statusFilter
        : null;
  final current = state is ReservationLoaded
      ? (state as ReservationLoaded).reservations
      : <Reservation>[];
    try {
      final created = await _repo.createReservation(
        tableId: e.tableId,
        guestName: e.guestName,
        guestPhone: e.guestPhone,
        reservedFor: e.reservedFor,
        reservedUntil: e.reservedUntil,
        partySize: e.partySize,
        additionalTableIds: e.additionalTableIds,
        notes: e.notes,
      );
      final data = await _loadLists(filter);
      emit(ReservationLoaded(
        reservations: data.reservations,
        history: data.history,
        statusFilter: filter,
        lastCreateId: created.id,
      ));
    } on ApiException catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.message,
      ));
    } catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.toString(),
      ));
    }
  }

  Future<void> _onEdit(
    ReservationEditRequested e,
    Emitter<ReservationState> emit,
  ) async {
    final current = state is ReservationLoaded
        ? (state as ReservationLoaded).reservations
        : <Reservation>[];
    try {
      final updated = await _repo.updateReservation(
        e.id,
        guestName: e.guestName,
        guestPhone: e.guestPhone,
        partySize: e.partySize,
        reservedFor: e.reservedFor,
        reservedUntil: e.reservedUntil,
        notes: e.notes,
      );
      final newList =
          current.map((r) => r.id == e.id ? updated : r).toList();
      emit(ReservationLoaded(
        reservations: newList,
        statusFilter: state is ReservationLoaded
            ? (state as ReservationLoaded).statusFilter
            : null,
      ));
    } on ApiException catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.message,
      ));
    } catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.toString(),
      ));
    }
  }

  Future<void> _onRelease(
    ReservationReleaseRequested e,
    Emitter<ReservationState> emit,
  ) async {
    final filter = state is ReservationLoaded
        ? (state as ReservationLoaded).statusFilter
        : null;
    final current = state is ReservationLoaded
        ? (state as ReservationLoaded).reservations
        : <Reservation>[];
    try {
      await _repo.releaseReservation(e.id);
      final data = await _loadLists(filter);
      emit(ReservationLoaded(
        reservations: data.reservations,
        history: data.history,
        statusFilter: filter,
        lastReleaseId: e.id,
      ));
    } on ApiException catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.message,
      ));
    } catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.toString(),
      ));
    }
  }

  Future<void> _onDisable(
    ReservationDisableRequested e,
    Emitter<ReservationState> emit,
  ) async {
    final current = state is ReservationLoaded
        ? (state as ReservationLoaded).reservations
        : <Reservation>[];
    try {
      await _repo.releaseReservation(e.id);
      final filter = state is ReservationLoaded
          ? (state as ReservationLoaded).statusFilter
          : null;
      final data = await _loadLists(filter);
      emit(ReservationLoaded(
        reservations: data.reservations,
        history: data.history,
        statusFilter: filter,
        lastDisableId: e.id,
      ));
    } on ApiException catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.message,
      ));
    } catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.toString(),
      ));
    }
  }

  Future<void> _onEnable(
    ReservationEnableRequested e,
    Emitter<ReservationState> emit,
  ) async {
    final current = state is ReservationLoaded
        ? (state as ReservationLoaded).reservations
        : <Reservation>[];
    try {
      final updated = await _repo.enableReservation(e.id);
      final newList =
          current.map((r) => r.id == e.id ? updated : r).toList();
      emit(ReservationLoaded(
        reservations: newList,
        statusFilter: state is ReservationLoaded
            ? (state as ReservationLoaded).statusFilter
            : null,
      ));
    } on ApiException catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.message,
      ));
    } catch (ex) {
      emit(ReservationOperationError(
        reservations: current,
        message: ex.toString(),
      ));
    }
  }
}
