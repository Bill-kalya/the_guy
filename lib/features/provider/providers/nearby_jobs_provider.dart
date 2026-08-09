import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../home/providers/location_provider.dart';
import '../models/provider_job_model.dart';

/// Fetches open jobs near the provider's current location so they can browse
/// and accept work directly from the map (Stage 1 job discovery).
final nearbyJobsProvider = FutureProvider.autoDispose<List<ProviderJob>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final position = locationState.currentPosition;
  if (position == null) {
    throw Exception('Location not available');
  }
  // Only query with a real (fresh) GPS fix, not a cached/placeholder coordinate.
  if (!locationState.isFresh) {
    throw Exception('Waiting for GPS fix...');
  }

  final api = ref.watch(apiClientProvider);
  final response = await api.get(
    Endpoints.nearbyJobs,
    params: {
      'lat': position.latitude,
      'lng': position.longitude,
      'radius': 20000,
    },
  );

  final data = response.data;
  if (data == null) return [];

  List<dynamic> list;
  if (data is Map && data.containsKey('data')) {
    list = data['data'] as List<dynamic>;
  } else if (data is List) {
    list = data;
  } else {
    return [];
  }

  return list
      .map((item) => ProviderJob.fromJson(item as Map<String, dynamic>))
      .toList();
});
