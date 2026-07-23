class AppException implements Exception {
  final String code;
  final String message;
  final List<FieldError>? fieldErrors;

  AppException({
    required this.code,
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'AppException($code): $message';
}

class FieldError {
  final String field;
  final String code;
  final String message;

  FieldError({required this.field, required this.code, required this.message});
}
