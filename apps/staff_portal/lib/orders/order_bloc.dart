import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'order_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class OrderEvent {
  const OrderEvent();
}

final class OrderListRequested extends OrderEvent {
  const OrderListRequested({this.orderType, this.status});
  final String? orderType;
  final String? status;
}

final class OrderNextPageRequested extends OrderEvent {
  const OrderNextPageRequested();
}

final class OrderDetailRequested extends OrderEvent {
  const OrderDetailRequested(this.id);
  final String id;
}

final class OrderCreateRequested extends OrderEvent {
  const OrderCreateRequested(this.payload);
  final Map<String, dynamic> payload;
}

final class OrderStatusUpdateRequested extends OrderEvent {
  const OrderStatusUpdateRequested({required this.id, required this.status});
  final String id;
  final OrderStatus status;
}

final class OrderCancelRequested extends OrderEvent {
  const OrderCancelRequested({required this.id, this.reason});
  final String id;
  final String? reason;
}

final class _OrderPolled extends OrderEvent {
  const _OrderPolled();
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class OrderState {
  const OrderState();
}

final class OrderInitial extends OrderState {
  const OrderInitial();
}

final class OrderLoading extends OrderState {
  const OrderLoading();
}

final class OrderListLoaded extends OrderState {
  const OrderListLoaded(
      {required this.orders,
      required this.pagination,
      this.isLoadingMore = false,
      this.hasReachedEnd = false,
      this.orderType,
      this.status});
  final List<Order> orders;
  final PaginationMeta pagination;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? orderType;
  final String? status;
}

final class OrderDetailLoaded extends OrderState {
  const OrderDetailLoaded(this.order);
  final Order order;
}

final class OrderCreated extends OrderState {
  const OrderCreated(this.order);
  final Order order;
}

final class OrderError extends OrderState {
  const OrderError(this.message);
  final String message;
}

final class OrderOperationError extends OrderState {
  const OrderOperationError(
      {required this.orders, required this.pagination, required this.message});
  final List<Order> orders;
  final PaginationMeta pagination;
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
/// Requirements: 9.1–9.11
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc({required OrderRepository repository})
      : _repo = repository,
        super(const OrderInitial()) {
    on<OrderListRequested>(_onList);
    on<OrderNextPageRequested>(_onNextPage);
    on<OrderDetailRequested>(_onDetail);
    on<OrderCreateRequested>(_onCreate);
    on<OrderStatusUpdateRequested>(_onStatusUpdate);
    on<OrderCancelRequested>(_onCancel);
    on<_OrderPolled>(_onPolled);
  }
  final OrderRepository _repo;
  StreamSubscription<void>? _pollSub;

  Future<void> _onList(OrderListRequested e, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final result =
          await _repo.getOrders(orderType: e.orderType, status: e.status);
      emit(OrderListLoaded(
        orders: result.data,
        pagination: result.pagination,
        hasReachedEnd: result.pagination.page >= result.pagination.pages,
        orderType: e.orderType,
        status: e.status,
      ));
      _startPolling();
    } on ApiException catch (ex) {
      emit(OrderError(ex.message));
    } catch (ex) {
      emit(OrderError(ex.toString()));
    }
  }

  Future<void> _onNextPage(
      OrderNextPageRequested e, Emitter<OrderState> emit) async {
    final cur = state;
    if (cur is! OrderListLoaded || cur.isLoadingMore || cur.hasReachedEnd)
      return;
    emit(OrderListLoaded(
        orders: cur.orders,
        pagination: cur.pagination,
        isLoadingMore: true,
        orderType: cur.orderType,
        status: cur.status));
    try {
      final result = await _repo.getOrders(
          page: cur.pagination.page + 1,
          orderType: cur.orderType,
          status: cur.status);
      emit(OrderListLoaded(
        orders: [...cur.orders, ...result.data],
        pagination: result.pagination,
        hasReachedEnd: result.pagination.page >= result.pagination.pages,
        orderType: cur.orderType,
        status: cur.status,
      ));
    } on ApiException catch (_) {
      emit(OrderListLoaded(
          orders: cur.orders,
          pagination: cur.pagination,
          orderType: cur.orderType,
          status: cur.status));
    } catch (_) {
      emit(OrderListLoaded(
          orders: cur.orders,
          pagination: cur.pagination,
          orderType: cur.orderType,
          status: cur.status));
    }
  }

  Future<void> _onDetail(
      OrderDetailRequested e, Emitter<OrderState> emit) async {
    try {
      emit(OrderDetailLoaded(await _repo.getOrder(e.id)));
    } on ApiException catch (ex) {
      emit(OrderError(ex.message));
    } catch (ex) {
      emit(OrderError(ex.toString()));
    }
  }

  Future<void> _onCreate(
      OrderCreateRequested e, Emitter<OrderState> emit) async {
    try {
      emit(OrderCreated(await _repo.createOrder(e.payload)));
    } on ApiException catch (ex) {
      emit(OrderError(ex.message));
    } catch (ex) {
      emit(OrderError(ex.toString()));
    }
  }

  Future<void> _onStatusUpdate(
      OrderStatusUpdateRequested e, Emitter<OrderState> emit) async {
    try {
      emit(OrderDetailLoaded(await _repo.updateOrderStatus(e.id, e.status)));
    } on ApiException catch (ex) {
      emit(OrderOperationError(
          orders: const [],
          pagination:
              const PaginationMeta(total: 0, page: 1, limit: 20, pages: 0),
          message: ex.message));
    } catch (ex) {
      emit(OrderOperationError(
          orders: const [],
          pagination:
              const PaginationMeta(total: 0, page: 1, limit: 20, pages: 0),
          message: ex.toString()));
    }
  }

  Future<void> _onCancel(
      OrderCancelRequested e, Emitter<OrderState> emit) async {
    try {
      emit(OrderDetailLoaded(await _repo.cancelOrder(e.id, reason: e.reason)));
    } on ApiException catch (ex) {
      emit(OrderOperationError(
          orders: const [],
          pagination:
              const PaginationMeta(total: 0, page: 1, limit: 20, pages: 0),
          message: ex.message));
    } catch (ex) {
      emit(OrderOperationError(
          orders: const [],
          pagination:
              const PaginationMeta(total: 0, page: 1, limit: 20, pages: 0),
          message: ex.toString()));
    }
  }

  Future<void> _onPolled(_OrderPolled e, Emitter<OrderState> emit) async {
    if (state is OrderListLoaded) {
      final cur = state as OrderListLoaded;
      try {
        final result =
            await _repo.getOrders(orderType: cur.orderType, status: cur.status);
        emit(OrderListLoaded(
            orders: result.data,
            pagination: result.pagination,
            hasReachedEnd: result.pagination.page >= result.pagination.pages,
            orderType: cur.orderType,
            status: cur.status));
      } catch (_) {}
    }
  }

  void _startPolling() {
    _pollSub?.cancel();
    _pollSub = Stream.periodic(const Duration(seconds: 30))
        .listen((_) => add(const _OrderPolled()));
  }

  @override
  Future<void> close() {
    _pollSub?.cancel();
    return super.close();
  }
}
