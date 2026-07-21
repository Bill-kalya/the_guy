import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/network/endpoints.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final ApiClient _apiClient;
  late final SecureStorage _secureStorage;
  bool _initialCheckDone = false;

  @override
  AuthState build() {
    _apiClient = ref.watch(apiClientProvider);
    _secureStorage = ref.watch(secureStorageProvider);
    if (!_initialCheckDone) {
      _initialCheckDone = true;
      checkAuthStatus();
    }
    return AuthState.initial();
  }

  // ──────────────────────────────────────────
  // Registration (OTP-based email verification)
  // ──────────────────────────────────────────
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    double? latitude,
    double? longitude,
  }) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 201) {
        final otpSent = response.data['data']?['otpSent'] ?? true;
        state = AuthState.emailVerificationPending(email, otpSent: otpSent);
      }
    } catch (e) {
      ErrorHandler.logError('Registration failed', e);
      state = AuthState.error('Registration failed. Please try again.');
    }
  }

  // ──────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────
  Future<void> loginWithEmail(String email, String password) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        await _persistSession(response.data);
        return;
      }

      if (response.statusCode == 403 &&
          response.data?['message'] == 'EMAIL_NOT_VERIFIED') {
        state = AuthState.emailVerificationPending(email);
        return;
      }

      state = AuthState.error(
        response.data?['message'] ?? 'Invalid email or password.',
      );
    } catch (e) {
      ErrorHandler.logError('Login failed', e);
      state = AuthState.error('Invalid email or password. Please try again.');
    }
  }

  // ──────────────────────────────────────────
  // Email Verification (OTP)
  // ──────────────────────────────────────────
  Future<void> verifyEmail(String email, String otp) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.verifyEmail,
        data: {'email': email, 'otp': otp},
      );

      if (response.statusCode == 200) {
        await _persistSession(response.data);
        return;
      }

      state = AuthState.error(
        response.data?['message'] ??
            'Invalid or expired verification code. Please try again.',
      );
    } catch (e) {
      ErrorHandler.logError('Email verification failed', e);
      state = AuthState.error(
        'Invalid or expired verification code. Please try again.',
      );
    }
  }

  // ──────────────────────────────────────────
  // Resend OTP (email verification)
  // ──────────────────────────────────────────
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _apiClient.post(
        Endpoints.resendVerification,
        data: {'email': email},
      );
    } catch (e) {
      ErrorHandler.logError('Failed to resend verification', e);
      state = AuthState.error(
        'Too many requests. Please wait before resending.',
      );
    }
  }

  // ──────────────────────────────────────────
  // Forgot Password — send OTP
  // ──────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        state = AuthState.forgotPasswordOtpSent(email);
      }
    } catch (e) {
      ErrorHandler.logError('Forgot password request failed', e);
      state = AuthState.error(
        'Failed to send reset code. Please check your email is correct.',
      );
    }
  }

  // ──────────────────────────────────────────
  // Verify Reset OTP
  // ──────────────────────────────────────────
  Future<void> verifyResetOtp(String email, String otp) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.verifyResetOtp,
        data: {'email': email, 'otp': otp},
      );

      if (response.statusCode == 200) {
        state = AuthState.resetOtpVerified(email);
      }
    } catch (e) {
      ErrorHandler.logError('Reset OTP verification failed', e);
      state = AuthState.error(
        'Invalid or expired reset code. Please try again.',
      );
    }
  }

  // ──────────────────────────────────────────
  // Resend Reset OTP
  // ──────────────────────────────────────────
  Future<void> resendResetOtp(String email) async {
    try {
      await _apiClient.post(
        Endpoints.forgotPassword,
        data: {'email': email},
      );
    } catch (e) {
      ErrorHandler.logError('Failed to resend reset OTP', e);
      state = AuthState.error(
        'Too many requests. Please wait before resending.',
      );
    }
  }

  // ──────────────────────────────────────────
  // Reset Password (after OTP verified)
  // ──────────────────────────────────────────
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.resetPassword,
        data: {
          'email': email,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        // Password reset successful — navigate to login
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      ErrorHandler.logError('Password reset failed', e);
      state = AuthState.error(
        'Failed to reset password. Please try again.',
      );
    }
  }

  // ──────────────────────────────────────────
  // Session persistence (shared by login + verify-email)
  // ──────────────────────────────────────────
  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _secureStorage.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );
    final user = UserModel(
      id: data['userId'] ?? data['id'],
      name: data['fullName'] ?? data['name'],
      phone: data['phone'] ?? '',
      email: data['email'],
      role: data['role'],
      isVerified: data['verified'] ?? data['isVerified'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
    await _secureStorage.saveUserData(user.toJson());
    await ref.read(webSocketServiceProvider).connect();
    state = AuthState.authenticated(user);
  }

  // ──────────────────────────────────────────
  // Update user in state (after profile edit)
  // ──────────────────────────────────────────
  void updateUser(UserModel user) {
    state = AuthState.authenticated(user);
    _secureStorage.saveUserData(user.toJson());
  }

  // ──────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _apiClient.post(Endpoints.logout);
    } catch (_) {}
    await _secureStorage.clearAll();
    await ref.read(webSocketServiceProvider).disconnect();
    state = AuthState.unauthenticated();
  }

  // ──────────────────────────────────────────
  // Check persisted auth status
  // ──────────────────────────────────────────
  Future<void> checkAuthStatus() async {
    final token = await _secureStorage.getAccessToken();
    final userData = await _secureStorage.getUserData();

    if (token == null || userData == null) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final response = await _apiClient.get(Endpoints.userProfile);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        state = AuthState.authenticated(user);
        await ref.read(webSocketServiceProvider).connect();
        return;
      }
    } catch (e) {
      // AuthInterceptor already handles 401 refresh + storage cleanup.
      // If we get here, the session is dead — don't fall back to stale local data.
      await _secureStorage.clearAll();
    }

    state = AuthState.unauthenticated();
  }
}