import 'package:flutter/material.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/app_exception.dart';

void showErrorSnackBar(BuildContext context, dynamic error) {
  String title;
  String message;

  if (error is AppException) {
    final mapped = ErrorMapper.map(error.code);
    title = mapped.title;
    message = mapped.message;
  } else {
    title = 'Error';
    message = error.toString();
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontSize: 13)),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
