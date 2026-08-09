import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/storage/shared_prefs.dart';

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);

class LocationNotifier extends Notifier<LocationState> {
  late final SharedPrefs _sharedPrefs;
  StreamSubscription<Position>? _streamSub;
  double? _lastAccuracy;
  Position? _lastAccepted;

  @override
  LocationState build() {
    _sharedPrefs = ref.watch(sharedPrefsProvider);
    ref.onDispose(() => _streamSub?.cancel());

    final lat = _sharedPrefs.getLastLatitude();
    final lng = _sharedPrefs.getLastLongitude();

    if (lat != null && lng != null) {
      return LocationState(
        currentPosition: Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
        // Cached position is only a warm-start hint; don't query the API with it.
        isFresh: false,
      );
    }

    return LocationState.initial();
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true);

    final position = await LocationUtils.getCurrentLocation();

    if (position != null) {
      _sharedPrefs.setLastLocation(position.latitude, position.longitude);
      state = state.copyWith(
        currentPosition: position,
        isFresh: true,
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to get location. Please enable GPS.',
      );
    }

    // Keep listening for finer fixes so the map converges on the true
    // location instead of freezing at the first (possibly coarse) one.
    _startWatching();
  }

  void _startWatching() {
    _streamSub?.cancel();
    _streamSub = null;
    try {
      _streamSub = LocationUtils.getPositionStream().listen(
        (position) {
          _acceptFix(position);
        },
        onError: (_) {
          // The single-shot already reported failures; keep the stream alive.
        },
      );
    } catch (_) {
      // Location stream not supported; single-shot result still applies.
    }
  }

  /// Decide whether a new GPS fix is worth keeping. The first fix is always
  /// accepted; later ones only when they improve accuracy enough or move a
  /// meaningful distance, so coarse network blips and jitter don't fight the
  /// map or spam the nearby-providers query.
  void _acceptFix(Position position) {
    if (position.accuracy > 0 && position.accuracy > 200) return;

    final last = _lastAccepted;
    if (last != null) {
      final accuracyImproved = position.accuracy > 0 &&
          position.accuracy < (_lastAccuracy ?? position.accuracy) * 0.9;
      final moved = _distanceBetween(last, position);
      // Stay with the current fix unless accuracy meaningfully improved or the
      // user actually moved (jitter threshold below).
      if (!accuracyImproved && moved < 15) return;
    }

    _lastAccepted = position;
    _lastAccuracy = position.accuracy > 0 ? position.accuracy : _lastAccuracy;
    _sharedPrefs.setLastLocation(position.latitude, position.longitude);
    state = state.copyWith(
      currentPosition: position,
      isFresh: true,
      isLoading: false,
      error: null,
    );
  }

  static double _distanceBetween(Position a, Position b) {
    const earthRadiusM = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = _hav(dLat) + _cos(a.latitude) * _cos(b.latitude) * _hav(dLng);
    return 2 * earthRadiusM * asin(sqrt(h));
  }

  static double _rad(double deg) => deg * 3.141592653589793 / 180.0;
  static double _hav(double rad) => (1 - cos(rad)) / 2;
  static double _cos(double deg) => cos(_rad(deg));

  void stopLocationUpdates() {
    _streamSub?.cancel();
    _streamSub = null;
  }

  void updateLocation(Position position) {
    state = state.copyWith(currentPosition: position, isFresh: true);
  }
}

class LocationState {
  final Position? currentPosition;
  final bool isLoading;
  final String? error;
  final bool isFresh;

  LocationState({
    this.currentPosition,
    this.isLoading = false,
    this.error,
    this.isFresh = false,
  });

  factory LocationState.initial() {
    return LocationState();
  }

  LocationState copyWith({
    Position? currentPosition,
    bool? isLoading,
    String? error,
    bool? isFresh,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFresh: isFresh ?? this.isFresh,
    );
  }
}
