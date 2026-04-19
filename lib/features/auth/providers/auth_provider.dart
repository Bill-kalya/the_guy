import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/auth_state.dart';
import '../../../core/network/endpoints.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiClient, secureStorage, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  final Ref _ref;
  
  AuthNotifier(this._apiClient, this._secureStorage, this._ref) 
      : super(const AuthState.initial());
  
  Future<void> loginWithPhone(String phoneNumber) async {
    state = const AuthState.loading();
    
    try {
      final response = await _apiClient.post(Endpoints.sendOtp, data: {
        'phoneNumber': phoneNumber,
      });
      
      if (response.statusCode == 200) {
        state = AuthState.otpSent(phoneNumber);
      }
    } catch (e) {
      state = AuthState.error('Failed to send OTP');
    }
  }
  
  Future<void> verifyOtp(String phoneNumber, String otp) async {
    state = const AuthState.loading();
    
    try {
      final response = await _apiClient.post(Endpoints.verifyOtp, data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });
      
      if (response.statusCode == 200) {
        final tokens = response.data;
        await _secureStorage.saveTokens(
          accessToken: tokens['accessToken'],
          refreshToken: tokens['refreshToken'],
        );
        await _secureStorage.saveUserData(tokens['user']);
        
        // Connect WebSocket after successful login
        await _ref.read(webSocketServiceProvider).connect();
        
        state = AuthState.authenticated(tokens['user']);
      }
    } catch (e) {
      state = AuthState.error('Invalid OTP');
    }
  }
  
  Future<void> logout() async {
    await _secureStorage.clearAll();
    await _ref.read(webSocketServiceProvider).disconnect();
    state = const AuthState.unauthenticated();
  }
  
  Future<void> checkAuthStatus() async {
    final token = await _secureStorage.getAccessToken();
    final user = await _secureStorage.getUserData();
    
    if (token != null && user != null) {
      state = AuthState.authenticated(user);
      await _ref.read(webSocketServiceProvider).connect();
    } else {
      state = const AuthState.unauthenticated();
    }
  }
}