import 'user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final bool isAuthenticated;
  final String? error;
  final String? pendingEmail;
  final bool emailVerified;
  final String? verificationToken;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.isAuthenticated = false,
    this.error,
    this.pendingEmail,
    this.emailVerified = false,
    this.verificationToken,
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

  factory AuthState.error(String message) => AuthState(error: message);

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    bool? isAuthenticated,
    String? error,
    String? pendingEmail,
    bool? emailVerified,
    String? verificationToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      emailVerified: emailVerified ?? this.emailVerified,
      verificationToken: verificationToken ?? this.verificationToken,
    );
  }
}