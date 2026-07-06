import 'package:dio/dio.dart';
import '../../utils/error_handler.dart';

class RetryInterceptor extends Interceptor {
  final int _maxRetries;
  final Set<DioExceptionType> _retryableTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  RetryInterceptor({int maxRetries = 2}) : _maxRetries = maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final retryCount = _getRetryCount(err.requestOptions);
    if (retryCount >= _maxRetries) {
      return handler.next(err);
    }

    ErrorHandler.logInfo(
      'Retrying request ${err.requestOptions.path} (attempt ${retryCount + 1}/$_maxRetries)',
    );

    final nextOptions = _incrementRetryCount(err.requestOptions);
    try {
      final response = await Dio().fetch(nextOptions);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.response != null && err.response!.statusCode != null) {
      return false;
    }
    return _retryableTypes.contains(err.type);
  }

  int _getRetryCount(RequestOptions options) {
    return (options.extra['_retryCount'] as int?) ?? 0;
  }

  RequestOptions _incrementRetryCount(RequestOptions options) {
    options.extra['_retryCount'] = _getRetryCount(options) + 1;
    return options;
  }
}
