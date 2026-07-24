import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final performanceProvider =
    NotifierProvider<PerformanceNotifier, PerformanceState>(
  PerformanceNotifier.new,
);

class PerformanceNotifier extends Notifier<PerformanceState> {
  late final ApiClient _apiClient;

  @override
  PerformanceState build() {
    _apiClient = ref.watch(apiClientProvider);
    return PerformanceState.initial();
  }

  Future<void> fetchPerformance() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.get(Endpoints.providerMePerformance);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final performance = PerformanceData.fromJson(data);
        state = state.copyWith(performance: performance, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load performance',
        isLoading: false,
      );
    }
  }
}

class PerformanceData {
  final double acceptanceRate;
  final double completionRate;
  final double avgResponseTime;
  final int repeatCustomerCount;
  final double cancellationRate;
  final String ranking;
  final Map<String, String> trend;

  PerformanceData({
    required this.acceptanceRate,
    required this.completionRate,
    required this.avgResponseTime,
    required this.repeatCustomerCount,
    required this.cancellationRate,
    required this.ranking,
    required this.trend,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      acceptanceRate: (json['acceptanceRate'] ?? 0).toDouble(),
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      avgResponseTime: (json['avgResponseTime'] ?? 0).toDouble(),
      repeatCustomerCount: json['repeatCustomerCount'] ?? 0,
      cancellationRate: (json['cancellationRate'] ?? 0).toDouble(),
      ranking: json['ranking'] ?? 'Building reputation',
      trend: Map<String, String>.from(json['trend'] ?? {}),
    );
  }
}

class PerformanceState {
  final PerformanceData? performance;
  final bool isLoading;
  final String? error;

  PerformanceState({this.performance, this.isLoading = false, this.error});

  factory PerformanceState.initial() {
    return PerformanceState();
  }

  PerformanceState copyWith({
    PerformanceData? performance,
    bool? isLoading,
    String? error,
  }) {
    return PerformanceState(
      performance: performance ?? this.performance,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
