import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

final adminProvidersProvider = NotifierProvider<AdminProvidersNotifier, AdminProvidersState>(
  AdminProvidersNotifier.new,
);

class AdminProvidersNotifier extends Notifier<AdminProvidersState> {
  late final ApiClient _api;

  @override
  AdminProvidersState build() {
    _api = ref.watch(apiClientProvider);
    return AdminProvidersState.initial();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadSummary(),
        _loadProviders(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _api.get(Endpoints.adminProvidersSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(summary: data);
    } catch (_) {}
  }

  Future<void> _loadProviders({String? status, String? search, int page = 0}) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': 20};
      if (status != null && status != 'All') params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(Endpoints.adminProviders, params: params);
      final data = _unwrapPage(res.data);
      if (data != null) state = state.copyWith(providers: data);
    } catch (_) {}
  }

  Future<void> refreshWithFilters({String? status, String? search}) async {
    await _loadProviders(status: status, search: search);
  }

  Map<String, dynamic>? _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    }
    return data is Map<String, dynamic> ? data : null;
  }

  Map<String, dynamic>? _unwrapPage(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    }
    return data is Map<String, dynamic> ? data : null;
  }
}

class AdminProvidersState {
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? providers;
  final bool isLoading;
  final String? error;

  AdminProvidersState({
    this.summary,
    this.providers,
    this.isLoading = false,
    this.error,
  });

  factory AdminProvidersState.initial() => AdminProvidersState();

  AdminProvidersState copyWith({
    Map<String, dynamic>? summary,
    Map<String, dynamic>? providers,
    bool? isLoading,
    String? error,
  }) {
    return AdminProvidersState(
      summary: summary ?? this.summary,
      providers: providers ?? this.providers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
