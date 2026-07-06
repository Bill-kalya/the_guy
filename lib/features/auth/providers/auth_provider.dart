import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/error_handler.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../../../core/network/endpoints.dart';

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
        // Registration successful - email verification pending
        state = AuthState.emailVerificationPending(email);
      }
    } catch (e) {
      ErrorHandler.logError('Registration failed', e);
      state = AuthState.error('Registration failed. Please try again.');
    }
  }

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
        final data = response.data;
        await _secureStorage.saveTokens(
          accessToken: data['accessToken'] ?? data['token'],
          refreshToken: data['refreshToken'],
        );
        await _secureStorage.saveUserData(data['user']);

        await ref.read(webSocketServiceProvider).connect();

        state = AuthState.authenticated(UserModel.fromJson(data['user']));
      }
    } catch (e) {
      ErrorHandler.logError('Login failed', e);
      state = AuthState.error('Invalid email or password. Please try again.');
    }
  }

  Future<void> verifyEmail(String email, String otp) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.verifyEmail,
        data: {'email': email, 'token': otp},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _secureStorage.saveTokens(
          accessToken: data['accessToken'] ?? data['token'],
          refreshToken: data['refreshToken'],
        );
        await _secureStorage.saveUserData(data['user']);

        await ref.read(webSocketServiceProvider).connect();

        state = AuthState.authenticated(UserModel.fromJson(data['user']));
      }
    } catch (e) {
      ErrorHandler.logError('Email verification failed', e);
      state = AuthState.error('Invalid or expired verification code. Please try again.');
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _apiClient.post(
        Endpoints.resendVerification,
        data: {'email': email},
      );
    } catch (e) {
      ErrorHandler.logError('Failed to resend verification', e);
      state = AuthState.error('Failed to resend verification email.');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(Endpoints.logout);
    } catch (_) {}
    await _secureStorage.clearAll();
    await ref.read(webSocketServiceProvider).disconnect();
    state = AuthState.unauthenticated();
  }

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
      // Token might be expired; try refresh via the auth interceptor
      // If we still have stored user data, optimistically authenticate
      try {
        final user = UserModel.fromJson(userData);
        state = AuthState.authenticated(user);
      } catch (_) {
        state = AuthState.unauthenticated();
      }
    }
  }
}