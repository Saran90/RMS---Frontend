import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tracks network connectivity and emits [ConnectivityStatus] changes.
///
/// Uses the `connectivity_plus` package stream. The cubit emits:
/// - [ConnectivityStatus.connected] when at least one connectivity type is
///   available (wifi, mobile, ethernet, etc.).
/// - [ConnectivityStatus.disconnected] when the list is empty or contains only
///   [ConnectivityResult.none].
///
/// Requirements: 19.1, 19.2, 19.3, 19.4.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      super(ConnectivityStatus.connected) {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // ---------------------------------------------------------------------------

  void _init() {
    // Check current status immediately on creation.
    _connectivity.checkConnectivity().then(_handleResults);

    // Subscribe to future changes.
    _subscription = _connectivity.onConnectivityChanged.listen(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final isOnline =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
    emit(
      isOnline ? ConnectivityStatus.connected : ConnectivityStatus.disconnected,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

/// Simple two-state connectivity status.
enum ConnectivityStatus {
  /// Device has at least one active network interface.
  connected,

  /// Device has no network connectivity.
  disconnected,
}
