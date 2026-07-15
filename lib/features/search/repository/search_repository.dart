import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../shared/models/nearby_provider_model.dart';

final searchApiServiceProvider = Provider<SearchApiService>((ref) {
  return SearchApiService(ref.read(apiClientProvider));
});

class SearchRequest {
  final String query;
  final double lat;
  final double lng;
  final int radius;
  final int page;
  final int size;

  SearchRequest({
    required this.query,
    required this.lat,
    required this.lng,
    this.radius = 10000,
    this.page = 0,
    this.size = 20,
  });

  Map<String, dynamic> toParams() => {
        'query': query,
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'page': page,
        'size': size,
      };
}

class SearchResult {
  final String query;
  final int totalResults;
  final List<NearbyProviderModel> providers;

  SearchResult({
    required this.query,
    required this.totalResults,
    required this.providers,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final list = <NearbyProviderModel>[];
    if (json['providers'] is List) {
      for (final item in json['providers']) {
        if (item is Map<String, dynamic>) {
          list.add(NearbyProviderModel.fromJson(item));
        }
      }
    }

    return SearchResult(
      query: json['query'] ?? '',
      totalResults: json['totalResults'] ?? list.length,
      providers: list,
    );
  }
}

class SearchApiService {
  final ApiClient _apiClient;

  SearchApiService(this._apiClient);

  Future<SearchResult> searchProviders(SearchRequest req) async {
    final response = await _apiClient.get(
      Endpoints.searchProviders,
      params: req.toParams(),
    );

    final data = response.data;
    if (data == null) return SearchResult(query: req.query, totalResults: 0, providers: []);

    if (data is Map<String, dynamic>) {
      return SearchResult.fromJson(data);
    }

    return SearchResult(query: req.query, totalResults: 0, providers: []);
  }

  Future<List<String>> suggestions(String q) async {
    if (q.isEmpty) return [];
    final response = await _apiClient.get(
      Endpoints.searchSuggestions,
      params: {'q': q},
    );

    final data = response.data;
    if (data == null) return [];
    if (data is List) {
      return data.whereType<String>().toList();
    }

    if (data is Map && data.containsKey('data') && data['data'] is List) {
      return (data['data'] as List).whereType<String>().toList();
    }

    return [];
  }
}
