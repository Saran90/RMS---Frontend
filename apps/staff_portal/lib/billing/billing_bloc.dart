import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'billing_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class BillingEvent {
  const BillingEvent();
}

final class BillGenerateRequested extends BillingEvent {
  const BillGenerateRequested(this.orderId);
  final String orderId;
}

final class BillPaymentRequested extends BillingEvent {
  const BillPaymentRequested(
      {required this.billId, required this.mode, required this.amount});
  final String billId;
  final String mode;
  final double amount;
}

final class BillSplitRequested extends BillingEvent {
  const BillSplitRequested({required this.billId, required this.diners});
  final String billId;
  final int diners;
}

final class BillVoidRequested extends BillingEvent {
  const BillVoidRequested({required this.billId, required this.reason});
  final String billId;
  final String reason;
}

final class BillLoadRequested extends BillingEvent {
  const BillLoadRequested(this.billId);
  final String billId;
}

final class BillsListRequested extends BillingEvent {
  const BillsListRequested();
}

final class BillNewRequested extends BillingEvent {
  const BillNewRequested();
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class BillingState {
  const BillingState();
}

final class BillingInitial extends BillingState {
  const BillingInitial();
}

final class BillingLoading extends BillingState {
  const BillingLoading();
}

final class BillLoaded extends BillingState {
  const BillLoaded(this.bill);
  final Bill bill;
}

final class BillSplit extends BillingState {
  const BillSplit({required this.originalBill, required this.subBills});
  final Bill originalBill;
  final List<Bill> subBills;
}

final class BillingError extends BillingState {
  const BillingError({this.bill, required this.message});
  final Bill? bill;
  final String message;
}

final class BillsListLoaded extends BillingState {
  const BillsListLoaded(this.bills);
  final List<Bill> bills;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
/// Requirements: 11.1–11.13
class BillingBloc extends Bloc<BillingEvent, BillingState> {
  BillingBloc({required BillingRepository repository})
      : _repo = repository,
        super(const BillingInitial()) {
    print('BillingBloc: constructor called');
    on<BillGenerateRequested>(_onGenerate);
    on<BillPaymentRequested>(_onPayment);
    on<BillSplitRequested>(_onSplit);
    on<BillVoidRequested>(_onVoid);
    on<BillLoadRequested>(_onLoad);
    on<BillsListRequested>(_onListBills);
    on<BillNewRequested>((_, emit) => emit(const BillingInitial()));
    print('BillingBloc: event handlers registered');
  }
  final BillingRepository _repo;
  Bill? _currentBill;

  Future<void> _onGenerate(
      BillGenerateRequested e, Emitter<BillingState> emit) async {
    emit(const BillingLoading());
    try {
      final b = await _repo.generateBill(e.orderId);
      _currentBill = b;
      emit(BillLoaded(b));
    } on ApiException catch (ex) {
      emit(BillingError(message: ex.message));
    } catch (ex) {
      emit(BillingError(message: ex.toString()));
    }
  }

  Future<void> _onPayment(
      BillPaymentRequested e, Emitter<BillingState> emit) async {
    emit(const BillingLoading());
    try {
      final b = await _repo.recordPayment(
          billId: e.billId, mode: e.mode, amount: e.amount);
      _currentBill = b;
      emit(BillLoaded(b));
    } on ApiException catch (ex) {
      emit(BillingError(bill: _currentBill, message: ex.message));
    } catch (ex) {
      emit(BillingError(bill: _currentBill, message: ex.toString()));
    }
  }

  Future<void> _onSplit(
      BillSplitRequested e, Emitter<BillingState> emit) async {
    emit(const BillingLoading());
    try {
      final subs = await _repo.splitBill(billId: e.billId, diners: e.diners);
      emit(BillSplit(originalBill: _currentBill!, subBills: subs));
    } on ApiException catch (ex) {
      emit(BillingError(bill: _currentBill, message: ex.message));
    } catch (ex) {
      emit(BillingError(bill: _currentBill, message: ex.toString()));
    }
  }

  Future<void> _onVoid(BillVoidRequested e, Emitter<BillingState> emit) async {
    emit(const BillingLoading());
    try {
      final b = await _repo.voidBill(billId: e.billId, reason: e.reason);
      _currentBill = b;
      emit(BillLoaded(b));
    } on ApiException catch (ex) {
      emit(BillingError(bill: _currentBill, message: ex.message));
    } catch (ex) {
      emit(BillingError(bill: _currentBill, message: ex.toString()));
    }
  }

  Future<void> _onLoad(BillLoadRequested e, Emitter<BillingState> emit) async {
    emit(const BillingLoading());
    try {
      final b = await _repo.getBill(e.billId);
      _currentBill = b;
      emit(BillLoaded(b));
    } on ApiException catch (ex) {
      emit(BillingError(message: ex.message));
    } catch (ex) {
      emit(BillingError(message: ex.toString()));
    }
  }

  Future<void> _onListBills(
      BillsListRequested e, Emitter<BillingState> emit) async {
    print('BillingBloc: _onListBills called');
    emit(const BillingLoading());
    try {
      print('BillingBloc: calling repository.listBills()');
      final bills = await _repo.listBills();
      print('BillingBloc: received ${bills.length} bills');

      // Log bill details safely
      for (final bill in bills) {
        print(
            'BillingBloc: bill id=${bill.id.substring(0, 8)}, status=${bill.status}');
      }

      print('BillingBloc: emitting BillsListLoaded with ${bills.length} bills');
      emit(BillsListLoaded(bills));
    } catch (e, stackTrace) {
      print('BillingBloc: Error - $e');
      print('BillingBloc: Stack trace - $stackTrace');
      emit(BillingInitial());
    }
  }
}
