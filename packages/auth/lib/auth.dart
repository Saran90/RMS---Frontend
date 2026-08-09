/// Authentication package for the RMS Flutter monorepo.
///
/// Exposes [AuthBloc], [AuthRepository], [SecureTokenRepository],
/// and associated events/states.
library auth;

// auth_event.dart and auth_state.dart are `part` files of auth_bloc.dart;
// exporting auth_bloc.dart implicitly exposes their public symbols.
export 'src/auth_bloc.dart';
export 'src/auth_repository.dart';
export 'src/secure_token_repository.dart';
