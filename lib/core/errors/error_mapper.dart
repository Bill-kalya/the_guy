import 'error_codes.dart';

class ErrorMapper {
  ErrorMapper._();

  static ErrorResponse map(String code, {String? details}) {
    switch (code) {
      case ErrorCodes.emailExists:
        return ErrorResponse(
          title: 'Account Already Exists',
          message: 'An account with this email already exists.',
          actionLabel: 'Sign In',
          actionRoute: '/login',
        );

      case ErrorCodes.invalidCredentials:
        return ErrorResponse(
          title: 'Incorrect Details',
          message:
              'Email or password is incorrect. Please check and try again.',
        );

      case ErrorCodes.accountLocked:
        return ErrorResponse(
          title: 'Account Locked',
          message:
              'Your account has been locked due to too many failed attempts.',
          actionLabel: 'Contact Support',
        );

      case ErrorCodes.accountSuspended:
        return ErrorResponse(
          title: 'Account Suspended',
          message:
              'Your account has been suspended. Please contact support.',
          actionLabel: 'Contact Support',
        );

      case ErrorCodes.otpExpired:
        return ErrorResponse(
          title: 'Code Expired',
          message:
              'Your verification code has expired. Please request a new one.',
          actionLabel: 'Resend Code',
        );

      case ErrorCodes.otpInvalid:
        return ErrorResponse(
          title: 'Invalid Code',
          message:
              'The code you entered is incorrect. Please try again.',
        );

      case ErrorCodes.emailNotVerified:
        return ErrorResponse(
          title: 'Email Not Verified',
          message: 'Please verify your email to continue.',
          actionLabel: 'Verify Email',
          actionRoute: '/verify-email',
        );

      case ErrorCodes.validationFailed:
        return ErrorResponse(
          title: 'Please Check Your Input',
          message: details ?? 'Some fields need your attention.',
        );

      case ErrorCodes.passwordWeak:
        return ErrorResponse(
          title: 'Password Too Weak',
          message:
              'Your password must include uppercase, lowercase, number and special character.',
        );

      case ErrorCodes.providerOffline:
        return ErrorResponse(
          title: 'Provider Unavailable',
          message: 'This provider is currently offline.',
          secondaryMessage:
              'You can book another provider or try again later.',
        );

      case ErrorCodes.providerBusy:
        return ErrorResponse(
          title: 'Provider Busy',
          message: 'This provider is currently handling another job.',
          secondaryMessage:
              'Please choose another provider or wait.',
        );

      case ErrorCodes.bookingConflict:
        return ErrorResponse(
          title: 'Booking Unavailable',
          message: 'This time slot is no longer available.',
          secondaryMessage:
              'Please select a different time or provider.',
        );

      case ErrorCodes.paymentFailed:
        return ErrorResponse(
          title: 'Payment Failed',
          message: 'We couldn\'t complete your payment.',
          secondaryMessage:
              'Possible reasons:\n\u2022 Insufficient balance\n\u2022 Incorrect M-Pesa PIN\n\u2022 Transaction cancelled',
          actionLabel: 'Try Again',
        );

      case ErrorCodes.insufficientFunds:
        return ErrorResponse(
          title: 'Insufficient Balance',
          message:
              'You don\'t have enough balance to complete this payment.',
          actionLabel: 'Top Up Wallet',
        );

      case ErrorCodes.paymentCancelled:
        return ErrorResponse(
          title: 'Payment Cancelled',
          message: 'The payment was cancelled.',
        );

      case ErrorCodes.networkError:
        return ErrorResponse(
          title: 'No Internet Connection',
          message: 'Check your network and try again.',
          actionLabel: 'Retry',
        );

      case ErrorCodes.rateLimited:
        return ErrorResponse(
          title: 'Too Many Requests',
          message:
              'Please wait a moment before trying again.',
        );

      default:
        return ErrorResponse(
          title: 'Something Went Wrong',
          message:
              'An unexpected error occurred. Please try again.',
          actionLabel: 'Retry',
        );
    }
  }
}

class ErrorResponse {
  final String title;
  final String message;
  final String? secondaryMessage;
  final String? actionLabel;
  final String? actionRoute;

  const ErrorResponse({
    required this.title,
    required this.message,
    this.secondaryMessage,
    this.actionLabel,
    this.actionRoute,
  });
}
