import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:staff_portal/reports/reports_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class ReportsEvent {
  const ReportsEvent();
}

final class SalesReportRequested extends ReportsEvent {
  const SalesReportRequested({this.dateFrom, this.dateTo});
  final String? dateFrom, dateTo;
}

final class TopItemsReportRequested extends ReportsEvent {
  const TopItemsReportRequested({this.dateFrom, this.dateTo});
  final String? dateFrom, dateTo;
}

final class RevenueByTypeReportRequested extends ReportsEvent {
  const RevenueByTypeReportRequested({this.dateFrom, this.dateTo});
  final String? dateFrom, dateTo;
}

final class StaffPerformanceReportRequested extends ReportsEvent {
  const StaffPerformanceReportRequested({this.dateFrom, this.dateTo});
  final String? dateFrom, dateTo;
}

final class GstSummaryReportRequested extends ReportsEvent {
  const GstSummaryReportRequested({this.dateFrom, this.dateTo});
  final String? dateFrom, dateTo;
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class ReportsState {
  const ReportsState();
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

final class SalesReportLoaded extends ReportsState {
  const SalesReportLoaded(
      {required this.data, required this.dateFrom, required this.dateTo});
  final List<SalesReportDay> data;
  final String dateFrom, dateTo;
}

final class TopItemsReportLoaded extends ReportsState {
  const TopItemsReportLoaded(
      {required this.data, required this.dateFrom, required this.dateTo});
  final List<TopItem> data;
  final String dateFrom, dateTo;
}

final class RevenueByTypeReportLoaded extends ReportsState {
  const RevenueByTypeReportLoaded(
      {required this.data, required this.dateFrom, required this.dateTo});
  final List<RevenueByType> data;
  final String dateFrom, dateTo;
}

final class StaffPerformanceReportLoaded extends ReportsState {
  const StaffPerformanceReportLoaded(
      {required this.data, required this.dateFrom, required this.dateTo});
  final List<StaffPerformance> data;
  final String dateFrom, dateTo;
}

final class GstSummaryReportLoaded extends ReportsState {
  const GstSummaryReportLoaded(
      {required this.data, required this.dateFrom, required this.dateTo});
  final List<GstSummaryItem> data;
  final String dateFrom, dateTo;
}

final class ReportsError extends ReportsState {
  const ReportsError(this.message);
  final String message;
}

final class ReportsEmpty extends ReportsState {
  const ReportsEmpty();
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({required ReportsRepository repository})
      : _repo = repository,
        super(const ReportsInitial()) {
    on<SalesReportRequested>(_onSales);
    on<TopItemsReportRequested>(_onTopItems);
    on<RevenueByTypeReportRequested>(_onRevenueByType);
    on<StaffPerformanceReportRequested>(_onStaffPerformance);
    on<GstSummaryReportRequested>(_onGstSummary);
  }
  final ReportsRepository _repo;

  String _from(String? d) => d ?? _repo.defaultDateFrom;
  String _to(String? d) => d ?? _repo.defaultDateTo;

  Future<void> _onSales(
      SalesReportRequested e, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading());
    try {
      final data =
          await _repo.getSalesReport(dateFrom: e.dateFrom, dateTo: e.dateTo);
      if (data.isEmpty) {
        emit(const ReportsEmpty());
        return;
      }
      emit(SalesReportLoaded(
          data: data, dateFrom: _from(e.dateFrom), dateTo: _to(e.dateTo)));
    } on ApiException catch (ex) {
      emit(ReportsError(ex.message));
    } catch (ex) {
      emit(ReportsError(ex.toString()));
    }
  }

  Future<void> _onTopItems(
      TopItemsReportRequested e, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading());
    try {
      final data =
          await _repo.getTopItemsReport(dateFrom: e.dateFrom, dateTo: e.dateTo);
      if (data.isEmpty) {
        emit(const ReportsEmpty());
        return;
      }
      emit(TopItemsReportLoaded(
          data: data, dateFrom: _from(e.dateFrom), dateTo: _to(e.dateTo)));
    } on ApiException catch (ex) {
      emit(ReportsError(ex.message));
    } catch (ex) {
      emit(ReportsError(ex.toString()));
    }
  }

  Future<void> _onRevenueByType(
      RevenueByTypeReportRequested e, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading());
    try {
      final data = await _repo.getRevenueByTypeReport(
          dateFrom: e.dateFrom, dateTo: e.dateTo);
      if (data.isEmpty) {
        emit(const ReportsEmpty());
        return;
      }
      emit(RevenueByTypeReportLoaded(
          data: data, dateFrom: _from(e.dateFrom), dateTo: _to(e.dateTo)));
    } on ApiException catch (ex) {
      emit(ReportsError(ex.message));
    } catch (ex) {
      emit(ReportsError(ex.toString()));
    }
  }

  Future<void> _onStaffPerformance(
      StaffPerformanceReportRequested e, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading());
    try {
      final data = await _repo.getStaffPerformanceReport(
          dateFrom: e.dateFrom, dateTo: e.dateTo);
      if (data.isEmpty) {
        emit(const ReportsEmpty());
        return;
      }
      emit(StaffPerformanceReportLoaded(
          data: data, dateFrom: _from(e.dateFrom), dateTo: _to(e.dateTo)));
    } on ApiException catch (ex) {
      emit(ReportsError(ex.message));
    } catch (ex) {
      emit(ReportsError(ex.toString()));
    }
  }

  Future<void> _onGstSummary(
      GstSummaryReportRequested e, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading());
    try {
      final data = await _repo.getGstSummaryReport(
          dateFrom: e.dateFrom, dateTo: e.dateTo);
      if (data.isEmpty) {
        emit(const ReportsEmpty());
        return;
      }
      emit(GstSummaryReportLoaded(
          data: data, dateFrom: _from(e.dateFrom), dateTo: _to(e.dateTo)));
    } on ApiException catch (ex) {
      emit(ReportsError(ex.message));
    } catch (ex) {
      emit(ReportsError(ex.toString()));
    }
  }
}
