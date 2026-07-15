import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/search_repository.dart';

final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, q) async {
  final service = ref.read(searchApiServiceProvider);
  return service.suggestions(q);
});

final searchResultsProvider = FutureProvider.family<SearchResult, SearchRequest>((ref, req) async {
  final service = ref.read(searchApiServiceProvider);
  return service.searchProviders(req);
});
