import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _storage.write(key: 'user_id', value: user['id'].toString());
    await _storage.write(key: 'user_role', value: user['role']);
    await _storage.write(key: 'user_data', value: jsonEncode(user));
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: 'user_data');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ── Impersonation ──────────────────────────────────────

  Future<void> saveAdminSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    await _storage.write(key: 'admin_access_token', value: accessToken);
    await _storage.write(key: 'admin_refresh_token', value: refreshToken);
    await _storage.write(key: 'admin_user_data', value: jsonEncode(userData));
  }

  Future<String?> getAdminAccessToken() async {
    return await _storage.read(key: 'admin_access_token');
  }

  Future<String?> getAdminRefreshToken() async {
    return await _storage.read(key: 'admin_refresh_token');
  }

  Future<Map<String, dynamic>?> getAdminUserData() async {
    final data = await _storage.read(key: 'admin_user_data');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> saveImpersonationToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'is_impersonating', value: 'true');
  }

  Future<bool> isImpersonating() async {
    return await _storage.read(key: 'is_impersonating') == 'true';
  }

  Future<void> clearImpersonation() async {
    await _storage.delete(key: 'is_impersonating');
  }

  Future<void> clearAdminSession() async {
    await _storage.delete(key: 'admin_access_token');
    await _storage.delete(key: 'admin_refresh_token');
    await _storage.delete(key: 'admin_user_data');
  }
}
