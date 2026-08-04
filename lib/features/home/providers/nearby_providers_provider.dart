import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/location_api_service.dart';
import '../../../shared/models/nearby_provider_model.dart';
import 'location_provider.dart';

/// Provider that fetches nearby providers based on current location
final nearbyProvidersProvider = FutureProvider<List<NearbyProviderModel>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final position = locationState.currentPosition;
  if (position == null) {
    throw Exception('Location not available');
  }
  // Only query with a real (fresh) GPS fix, not a cached/placeholder coordinate.
  if (!locationState.isFresh) {
    throw Exception('Waiting for GPS fix...');
  }

  final service = ref.watch(locationApiServiceProvider);
  return await service.getNearbyProviders(
    lat: position.latitude,
    lng: position.longitude,
    radius: 20000,
  );
});

/// Provider that fetches nearby providers filtered by category
final nearbyProvidersByCategoryProvider = FutureProvider.family<List<NearbyProviderModel>, String>((ref, category) async {
  final locationState = ref.watch(locationProvider);
  final position = locationState.currentPosition;
  if (position == null) {
    throw Exception('Location not available');
  }
  if (!locationState.isFresh) {
    throw Exception('Waiting for GPS fix...');
  }

  final service = ref.watch(locationApiServiceProvider);
  return await service.getNearbyProviders(
    lat: position.latitude,
    lng: position.longitude,
    radius: 20000,
    category: category,
  );
});

/// State notifier that holds live provider location updates from WebSocket
class ProviderLocationsNotifier extends StateNotifier<Map<String, ProviderLocationUpdate>> {
  ProviderLocationsNotifier() : super({});

  void updateLocation(ProviderLocationUpdate location) {
    state = {...state, location.providerId: location};
  }

  void removeProvider(String providerId) {
    final newState = Map<String, ProviderLocationUpdate>.from(state);
    newState.remove(providerId);
    state = newState;
  }

  ProviderLocationUpdate? getProviderLocation(String providerId) {
    return state[providerId];
  }

  void clear() {
    state = {};
  }
}

final providerLocationsProvider = StateNotifierProvider<ProviderLocationsNotifier, Map<String, ProviderLocationUpdate>>((ref) {
  return ProviderLocationsNotifier();
});