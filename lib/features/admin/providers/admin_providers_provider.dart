import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../shared/providers/auto_refresh_mixin.dart';

final adminProvidersProvider = NotifierProvider<AdminProvidersNotifier, AdminProvidersState>(
  AdminProvidersNotifier.new,
);

class AdminProvidersNotifier extends Notifier<AdminProvidersState> with AutoRefreshMixin<AdminProvidersState> {
  late final ApiClient _api;

  @override
  AdminProvidersState build() {
    _api = ref.watch(apiClientProvider);
    startAutoRefresh();
    return AdminProvidersState.initial();
  }

  @override
  Future<void> autoRefresh() => loadAll();

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
    } catch (e) {
      state = state.copyWith(error: 'Summary: ${e.toString()}');
    }
  }

  Future<void> _loadProviders({String? status, String? search, int page = 0}) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': 20};
      if (status != null && status != 'All') params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(Endpoints.adminProviders, params: params);
      final data = _unwrapPage(res.data);
      if (data != null) state = state.copyWith(providers: data);
    } catch (e) {
      state = state.copyWith(error: 'Providers: ${e.toString()}');
    }
  }

  Future<void> refreshWithFilters({String? status, String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadProviders(status: status, search: search);
    state = state.copyWith(isLoading: false);
  }

  Future<Map<String, dynamic>> importProviders(String csvContent) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromString(
        csvContent,
        filename: 'providers.csv',
      ),
    });
    final res = await _api.postMultipart(Endpoints.adminProvidersImport, formData);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return {'imported': 0};
  }

  Future<Map<String, dynamic>> regenerateClaimCode(String providerId) async {
    final res = await _api.post(Endpoints.adminProviderClaimCode(providerId));
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return const {};
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
