import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/env.dart';

class ErrorHandler {
  static void logError(String message, [dynamic error, StackTrace? stack]) {
    if (Env.isDevelopment || kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) debugPrint('   Error: $error');
      if (stack != null) debugPrint('   Stack: $stack');
    }
  }

  static void logInfo(String message) {
    if (Env.isDevelopment || kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }
  // Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    String message, {
    String title = 'Error',
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onRetry != null) onRetry();
            },
            child: Text(onRetry != null ? 'Retry' : 'OK'),
          ),
          if (onRetry == null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show info snackbar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Parse error message from exception
  static String parseErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception:', '').trim();
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Get user-friendly error message
  static String getUserFriendlyMessage(String errorCode) {
    switch (errorCode) {
      case 'network_error':
        return 'No internet connection. Please check your network and try again.';
      case 'timeout':
        return 'Request timed out. Please try again.';
      case 'server_error':
        return 'Server error. Please try again later.';
      case 'unauthorized':
        return 'Session expired. Please login again.';
      case 'not_found':
        return 'Resource not found.';
      case 'invalid_input':
        return 'Invalid input. Please check your information.';
      case 'payment_failed':
        return 'Payment failed. Please try again or use another method.';
      case 'no_providers':
        return 'No providers available in your area. Please try again later.';
      case 'job_already_taken':
        return 'This job has already been taken by another provider.';
      case 'location_permission_denied':
        return 'Location permission is required to use this feature.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // Handle common exceptions
  static String handleException(dynamic exception) {
    if (exception.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (exception.toString().contains('Timeout')) {
      return 'Connection timeout. Please try again.';
    } else if (exception.toString().contains('401')) {
      return 'Session expired. Please login again.';
    } else if (exception.toString().contains('403')) {
      return 'You don\'t have permission to perform this action.';
    } else if (exception.toString().contains('404')) {
      return 'Resource not found.';
    } else if (exception.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else {
      return parseErrorMessage(exception);
    }
  }
}
