import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/reservation/reservation_repository.dart';
import 'package:staff_portal/reservation/table_reservation_deriver.dart';

import 'table_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class TableEvent {
  const TableEvent();
}

final class TablesLoadRequested extends TableEvent {
  const TablesLoadRequested();
}

final class TableStatusUpdateRequested extends TableEvent {
  const TableStatusUpdateRequested({
    required this.id,
    required this.status,
    this.reservation,
  });
  final String id;
  final TableStatus status;
  final TableReservation? reservation;
}

/// Reservation details required when transitioning to [TableStatus.reserved].

final class TableEditRequested extends TableEvent {
  const TableEditRequested({
    required this.id,
    this.tableNumber,
    this.capacity,
    this.sectionLabel,
    this.qrCodeUrl,
  });
  final String id;
  final int? tableNumber;
  final int? capacity;
  final String? sectionLabel;
  final String? qrCodeUrl;
}

final class TableDeleteRequested extends TableEvent {
  const TableDeleteRequested({required this.id});
  final String id;
}

final class TableCreateRequested extends TableEvent {
  const TableCreateRequested({
    required this.tableNumber,
    required this.capacity,
    this.sectionLabel,
    this.qrCodeUrl,
  });
  final int tableNumber;
  final int capacity;
  final String? sectionLabel;
  final String? qrCodeUrl;
}

final class TablesBulkCreateRequested extends TableEvent {
  const TablesBulkCreateRequested({
    required this.count,
    required this.sectionLabel,
    required this.capacity,
    required this.startingNumber,
  });
  final int count;
  final String sectionLabel;
  final int capacity;
  final int startingNumber;
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class TableState {
  const TableState();
}

final class TableInitial extends TableState {
  const TableInitial();
}

final class TableLoading extends TableState {
  const TableLoading();
}

final class TableLoaded extends TableState {
  const TableLoaded({required this.tables, this.refreshError});
  final List<Table> tables;
  final String? refreshError;
}

final class TableError extends TableState {
  const TableError(this.message);
  final String message;
}

final class TableOperationError extends TableState {
  const TableOperationError({required this.tables, required this.message});
  final List<Table> tables;
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.7
class TableBloc extends Bloc<TableEvent, TableState> {
  TableBloc({
    required TableRepository repository,
    ReservationRepository? reservationRepository,
  })  : _repo = repository,
        _reservationRepo = reservationRepository,
        super(const TableInitial()) {
    on<TablesLoadRequested>(_onLoad);
    on<TableCreateRequested>(_onCreate);
    on<TableEditRequested>(_onEdit);
    on<TableDeleteRequested>(_onDelete);
    on<TableStatusUpdateRequested>(_onStatusUpdate);
    on<TablesBulkCreateRequested>(_onBulkCreate);
  }
  final TableRepository _repo;
  final ReservationRepository? _reservationRepo;

  Future<void> _onLoad(TablesLoadRequested e, Emitter<TableState> emit) async {
    emit(const TableLoading());
    try {
      final tables = await _repo.getTables();
      final merged = await _mergeActiveReservations(tables);
      emit(TableLoaded(tables: merged));
    } on ApiException catch (ex) {
      emit(TableError(ex.message));
    } catch (ex) {
      emit(TableError(ex.toString()));
    }
  }

  /// Fetches the active reservation list (best-effort) and overlays
  /// reserved-state info on the supplied [tables] so the table card
  /// shows the "Reserved" tag whenever there is an active reservation
  /// for it, regardless of how the reservation was created.
  Future<List<Table>> _mergeActiveReservations(List<Table> tables) async {
    final repo = _reservationRepo;
    if (repo == null) return tables;
    try {
      final reservations = await repo.getReservations();
      return deriveTableReservationState(
        tables: tables,
        reservations: reservations,
      );
    } catch (_) {
      // Reservation backend may be down — never fail the table load
      // because of a best-effort merge.
      return tables;
    }
  }

  Future<void> _onCreate(
      TableCreateRequested e, Emitter<TableState> emit) async {
    final current =
        state is TableLoaded ? (state as TableLoaded).tables : <Table>[];
    try {
      await _repo.createTable(
        tableNumber: e.tableNumber,
        capacity: e.capacity,
        sectionLabel: e.sectionLabel,
        qrCodeUrl: e.qrCodeUrl,
      );
      emit(TableLoaded(tables: await _repo.getTables()));
    } on ApiException catch (ex) {
      emit(TableOperationError(tables: current, message: ex.message));
    } catch (ex) {
      emit(TableOperationError(tables: current, message: ex.toString()));
    }
  }

  Future<void> _onEdit(TableEditRequested e, Emitter<TableState> emit) async {
    final current =
        state is TableLoaded ? (state as TableLoaded).tables : <Table>[];
    try {
      final updated = await _repo.editTable(
        e.id,
        tableNumber: e.tableNumber,
        capacity: e.capacity,
        sectionLabel: e.sectionLabel,
        qrCodeUrl: e.qrCodeUrl,
      );
      emit(TableLoaded(
          tables: current.map((t) => t.id == e.id ? updated : t).toList()));
    } on ApiException catch (ex) {
      emit(TableOperationError(tables: current, message: ex.message));
    } catch (ex) {
      emit(TableOperationError(tables: current, message: ex.toString()));
    }
  }

  Future<void> _onDelete(
      TableDeleteRequested e, Emitter<TableState> emit) async {
    final current =
        state is TableLoaded ? (state as TableLoaded).tables : <Table>[];
    try {
      await _repo.deleteTable(e.id);
      emit(TableLoaded(tables: current.where((t) => t.id != e.id).toList()));
    } on ApiException catch (ex) {
      // 409 = table has active order — surface the message clearly
      emit(TableOperationError(tables: current, message: ex.message));
    } catch (ex) {
      emit(TableOperationError(tables: current, message: ex.toString()));
    }
  }

  Future<void> _onStatusUpdate(
      TableStatusUpdateRequested e, Emitter<TableState> emit) async {
    final current =
        state is TableLoaded ? (state as TableLoaded).tables : <Table>[];
    try {
      final updated = await _repo.updateTableStatus(
        e.id,
        e.status,
        reservation: e.reservation,
      );
      final newList = current.map((t) => t.id == e.id ? updated : t).toList();
      emit(TableLoaded(tables: newList));
    } on ApiException catch (ex) {
      emit(TableOperationError(tables: current, message: ex.message));
    } catch (ex) {
      emit(TableOperationError(tables: current, message: ex.toString()));
    }
  }

  Future<void> _onBulkCreate(
      TablesBulkCreateRequested e, Emitter<TableState> emit) async {
    final current =
        state is TableLoaded ? (state as TableLoaded).tables : <Table>[];
    emit(const TableLoading());
    try {
      final newTables = await _repo.bulkCreateTables(
        count: e.count,
        sectionLabel: e.sectionLabel,
        capacity: e.capacity,
        startingNumber: e.startingNumber,
      );
      emit(TableLoaded(tables: newTables));
    } on ApiException catch (ex) {
      emit(TableLoaded(tables: current, refreshError: ex.message));
    } catch (ex) {
      emit(TableLoaded(tables: current, refreshError: ex.toString()));
    }
  }
}
