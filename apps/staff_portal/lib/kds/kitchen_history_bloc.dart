import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'kds_repository.dart';

sealed class KitchenHistoryEvent {
  const KitchenHistoryEvent();
}

final class KitchenHistoryLoadRequested extends KitchenHistoryEvent {
  const KitchenHistoryLoadRequested(this.stationId);
  final String stationId;
}

sealed class KitchenHistoryState {
  const KitchenHistoryState();
}

final class KitchenHistoryInitial extends KitchenHistoryState {
  const KitchenHistoryInitial();
}

final class KitchenHistoryLoading extends KitchenHistoryState {
  const KitchenHistoryLoading();
}

final class KitchenHistoryLoaded extends KitchenHistoryState {
  const KitchenHistoryLoaded({required this.orders});
  final List<KdsOrder> orders;
}

final class KitchenHistoryError extends KitchenHistoryState {
  const KitchenHistoryError(this.message);
  final String message;
}

class KitchenHistoryBloc extends Bloc<KitchenHistoryEvent, KitchenHistoryState> {
  KitchenHistoryBloc({required KdsRepository repository})
      : _repo = repository,
        super(const KitchenHistoryInitial()) {
    on<KitchenHistoryLoadRequested>(_onLoad);
  }

  final KdsRepository _repo;

  Future<void> _onLoad(
    KitchenHistoryLoadRequested event,
    Emitter<KitchenHistoryState> emit,
  ) async {
    emit(const KitchenHistoryLoading());
    try {
      final orders = await _repo.getStationHistory(event.stationId);
      emit(KitchenHistoryLoaded(orders: orders));
    } on ApiException catch (ex) {
      emit(KitchenHistoryError(ex.message));
    } catch (ex) {
      emit(KitchenHistoryError(ex.toString()));
    }
  }
}
