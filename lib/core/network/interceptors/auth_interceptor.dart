import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../endpoints.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  late final Dio _dio;

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
    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newToken = await _secureStorage.getAccessToken();
        final newOptions = err.requestOptions;
        newOptions.headers['Authorization'] = 'Bearer $newToken';

        try {
          final response = await _dio.fetch(newOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Force logout
        await _secureStorage.clearAll();
        return handler.reject(err);
      }
    }

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
      return false;
    }

    return false;
  }
}
