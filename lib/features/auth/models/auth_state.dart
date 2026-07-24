import '../../../core/errors/app_exception.dart';
import 'user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final bool isAuthenticated;
  final String? error;
  final String? errorCode;
  final List<FieldError>? fieldErrors;
  final String? pendingEmail;
  final bool emailVerified;
  final bool otpSent;

  final String? resetEmail;
  final bool resetOtpSent;
  final bool resetOtpVerified;

  // Impersonation
  final bool isImpersonating;
  final UserModel? originalAdminUser;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.isAuthenticated = false,
    this.error,
    this.errorCode,
    this.fieldErrors,
    this.pendingEmail,
    this.emailVerified = false,
    this.otpSent = true,
    this.resetEmail,
    this.resetOtpSent = false,
    this.resetOtpVerified = false,
    this.isImpersonating = false,
    this.originalAdminUser,
  });

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(isLoading: true);

  factory AuthState.authenticated(UserModel user) =>
      AuthState(user: user, isAuthenticated: true);

  factory AuthState.unauthenticated() => const AuthState();

  factory AuthState.emailVerificationPending(String email, {bool otpSent = true}) =>
      AuthState(pendingEmail: email, otpSent: otpSent);

  factory AuthState.verified(String email) =>
      AuthState(pendingEmail: email, emailVerified: true);

  factory AuthState.forgotPasswordOtpSent(String email) =>
      AuthState(resetEmail: email, resetOtpSent: true);

  factory AuthState.resetOtpVerified(String email) =>
      AuthState(resetEmail: email, resetOtpSent: true, resetOtpVerified: true);

  factory AuthState.error(String message, {String? errorCode, List<FieldError>? fieldErrors}) =>
      AuthState(error: message, errorCode: errorCode, fieldErrors: fieldErrors);

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    bool? isAuthenticated,
    String? error,
    String? errorCode,
    List<FieldError>? fieldErrors,
    String? pendingEmail,
    bool? emailVerified,
    bool? otpSent,
    String? resetEmail,
    bool? resetOtpSent,
    bool? resetOtpVerified,
    bool? isImpersonating,
    UserModel? originalAdminUser,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      errorCode: errorCode ?? this.errorCode,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      emailVerified: emailVerified ?? this.emailVerified,
      otpSent: otpSent ?? this.otpSent,
      resetEmail: resetEmail ?? this.resetEmail,
      resetOtpSent: resetOtpSent ?? this.resetOtpSent,
      resetOtpVerified: resetOtpVerified ?? this.resetOtpVerified,
      isImpersonating: isImpersonating ?? this.isImpersonating,
      originalAdminUser: originalAdminUser ?? this.originalAdminUser,
    );
  }
}
