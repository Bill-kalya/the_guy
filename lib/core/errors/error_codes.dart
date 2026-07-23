class ErrorCodes {
  ErrorCodes._();

  static const emailExists = 'EMAIL_EXISTS';
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const accountLocked = 'ACCOUNT_LOCKED';
  static const accountSuspended = 'ACCOUNT_SUSPENDED';
  static const otpExpired = 'OTP_EXPIRED';
  static const otpInvalid = 'OTP_INVALID';
  static const emailNotVerified = 'EMAIL_NOT_VERIFIED';

  static const validationFailed = 'VALIDATION_FAILED';
  static const passwordWeak = 'PASSWORD_WEAK';
  static const emailInvalid = 'EMAIL_INVALID';
  static const phoneInvalid = 'PHONE_INVALID';

  static const providerOffline = 'PROVIDER_OFFLINE';
  static const providerBusy = 'PROVIDER_BUSY';
  static const verificationRequired = 'VERIFICATION_REQUIRED';

  static const bookingConflict = 'BOOKING_CONFLICT';
  static const jobNotFound = 'JOB_NOT_FOUND';

  static const paymentFailed = 'PAYMENT_FAILED';
  static const insufficientFunds = 'INSUFFICIENT_FUNDS';
  static const paymentCancelled = 'PAYMENT_CANCELLED';
  static const paymentTimeout = 'PAYMENT_TIMEOUT';

  static const networkError = 'NETWORK_ERROR';
  static const serverError = 'SERVER_ERROR';
  static const rateLimited = 'RATE_LIMITED';
  static const notFound = 'NOT_FOUND';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
}
