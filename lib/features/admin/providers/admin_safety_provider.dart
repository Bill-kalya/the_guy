import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

final adminSafetyProvider = NotifierProvider<AdminSafetyNotifier, AdminSafetyState>(
  AdminSafetyNotifier.new,
);

class AdminSafetyNotifier extends Notifier<AdminSafetyState> {
  late final ApiClient _apiClient;

  @override
  AdminSafetyState build() {
    _apiClient = ref.watch(apiClientProvider);
    return AdminSafetyState.initial();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.wait([
        fetchSummary(),
        fetchAlerts(),
        fetchHeatmap(),
        fetchModerationQueue(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchSummary() async {
    try {
      final response = await _apiClient.get(Endpoints.adminSafetySummary);
      if (response.statusCode == 200) {
        final data = response.data;
        final summary = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        state = state.copyWith(summary: summary);
      }
    } catch (e) {
      // Non-critical
    }
  }

  Future<void> fetchAlerts() async {
    try {
      final response = await _apiClient.get('${Endpoints.adminSafetyAlerts}?limit=10');
      if (response.statusCode == 200) {
        final data = response.data;
        final alerts = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as List<dynamic>
            : data as List<dynamic>;
        state = state.copyWith(alerts: alerts.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      // Non-critical
    }
  }

  Future<void> fetchHeatmap() async {
    try {
      final response = await _apiClient.get(Endpoints.adminSafetyHeatmap);
      if (response.statusCode == 200) {
        final data = response.data;
        final heatmap = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as List<dynamic>
            : data as List<dynamic>;
        state = state.copyWith(heatmap: heatmap.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      // Non-critical
    }
  }

  Future<void> fetchModerationQueue({String? status}) async {
    try {
      final url = status != null
          ? '${Endpoints.adminSafetyModerationQueue}?status=$status&size=20'
          : '${Endpoints.adminSafetyModerationQueue}?size=20';
      final response = await _apiClient.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        final body = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        final content = body['content'] as List<dynamic>? ?? [];
        final total = body['totalElements'] as int? ?? 0;
        state = state.copyWith(
          moderationQueue: content.cast<Map<String, dynamic>>(),
          moderationTotal: total,
        );
      }
    } catch (e) {
      // Non-critical
    }
  }

  Future<bool> suspendProvider(String providerId, {String reason = 'Suspended by admin'}) async {
    try {
      final response = await _apiClient.post(
        EndpointBuilder.adminSuspendProvider(providerId),
        data: {'reason': reason},
      );
      if (response.statusCode == 200) {
        await fetchModerationQueue();
        return true;
      }
    } catch (e) {
      state = state.copyWith(actionError: 'Failed to suspend provider');
    }
    return false;
  }

  Future<bool> banProvider(String providerId, {String reason = 'Banned by admin'}) async {
    try {
      final response = await _apiClient.post(
        EndpointBuilder.adminBanProvider(providerId),
        data: {'reason': reason},
      );
      if (response.statusCode == 200) {
        await fetchModerationQueue();
        return true;
      }
    } catch (e) {
      state = state.copyWith(actionError: 'Failed to ban provider');
    }
    return false;
  }

  Future<bool> reinstateProvider(String providerId, {String reason = 'Reinstated by admin'}) async {
    try {
      final response = await _apiClient.post(
        EndpointBuilder.adminReinstateProvider(providerId),
        data: {'reason': reason},
      );
      if (response.statusCode == 200) {
        await fetchModerationQueue();
        return true;
      }
    } catch (e) {
      state = state.copyWith(actionError: 'Failed to reinstate provider');
    }
    return false;
  }
}

class AdminSafetyState {
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> heatmap;
  final List<Map<String, dynamic>> moderationQueue;
  final int moderationTotal;
  final bool isLoading;
  final String? error;
  final String? actionError;

  AdminSafetyState({
    this.summary,
    this.alerts = const [],
    this.heatmap = const [],
    this.moderationQueue = const [],
    this.moderationTotal = 0,
    this.isLoading = false,
    this.error,
    this.actionError,
  });

  factory AdminSafetyState.initial() => AdminSafetyState();

  AdminSafetyState copyWith({
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? alerts,
    List<Map<String, dynamic>>? heatmap,
    List<Map<String, dynamic>>? moderationQueue,
    int? moderationTotal,
    bool? isLoading,
    String? error,
    String? actionError,
  }) {
    return AdminSafetyState(
      summary: summary ?? this.summary,
      alerts: alerts ?? this.alerts,
      heatmap: heatmap ?? this.heatmap,
      moderationQueue: moderationQueue ?? this.moderationQueue,
      moderationTotal: moderationTotal ?? this.moderationTotal,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      actionError: actionError,
    );
  }
}
