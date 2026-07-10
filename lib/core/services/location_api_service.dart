import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/endpoints.dart';
import '../../shared/models/nearby_provider_model.dart';

final locationApiServiceProvider = Provider<LocationApiService>((ref) {
  return LocationApiService(ref.read(apiClientProvider));
});

class LocationApiService {
  final ApiClient _apiClient;

  LocationApiService(this._apiClient);

  /// Fetch nearby providers from the backend
  Future<List<NearbyProviderModel>> getNearbyProviders({
    required double lat,
    required double lng,
    double radius = 5000,
    String? category,
  }) async {
    final params = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'radius': radius,
    };
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }

    final response = await _apiClient.get(
      Endpoints.nearbyProviders,
      params: params,
    );

    final data = response.data;
    if (data == null) return [];

    // Handle wrapped API response: { "success": true, "data": [...] }
    List<dynamic> list;
    if (data is Map && data.containsKey('data')) {
      list = data['data'] as List<dynamic>;
    } else if (data is List) {
      list = data;
    } else {
      return [];
    }

    return list
        .map((item) => NearbyProviderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Update provider's current location (called by provider app)
  Future<void> updateLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) async {
    final body = <String, dynamic>{
      'latitude': lat,
      'longitude': lng,
    };
    if (heading != null) body['heading'] = heading;
    if (speed != null) body['speed'] = speed;

    await _apiClient.post(Endpoints.updateLocation, data: body);
  }

  /// Get a specific provider's current location
  Future<ProviderLocationUpdate?> getProviderLocation(String providerId) async {
    try {
      final response = await _apiClient.get(
        '${Endpoints.providerLocation}/$providerId',
      );

      final data = response.data;
      if (data == null) return null;

      Map<String, dynamic> locationData;
      if (data is Map && data.containsKey('data')) {
        locationData = Map<String, dynamic>.from(data['data']);
      } else if (data is Map) {
        locationData = Map<String, dynamic>.from(data);
      } else {
        return null;
      }

      return ProviderLocationUpdate.fromJson(locationData);
    } catch (e) {
      return null;
    }
  }
}