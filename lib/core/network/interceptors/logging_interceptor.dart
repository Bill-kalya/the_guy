import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/env.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (Env.enableLogging) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🚀 REQUEST: ${options.method} ${options.path}');
      debugPrint('📦 HEADERS: ${options.headers}');
      if (options.data != null) {
        debugPrint('📝 BODY: ${options.data}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (Env.enableLogging) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint(
        '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
      );
      if (response.data != null) {
        debugPrint('📦 DATA: ${response.data}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (Env.enableLogging) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.path}');
      debugPrint('⚠️ MESSAGE: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('📦 ERROR DATA: ${err.response?.data}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return handler.next(err);
  }
}
