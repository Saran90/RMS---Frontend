import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Injects a unique `X-Request-ID` header (UUID v4) on every outgoing request.
///
/// Satisfies Requirement 18.8: every HTTP request carries a traceable
/// identifier that is unique per request and matches the UUID v4 format.
class RequestIdInterceptor extends Interceptor {
  RequestIdInterceptor() : _uuid = const Uuid();

  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Request-ID'] = _uuid.v4();
    handler.next(options);
  }
}
