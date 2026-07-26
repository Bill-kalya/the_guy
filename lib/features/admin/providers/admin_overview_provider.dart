import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

final adminOverviewProvider = NotifierProvider<AdminOverviewNotifier, AdminOverviewState>(
  AdminOverviewNotifier.new,
);

class AdminOverviewNotifier extends Notifier<AdminOverviewState> {
  late final ApiClient _api;

  @override
  AdminOverviewState build() {
    _api = ref.watch(apiClientProvider);
    return AdminOverviewState.initial();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadUserSummary(),
        _loadProviderSummary(),
        _loadFinanceSummary(),
        _loadJobsSummary(),
        _loadSafetySummary(),
        _loadAuditLogs(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadUserSummary() async {
    try {
      final res = await _api.get(Endpoints.adminUsersSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(userSummary: data);
    } catch (_) {}
  }

  Future<void> _loadProviderSummary() async {
    try {
      final res = await _api.get(Endpoints.adminProvidersSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(providerSummary: data);
    } catch (_) {}
  }

  Future<void> _loadFinanceSummary() async {
    try {
      final res = await _api.get(Endpoints.adminFinanceSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(financeSummary: data);
    } catch (_) {}
  }

  Future<void> _loadJobsSummary() async {
    try {
      final res = await _api.get(Endpoints.adminJobsSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(jobsSummary: data);
    } catch (_) {}
  }

  Future<void> _loadSafetySummary() async {
    try {
      final res = await _api.get(Endpoints.adminSafetySummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(safetySummary: data);
    } catch (_) {}
  }

  Future<void> _loadAuditLogs() async {
    try {
      final res = await _api.get('${Endpoints.adminAuditLogs}?size=10');
      final data = _unwrapPage(res.data);
      if (data != null) state = state.copyWith(auditLogs: data);
    } catch (_) {}
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

class AdminOverviewState {
  final Map<String, dynamic>? userSummary;
  final Map<String, dynamic>? providerSummary;
  final Map<String, dynamic>? financeSummary;
  final Map<String, dynamic>? jobsSummary;
  final Map<String, dynamic>? safetySummary;
  final Map<String, dynamic>? auditLogs;
  final bool isLoading;
  final String? error;

  AdminOverviewState({
    this.userSummary,
    this.providerSummary,
    this.financeSummary,
    this.jobsSummary,
    this.safetySummary,
    this.auditLogs,
    this.isLoading = false,
    this.error,
  });

  factory AdminOverviewState.initial() => AdminOverviewState();

  AdminOverviewState copyWith({
    Map<String, dynamic>? userSummary,
    Map<String, dynamic>? providerSummary,
    Map<String, dynamic>? financeSummary,
    Map<String, dynamic>? jobsSummary,
    Map<String, dynamic>? safetySummary,
    Map<String, dynamic>? auditLogs,
    bool? isLoading,
    String? error,
  }) {
    return AdminOverviewState(
      userSummary: userSummary ?? this.userSummary,
      providerSummary: providerSummary ?? this.providerSummary,
      financeSummary: financeSummary ?? this.financeSummary,
      jobsSummary: jobsSummary ?? this.jobsSummary,
      safetySummary: safetySummary ?? this.safetySummary,
      auditLogs: auditLogs ?? this.auditLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
