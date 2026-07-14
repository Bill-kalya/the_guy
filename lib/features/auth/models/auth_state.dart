import 'user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final bool isAuthenticated;
  final String? error;
  final String? pendingEmail;
  final bool emailVerified;

  // Password reset flow
  final String? resetEmail;
  final bool resetOtpSent;
  final bool resetOtpVerified;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.isAuthenticated = false,
    this.error,
    this.pendingEmail,
    this.emailVerified = false,
    this.resetEmail,
    this.resetOtpSent = false,
    this.resetOtpVerified = false,
  });

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(isLoading: true);

  factory AuthState.authenticated(UserModel user) =>
      AuthState(user: user, isAuthenticated: true);

  factory AuthState.unauthenticated() => const AuthState();

  factory AuthState.emailVerificationPending(String email) =>
      AuthState(pendingEmail: email);

  factory AuthState.verified(String email) =>
      AuthState(pendingEmail: email, emailVerified: true);

  factory AuthState.forgotPasswordOtpSent(String email) =>
      AuthState(resetEmail: email, resetOtpSent: true);

  factory AuthState.resetOtpVerified(String email) =>
      AuthState(resetEmail: email, resetOtpSent: true, resetOtpVerified: true);

  factory AuthState.error(String message) => AuthState(error: message);

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    bool? isAuthenticated,
    String? error,
    String? pendingEmail,
    bool? emailVerified,
    String? resetEmail,
    bool? resetOtpSent,
    bool? resetOtpVerified,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      emailVerified: emailVerified ?? this.emailVerified,
      resetEmail: resetEmail ?? this.resetEmail,
      resetOtpSent: resetOtpSent ?? this.resetOtpSent,
      resetOtpVerified: resetOtpVerified ?? this.resetOtpVerified,
    );
  }
}