import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/websocket_service.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../../../core/network/endpoints.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final ApiClient _apiClient;
  late final SecureStorage _secureStorage;

  @override
  AuthState build() {
    _apiClient = ref.watch(apiClientProvider);
    _secureStorage = ref.watch(secureStorageProvider);
    checkAuthStatus();
    return AuthState.initial();
  }

  Future<void> loginWithPhone(String phoneNumber) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.sendOtp,
        data: {'phoneNumber': phoneNumber},
      );

      if (response.statusCode == 200) {
        state = AuthState.otpSent(phoneNumber);
      }
    } catch (e) {
      state = AuthState.error('Failed to send OTP');
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    state = AuthState.loading();

    try {
      final response = await _apiClient.post(
        Endpoints.verifyOtp,
        data: {'phoneNumber': phoneNumber, 'otp': otp},
      );

      if (response.statusCode == 200) {
        final tokens = response.data;
        await _secureStorage.saveTokens(
          accessToken: tokens['accessToken'],
          refreshToken: tokens['refreshToken'],
        );
        await _secureStorage.saveUserData(tokens['user']);

        // Connect WebSocket after successful login
        await ref.read(webSocketServiceProvider).connect();

        state = AuthState.authenticated(UserModel.fromJson(tokens['user']));
      }
    } catch (e) {
      state = AuthState.error('Invalid OTP');
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearAll();
    await ref.read(webSocketServiceProvider).disconnect();
    state = AuthState.unauthenticated();
  }

  Future<void> checkAuthStatus() async {
    final token = await _secureStorage.getAccessToken();
    final user = await _secureStorage.getUserData();

    if (token != null && user != null) {
      state = AuthState.authenticated(UserModel.fromJson(user));
      await ref.read(webSocketServiceProvider).connect();
    } else {
      state = AuthState.unauthenticated();
    }
  }
}
