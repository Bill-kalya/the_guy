import 'package:dio/dio.dart';
import '../../errors/app_exception.dart';
import '../../errors/error_codes.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _mapToAppException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
        message: appException.message,
      ),
    );
  }

  AppException _mapToAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppException(
          code: ErrorCodes.networkError,
          message: 'No internet connection. Check your network and try again.',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(err.response);

      case DioExceptionType.cancel:
        return AppException(
          code: ErrorCodes.networkError,
          message: 'Request was cancelled.',
        );

      default:
        return AppException(
          code: ErrorCodes.serverError,
          message: 'Something went wrong. Please try again.',
        );
    }
  }

  AppException _handleBadResponse(Response? response) {
    if (response == null) {
      return AppException(
        code: ErrorCodes.serverError,
        message: 'No response from server.',
      );
    }

    final statusCode = response.statusCode;
    final data = response.data;

    if (statusCode == 429) {
      return AppException(
        code: ErrorCodes.rateLimited,
        message: 'Too many requests. Please wait a moment before trying again.',
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return AppException(
        code: ErrorCodes.serverError,
        message: 'Server error. Please try again later.',
      );
    }

    if (data is Map<String, dynamic>) {
      final errorCode = data['errorCode'] as String? ??
          data['error_code'] as String? ??
          _statusCodeToCode(statusCode);
      final message = data['message'] as String? ??
          data['error'] as String? ??
          'Something went wrong.';

      List<FieldError>? fieldErrors;
      if (data['fieldErrors'] is List) {
        fieldErrors = (data['fieldErrors'] as List)
            .map((e) => FieldError(
                  field: e['field'] as String? ?? '',
                  code: e['code'] as String? ?? '',
                  message: e['message'] as String? ?? '',
                ))
            .toList();
      } else if (data['field_errors'] is List) {
        fieldErrors = (data['field_errors'] as List)
            .map((e) => FieldError(
                  field: e['field'] as String? ?? '',
                  code: e['code'] as String? ?? '',
                  message: e['message'] as String? ?? '',
                ))
            .toList();
      }

      return AppException(
        code: errorCode,
        message: message,
        fieldErrors: fieldErrors,
      );
    }

    return AppException(
      code: _statusCodeToCode(statusCode),
      message: _statusCodeToMessage(statusCode),
    );
  }

  String _statusCodeToCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return ErrorCodes.validationFailed;
      case 401:
        return ErrorCodes.unauthorized;
      case 403:
        return ErrorCodes.forbidden;
      case 404:
        return ErrorCodes.notFound;
      default:
        return ErrorCodes.serverError;
    }
  }

  String _statusCodeToMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
