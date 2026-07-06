import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../../utils/error_handler.dart';
import '../endpoints.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  late final Dio _dio;
  bool _isRefreshing = false;
  final Map<String, dynamic> _pendingRequests = {};

  AuthInterceptor(this._secureStorage) {
    _dio = Dio();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (!_isRefreshing) {
      _isRefreshing = true;
      final refreshed = await _refreshToken();
      _isRefreshing = false;

      if (refreshed) {
        final newToken = await _secureStorage.getAccessToken();
        final newOptions = err.requestOptions;
        newOptions.headers['Authorization'] = 'Bearer $newToken';

        try {
          final response = await _dio.fetch(newOptions);
          return handler.resolve(response);
        } catch (e) {
          ErrorHandler.logError('Retry after token refresh failed', e);
          return handler.next(err);
        }
      }

      await _secureStorage.clearAll();
      return handler.reject(err);
    }

    // Another request is already refreshing — queue this one
    try {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _isRefreshing;
      });
      final newToken = await _secureStorage.getAccessToken();
      if (newToken != null) {
        final newOptions = err.requestOptions;
        newOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _dio.fetch(newOptions);
          return handler.resolve(response);
        } catch (_) {}
      }
    } catch (_) {}

    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post(
        '${Endpoints.baseUrl}${Endpoints.refreshToken}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        await _secureStorage.saveTokens(
          accessToken: response.data['accessToken'],
          refreshToken: response.data['refreshToken'],
        );
        return true;
      }
    } catch (e) {
      ErrorHandler.logError('Token refresh failed', e);
    }

    return false;
  }
}
