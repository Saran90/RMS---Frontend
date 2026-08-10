import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'staff_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class StaffEvent {
  const StaffEvent();
}

final class StaffListRequested extends StaffEvent {
  const StaffListRequested();
}

final class StaffCreateRequested extends StaffEvent {
  const StaffCreateRequested({
    required this.fullName,
    required this.phoneNumber,
    required this.username,
    required this.role,
    this.email,
    this.password,
  });

  final String fullName;
  final String phoneNumber;
  final String username;
  final String role;
  final String? email;
  final String? password;
}

final class StaffRoleUpdateRequested extends StaffEvent {
  const StaffRoleUpdateRequested({required this.id, required this.role});
  final String id, role;
}

final class StaffDeactivateRequested extends StaffEvent {
  const StaffDeactivateRequested(this.id);
  final String id;
}

final class StaffShiftsRequested extends StaffEvent {
  const StaffShiftsRequested();
}

final class StaffShiftSaveRequested extends StaffEvent {
  const StaffShiftSaveRequested(this.payload);
  final Map<String, dynamic> payload;
}

final class StaffShiftDeleteRequested extends StaffEvent {
  const StaffShiftDeleteRequested(this.shiftId);
  final String shiftId;
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class StaffState {
  const StaffState();
}

final class StaffInitial extends StaffState {
  const StaffInitial();
}

final class StaffLoading extends StaffState {
  const StaffLoading();
}

final class StaffLoaded extends StaffState {
  const StaffLoaded(this.staff);
  final List<Staff> staff;
}

/// Emitted after owner creates a staff member with login credentials.
final class StaffCreated extends StaffState {
  const StaffCreated({
    required this.staff,
    required this.createdMember,
    required this.loginPassword,
  });

  final List<Staff> staff;
  final Staff createdMember;
  final String loginPassword;
}

final class StaffError extends StaffState {
  const StaffError(this.message);
  final String message;
}

final class StaffOperationError extends StaffState {
  const StaffOperationError({required this.staff, required this.message});
  final List<Staff> staff;
  final String message;
}

final class StaffShiftsLoaded extends StaffState {
  const StaffShiftsLoaded(this.shifts);
  final List<StaffShift> shifts;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class StaffBloc extends Bloc<StaffEvent, StaffState> {
  StaffBloc({required StaffRepository repository})
      : _repo = repository,
        super(const StaffInitial()) {
    on<StaffListRequested>(_onList);
    on<StaffCreateRequested>(_onCreate);
    on<StaffRoleUpdateRequested>(_onRoleUpdate);
    on<StaffDeactivateRequested>(_onDeactivate);
    on<StaffShiftsRequested>(_onShifts);
    on<StaffShiftSaveRequested>(_onShiftSave);
    on<StaffShiftDeleteRequested>(_onShiftDelete);
  }
  final StaffRepository _repo;
  List<Staff> _currentStaff = [];

  static const defaultStaffPassword = 'Staff@1234';

  Future<void> _onList(StaffListRequested e, Emitter<StaffState> emit) async {
    emit(const StaffLoading());
    try {
      final s = await _repo.getStaff();
      _currentStaff = s;
      emit(StaffLoaded(s));
    } on ApiException catch (ex) {
      emit(StaffError(ex.message));
    } catch (ex) {
      emit(StaffError(ex.toString()));
    }
  }

  Future<void> _onCreate(
      StaffCreateRequested e, Emitter<StaffState> emit) async {
    try {
      final passwordUsed =
          (e.password != null && e.password!.isNotEmpty)
              ? e.password!
              : defaultStaffPassword;
      final created = await _repo.createStaff(
        fullName: e.fullName,
        phoneNumber: e.phoneNumber,
        username: e.username,
        role: e.role,
        email: e.email,
        password: e.password,
      );
      final s = await _repo.getStaff();
      _currentStaff = s;
      emit(StaffCreated(
        staff: _currentStaff,
        createdMember: created,
        loginPassword: passwordUsed,
      ));
    } on ApiException catch (ex) {
      emit(StaffOperationError(staff: _currentStaff, message: ex.message));
    } catch (ex) {
      emit(StaffOperationError(staff: _currentStaff, message: ex.toString()));
    }
  }

  Future<void> _onRoleUpdate(
      StaffRoleUpdateRequested e, Emitter<StaffState> emit) async {
    try {
      final updated = await _repo.updateStaffRole(e.id, e.role);
      _currentStaff =
          _currentStaff.map((s) => s.id == e.id ? updated : s).toList();
      emit(StaffLoaded(_currentStaff));
    } on ApiException catch (ex) {
      emit(StaffOperationError(staff: _currentStaff, message: ex.message));
    } catch (ex) {
      emit(StaffOperationError(staff: _currentStaff, message: ex.toString()));
    }
  }

  Future<void> _onDeactivate(
      StaffDeactivateRequested e, Emitter<StaffState> emit) async {
    try {
      final updated = await _repo.deactivateStaff(e.id);
      _currentStaff =
          _currentStaff.map((s) => s.id == e.id ? updated : s).toList();
      emit(StaffLoaded(_currentStaff));
    } on ApiException catch (ex) {
      emit(StaffOperationError(staff: _currentStaff, message: ex.message));
    } catch (ex) {
      emit(StaffOperationError(staff: _currentStaff, message: ex.toString()));
    }
  }

  Future<void> _onShifts(
      StaffShiftsRequested e, Emitter<StaffState> emit) async {
    try {
      emit(StaffShiftsLoaded(await _repo.getShifts()));
    } on ApiException catch (ex) {
      emit(StaffError(ex.message));
    } catch (ex) {
      emit(StaffError(ex.toString()));
    }
  }

  Future<void> _onShiftSave(
      StaffShiftSaveRequested e, Emitter<StaffState> emit) async {
    try {
      await _repo.saveShift(e.payload);
      emit(StaffShiftsLoaded(await _repo.getShifts()));
    } on ApiException catch (ex) {
      emit(StaffError(ex.message));
    } catch (ex) {
      emit(StaffError(ex.toString()));
    }
  }

  Future<void> _onShiftDelete(
      StaffShiftDeleteRequested e, Emitter<StaffState> emit) async {
    try {
      await _repo.deleteShift(e.shiftId);
      emit(StaffShiftsLoaded(await _repo.getShifts()));
    } on ApiException catch (ex) {
      emit(StaffError(ex.message));
    } catch (ex) {
      emit(StaffError(ex.toString()));
    }
  }
}
