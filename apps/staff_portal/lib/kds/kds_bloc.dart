import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'kds_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class KdsEvent {
  const KdsEvent();
}

final class KdsFeedRequested extends KdsEvent {
  const KdsFeedRequested(this.stationId);
  final String stationId;
}

final class KdsItemStatusUpdateRequested extends KdsEvent {
  const KdsItemStatusUpdateRequested({
    required this.itemId,
    required this.orderId,
    required this.status,
  });
  final String itemId;
  final String orderId;
  final KdsItemStatus status;
}

final class _KdsPolled extends KdsEvent {
  const _KdsPolled();
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class KdsState {
  const KdsState();
}

final class KdsInitial extends KdsState {
  const KdsInitial();
}

final class KdsLoading extends KdsState {
  const KdsLoading();
}

final class KdsFeedLoaded extends KdsState {
  const KdsFeedLoaded({required this.orders, this.pollingError = false});
  final List<KdsOrder> orders;
  final bool pollingError;
}

final class KdsItemUpdateError extends KdsState {
  const KdsItemUpdateError({required this.orders, required this.message});
  final List<KdsOrder> orders;
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class KdsBloc extends Bloc<KdsEvent, KdsState> {
  KdsBloc({required KdsRepository repository})
      : _repo = repository,
        super(const KdsInitial()) {
    on<KdsFeedRequested>(_onFeed);
    on<KdsItemStatusUpdateRequested>(_onStatusUpdate);
    on<_KdsPolled>(_onPolled);
  }

  final KdsRepository _repo;
  StreamSubscription<void>? _pollSub;
  String? _stationId;

  Future<void> _onFeed(KdsFeedRequested e, Emitter<KdsState> emit) async {
    _stationId = e.stationId;
    emit(const KdsLoading());
    try {
      final orders = await _repo.getStationFeed(e.stationId);
      emit(KdsFeedLoaded(orders: orders));
      _startPolling();
    } catch (_) {
      emit(const KdsFeedLoaded(orders: [], pollingError: true));
    }
  }

  Future<void> _onStatusUpdate(
      KdsItemStatusUpdateRequested e, Emitter<KdsState> emit) async {
    final prev =
        state is KdsFeedLoaded ? (state as KdsFeedLoaded).orders : <KdsOrder>[];

    // ── Optimistic update ──────────────────────────────────────────────────
    final optimistic = prev.map((order) {
      if (order.orderId != e.orderId) return order;

      final updatedItems = order.items
          .map((item) =>
              item.id == e.itemId ? item.copyWith(kdsStatus: e.status) : item)
          .toList();

      // If any item just started → order moves to preparing
      // If all items are done → order moves to ready
      final allDone =
          updatedItems.every((i) => i.kdsStatus == KdsItemStatus.done);
      final anyStarted =
          updatedItems.any((i) => i.kdsStatus == KdsItemStatus.started);

      final newOrderStatus = allDone
          ? OrderStatus.ready
          : anyStarted
              ? OrderStatus.preparing
              : order.orderStatus;

      return order.copyWith(items: updatedItems, orderStatus: newOrderStatus);
    }).toList();

    emit(KdsFeedLoaded(orders: optimistic));

    try {
      await _repo.updateKdsItemStatus(e.itemId, e.status);

      // If all items done, remove the order from the feed
      if (e.status == KdsItemStatus.done) {
        final updated = optimistic.where((order) {
          if (order.orderId != e.orderId) return true;
          return !order.items.every((i) => i.kdsStatus == KdsItemStatus.done);
        }).toList();
        emit(KdsFeedLoaded(orders: updated));
      }
    } on ApiException catch (ex) {
      emit(KdsItemUpdateError(orders: prev, message: ex.message));
    } catch (ex) {
      emit(KdsItemUpdateError(orders: prev, message: ex.toString()));
    }
  }

  Future<void> _onPolled(_KdsPolled e, Emitter<KdsState> emit) async {
    if (_stationId == null) return;
    final cur =
        state is KdsFeedLoaded ? (state as KdsFeedLoaded).orders : <KdsOrder>[];
    try {
      final fresh = await _repo.getStationFeed(_stationId!);
      emit(KdsFeedLoaded(orders: fresh));
    } catch (_) {
      emit(KdsFeedLoaded(orders: cur, pollingError: true));
    }
  }

  void _startPolling() {
    _pollSub?.cancel();
    _pollSub = Stream.periodic(const Duration(seconds: 15))
        .listen((_) => add(const _KdsPolled()));
  }

  @override
  Future<void> close() {
    _pollSub?.cancel();
    return super.close();
  }
}
