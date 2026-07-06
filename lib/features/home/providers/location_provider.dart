import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/storage/shared_prefs.dart';

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);

class LocationNotifier extends Notifier<LocationState> {
  late final SharedPrefs _sharedPrefs;

  @override
  LocationState build() {
    _sharedPrefs = ref.watch(sharedPrefsProvider);

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
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to get location. Please enable GPS.',
      );
    }
  }

  void updateLocation(Position position) {
    state = state.copyWith(currentPosition: position);
  }
}

class LocationState {
  final Position? currentPosition;
  final bool isLoading;
  final String? error;

  LocationState({this.currentPosition, this.isLoading = false, this.error});

  factory LocationState.initial() {
    return LocationState();
  }

  LocationState copyWith({
    Position? currentPosition,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
