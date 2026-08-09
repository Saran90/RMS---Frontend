import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Called by [RedirectInterceptor] when a server response carries a
/// `redirect` field. The value is one of:
/// `login`, `payment`, `billing`, `support`, `restaurant_setup`.
typedef OnRedirect = void Function(String destination);

/// Intercepts errors that carry an [ApiException.redirect] hint and invokes
/// [onRedirect] so the app layer can navigate without coupling this package
/// to any routing library.
///
/// Must be placed **after** [ErrorInterceptor] in the interceptor chain so
/// that `DioException.error` is already an [ApiException] when this runs.
class RedirectInterceptor extends Interceptor {
  RedirectInterceptor({required this.onRedirect});

  final OnRedirect onRedirect;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = err.error;
    if (apiException is ApiException) {
      final redirect = apiException.redirect;
      if (redirect != null && redirect.isNotEmpty) {
        onRedirect(redirect);
      }
    }
    handler.next(err);
  }
}
