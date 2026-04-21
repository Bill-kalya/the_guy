import 'user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final bool isAuthenticated;
  final String? error;
  final String? pendingPhoneNumber;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.isAuthenticated = false,
    this.error,
    this.pendingPhoneNumber,
  });

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(isLoading: true);

  factory AuthState.authenticated(UserModel user) =>
      AuthState(user: user, isAuthenticated: true);

  factory AuthState.unauthenticated() => const AuthState();

  factory AuthState.otpSent(String phoneNumber) =>
      AuthState(pendingPhoneNumber: phoneNumber);

  factory AuthState.error(String message) => AuthState(error: message);

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    bool? isAuthenticated,
    String? error,
    String? pendingPhoneNumber,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      pendingPhoneNumber: pendingPhoneNumber ?? this.pendingPhoneNumber,
    );
  }
}
