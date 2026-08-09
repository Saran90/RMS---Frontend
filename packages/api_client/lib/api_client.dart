/// Dio-based HTTP client for the RMS Flutter monorepo.
///
/// Exposes [ApiClient], [ApiException], and the three interceptors:
/// [RequestIdInterceptor], [AuthInterceptor], [ErrorInterceptor].
library api_client;

export 'src/api_client.dart';
export 'src/api_exception.dart';
export 'src/interceptors/auth_interceptor.dart';
export 'src/interceptors/error_interceptor.dart';
export 'src/interceptors/request_id_interceptor.dart';
export 'src/token_repository.dart';
