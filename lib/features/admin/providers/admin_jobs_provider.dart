import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

final adminJobsProvider = NotifierProvider<AdminJobsNotifier, AdminJobsState>(
  AdminJobsNotifier.new,
);

class AdminJobsNotifier extends Notifier<AdminJobsState> {
  late final ApiClient _api;

  @override
  AdminJobsState build() {
    _api = ref.watch(apiClientProvider);
    return AdminJobsState.initial();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadSummary(),
        _loadJobs(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _api.get(Endpoints.adminJobsSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(summary: data);
    } catch (_) {}
  }

  Future<void> _loadJobs({String? status, String? search, int page = 0}) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': 20};
      if (status != null && status != 'All') params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(Endpoints.adminJobs, params: params);
      final data = _unwrapPage(res.data);
      if (data != null) state = state.copyWith(jobs: data);
    } catch (_) {}
  }

  Future<void> refreshWithFilters({String? status, String? search}) async {
    await _loadJobs(status: status, search: search);
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

class AdminJobsState {
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? jobs;
  final bool isLoading;
  final String? error;

  AdminJobsState({
    this.summary,
    this.jobs,
    this.isLoading = false,
    this.error,
  });

  factory AdminJobsState.initial() => AdminJobsState();

  AdminJobsState copyWith({
    Map<String, dynamic>? summary,
    Map<String, dynamic>? jobs,
    bool? isLoading,
    String? error,
  }) {
    return AdminJobsState(
      summary: summary ?? this.summary,
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
