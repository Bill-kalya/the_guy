import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'endpoints.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  final Ref ref;
  late final Dio _dio;
  bool _closed = false;

  ApiClient(this.ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    (_dio.httpClientAdapter as dynamic);
    _dio.interceptors.addAll([
      AuthInterceptor(ref.read(secureStorageProvider)),
      RetryInterceptor(),
      ErrorInterceptor(),
      if (!Env.isProduction || Env.enableLogging) LoggingInterceptor(),
    ]);

    ref.onDispose(() => close());
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    _checkClosed();
    return await _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    _checkClosed();
    return await _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    _checkClosed();
    return await _dio.patch(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    _checkClosed();
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    _checkClosed();
    return await _dio.delete(path);
  }

  void _checkClosed() {
    if (_closed) throw StateError('ApiClient has been closed');
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _dio.close(force: true);
  }
}
