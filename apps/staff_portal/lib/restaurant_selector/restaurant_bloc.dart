import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';

import 'restaurant_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

sealed class RestaurantEvent {
  const RestaurantEvent();
}

final class RestaurantListRequested extends RestaurantEvent {
  const RestaurantListRequested();
}

final class RestaurantItemSelected extends RestaurantEvent {
  const RestaurantItemSelected({required this.restaurantId});
  final String restaurantId;
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class RestaurantState {
  const RestaurantState();
}

final class RestaurantInitial extends RestaurantState {
  const RestaurantInitial();
}

final class RestaurantLoading extends RestaurantState {
  const RestaurantLoading();
}

final class RestaurantLoaded extends RestaurantState {
  const RestaurantLoaded(this.restaurants);
  final List<Restaurant> restaurants;
}

/// Empty list — user needs to create a restaurant first.
final class RestaurantEmpty extends RestaurantState {
  const RestaurantEmpty();
}

final class RestaurantError extends RestaurantState {
  const RestaurantError(this.message);
  final String message;
}

/// A selection is in flight — show loading indicator on the selected card.
final class RestaurantSelecting extends RestaurantState {
  const RestaurantSelecting({
    required this.restaurants,
    required this.selectingId,
  });
  final List<Restaurant> restaurants;
  final String selectingId;
}

/// The selection API call succeeded — AuthBloc.RestaurantSelected handles
/// token storage; this state signals success to the UI.
final class RestaurantSelected extends RestaurantState {
  const RestaurantSelected();
}

final class RestaurantSelectError extends RestaurantState {
  const RestaurantSelectError({
    required this.restaurants,
    required this.message,
  });
  final List<Restaurant> restaurants;
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

/// Manages the restaurant listing and selection flow.
///
/// NOTE: Actual token storage after selection is handled by [AuthBloc] via
/// [RestaurantSelected] event.  This bloc just drives the UI state for the
/// selector screen.
///
/// Requirements: 3.1, 3.2, 3.5, 3.6
class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  RestaurantBloc({required RestaurantRepository repository})
      : _repo = repository,
        super(const RestaurantInitial()) {
    on<RestaurantListRequested>(_onListRequested);
    on<RestaurantItemSelected>(_onItemSelected);
    // Load immediately on creation.
    add(const RestaurantListRequested());
  }

  final RestaurantRepository _repo;

  Future<void> _onListRequested(
    RestaurantListRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());
    try {
      final restaurants = await _repo.getRestaurants();
      if (restaurants.isEmpty) {
        emit(const RestaurantEmpty());
      } else {
        emit(RestaurantLoaded(restaurants));
      }
    } on ApiException catch (e) {
      emit(RestaurantError(e.message));
    } catch (e) {
      emit(RestaurantError(e.toString()));
    }
  }

  Future<void> _onItemSelected(
    RestaurantItemSelected event,
    Emitter<RestaurantState> emit,
  ) async {
    // Get the current restaurant list to show it while loading.
    final currentList = switch (state) {
      RestaurantLoaded(:final restaurants) => restaurants,
      RestaurantSelectError(:final restaurants) => restaurants,
      _ => <Restaurant>[],
    };

    emit(RestaurantSelecting(
      restaurants: currentList,
      selectingId: event.restaurantId,
    ));

    // Selection / token storage is handled by AuthBloc.RestaurantSelected.
    // This bloc simply signals "proceed" — the calling screen dispatches
    // the AuthBloc event directly.
    emit(const RestaurantSelected());
  }
}
