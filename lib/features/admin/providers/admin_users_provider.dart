import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

final adminUsersProvider = NotifierProvider<AdminUsersNotifier, AdminUsersState>(
  AdminUsersNotifier.new,
);

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  late final ApiClient _api;

  @override
  AdminUsersState build() {
    _api = ref.watch(apiClientProvider);
    return AdminUsersState.initial();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadSummary(),
        _loadRiskOverview(),
        _loadUsers(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _api.get(Endpoints.adminUsersSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(summary: data);
    } catch (_) {}
  }

  Future<void> _loadRiskOverview() async {
    try {
      final res = await _api.get(Endpoints.adminUsersRiskOverview);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(riskOverview: data);
    } catch (_) {}
  }

  Future<void> _loadUsers({String? role, String? search, int page = 0}) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': 20};
      if (role != null && role != 'All') params['role'] = role;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(Endpoints.adminUsers, params: params);
      final data = _unwrapPage(res.data);
      if (data != null) state = state.copyWith(users: data);
    } catch (_) {}
  }

  Future<void> refreshWithFilters({String? role, String? search}) async {
    await _loadUsers(role: role, search: search);
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

class AdminUsersState {
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? riskOverview;
  final Map<String, dynamic>? users;
  final bool isLoading;
  final String? error;

  AdminUsersState({
    this.summary,
    this.riskOverview,
    this.users,
    this.isLoading = false,
    this.error,
  });

  factory AdminUsersState.initial() => AdminUsersState();

  AdminUsersState copyWith({
    Map<String, dynamic>? summary,
    Map<String, dynamic>? riskOverview,
    Map<String, dynamic>? users,
    bool? isLoading,
    String? error,
  }) {
    return AdminUsersState(
      summary: summary ?? this.summary,
      riskOverview: riskOverview ?? this.riskOverview,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
