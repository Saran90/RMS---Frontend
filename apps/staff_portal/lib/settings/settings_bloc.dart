import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/settings/settings_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class SettingsEvent {
  const SettingsEvent();
}

/// Load the restaurant profile for the given [restaurantId].
///
/// Requirements: 15.1
final class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested(this.restaurantId);
  final String restaurantId;
}

/// Submit updated restaurant profile details.
///
/// Requirements: 15.2, 15.3, 15.4
final class SettingsUpdateRequested extends SettingsEvent {
  const SettingsUpdateRequested({
    required this.restaurantId,
    required this.payload,
  });
  final String restaurantId;

  /// The partial or full update payload, e.g.:
  /// `{'name': '...', 'address': '...', 'phone': '...', 'gst_number': '...',
  ///   'logo_url': '...', 'business_hours': [...]}`
  final Map<String, dynamic> payload;
}

// ── States ────────────────────────────────────────────────────────────────────
sealed class SettingsState {
  const SettingsState();
}

final class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Emitted while the initial `GET /api/v1/restaurants/:id` is in flight.
///
/// Requirements: 15.1
final class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Emitted once restaurant data has loaded successfully.
///
/// Requirements: 15.1
final class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.restaurant);
  final Restaurant restaurant;
}

/// Emitted while a `PATCH /api/v1/restaurants/:id` is in flight.
/// Carries the current [restaurant] so the UI can remain populated.
///
/// Requirements: 15.2
final class SettingsUpdating extends SettingsState {
  const SettingsUpdating(this.restaurant);
  final Restaurant restaurant;
}

/// Emitted after a successful `PATCH /api/v1/restaurants/:id`.
/// The UI should display a success confirmation (Req 15.2).
///
/// Requirements: 15.2
final class SettingsSaved extends SettingsState {
  const SettingsSaved(this.restaurant);
  final Restaurant restaurant;
}

/// Emitted when the initial load fails.
///
/// Requirements: 15.1
final class SettingsError extends SettingsState {
  const SettingsError(this.message);
  final String message;
}

/// Emitted when `PATCH /api/v1/restaurants/:id` returns a 422 validation error.
/// The [fields] list names the offending form fields reported by the server.
/// The current [restaurant] is preserved so the form can remain populated.
///
/// Requirements: 15.3
final class SettingsValidationError extends SettingsState {
  const SettingsValidationError({
    required this.restaurant,
    required this.message,
    required this.fields,
  });
  final Restaurant restaurant;
  final String message;

  /// Server-reported offending field names (e.g. `['name', 'gst_number']`).
  /// May be empty if the server does not enumerate individual fields.
  final List<String> fields;
}

/// Emitted when `PATCH /api/v1/restaurants/:id` fails for a non-validation
/// reason (5xx, timeout, etc.) while a restaurant is already loaded.
/// The current [restaurant] is preserved so the UI does not lose form data.
///
/// Requirements: 15.2
final class SettingsOperationError extends SettingsState {
  const SettingsOperationError({
    required this.restaurant,
    required this.message,
  });
  final Restaurant restaurant;
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

/// Manages the settings state machine.
///
/// Requirements: 15.1, 15.2, 15.3, 15.4, 15.5
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required SettingsRepository repository})
      : _repo = repository,
        super(const SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsUpdateRequested>(_onUpdate);
  }

  final SettingsRepository _repo;

  /// Cached restaurant so it can be included in error states after load.
  Restaurant? _restaurant;

  // ── Handlers ──────────────────────────────────────────────────────────────

  /// Fetches the restaurant profile (Req 15.1).
  Future<void> _onLoad(
    SettingsLoadRequested e,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final r = await _repo.getRestaurant(e.restaurantId);
      _restaurant = r;
      emit(SettingsLoaded(r));
    } on ApiException catch (ex) {
      emit(SettingsError(ex.message));
    } catch (ex) {
      emit(SettingsError(ex.toString()));
    }
  }

  /// Submits updated profile details (Req 15.2) and handles validation errors
  /// (Req 15.3) and business-hours updates (Req 15.4).
  Future<void> _onUpdate(
    SettingsUpdateRequested e,
    Emitter<SettingsState> emit,
  ) async {
    // Keep the current restaurant in the state so the form stays populated
    // while the request is in flight (Req 15.2).
    final current = _restaurant;
    if (current != null) {
      emit(SettingsUpdating(current));
    } else {
      emit(const SettingsLoading());
    }

    try {
      final r = await _repo.updateRestaurant(e.restaurantId, e.payload);
      _restaurant = r;
      emit(SettingsSaved(r));
    } on ApiException catch (ex) {
      if (ex.statusCode == 422) {
        // Validation error: highlight offending fields (Req 15.3).
        // The server message describes the error; fields are extracted from
        // errorCode if the server enumerates them (e.g. comma-separated names).
        final fields = _parseFields(ex.errorCode);
        emit(SettingsValidationError(
          restaurant: current ?? _restaurant ?? _emptyRestaurant,
          message: ex.message,
          fields: fields,
        ));
      } else {
        emit(SettingsOperationError(
          restaurant: current ?? _restaurant ?? _emptyRestaurant,
          message: ex.message,
        ));
      }
    } catch (ex) {
      emit(SettingsOperationError(
        restaurant: current ?? _restaurant ?? _emptyRestaurant,
        message: ex.toString(),
      ));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parses a comma-separated list of field names from the server errorCode.
  /// Returns an empty list when no individual fields are reported.
  List<String> _parseFields(String errorCode) {
    if (errorCode.isEmpty) return const [];
    return errorCode.split(',').map((f) => f.trim()).toList();
  }

  /// Fallback Restaurant used only when [_restaurant] is unexpectedly null
  /// (i.e. an update was attempted without a prior successful load).
  static const _emptyRestaurant = Restaurant(
    id: '',
    name: '',
    address: '',
    phone: '',
    gstNumber: '',
  );
}
