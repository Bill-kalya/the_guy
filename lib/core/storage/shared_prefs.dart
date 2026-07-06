import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

final sharedPrefsProvider = Provider<SharedPrefs>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefs(prefs);
});

class SharedPrefs {
  final SharedPreferences _prefs;

  SharedPrefs(this._prefs);

  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool('is_first_launch', value);
  }

  bool isFirstLaunch() {
    return _prefs.getBool('is_first_launch') ?? true;
  }

  Future<void> setLastLocation(double lat, double lng) async {
    await _prefs.setDouble('last_lat', lat);
    await _prefs.setDouble('last_lng', lng);
  }

  double? getLastLatitude() {
    return _prefs.getDouble('last_lat');
  }

  double? getLastLongitude() {
    return _prefs.getDouble('last_lng');
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    await _prefs.setBool('notifications_enabled', enabled);
  }

  bool isNotificationEnabled() {
    return _prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}