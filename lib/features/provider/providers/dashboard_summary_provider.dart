import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final dashboardSummaryProvider =
    NotifierProvider<DashboardSummaryNotifier, DashboardSummaryState>(
  DashboardSummaryNotifier.new,
);

class DashboardSummaryNotifier extends Notifier<DashboardSummaryState> {
  late final ApiClient _apiClient;

  @override
  DashboardSummaryState build() {
    _apiClient = ref.watch(apiClientProvider);
    return DashboardSummaryState.initial();
  }

  Future<void> fetchDashboard() async {
    if (state.summary == null) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isRefreshing: true);
    }

    try {
      final response = await _apiClient.get(Endpoints.providerMeDashboard);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final summary = DashboardSummaryData.fromJson(data);
        state = state.copyWith(
          summary: summary,
          isLoading: false,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      if (state.summary == null) {
        state = state.copyWith(
          error: 'Failed to load dashboard',
          isLoading: false,
        );
      } else {
        state = state.copyWith(isRefreshing: false);
      }
    }
  }

  Future<void> refreshDashboard() async {
    await fetchDashboard();
  }
}

class DashboardSummaryData {
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double totalEarnings;
  final String currency;
  final int todayJobs;
  final int weekJobs;
  final int totalJobsCompleted;
  final int activeJobs;
  final double averageRating;
  final int totalReviews;
  final double responseRate;
  final double completionRate;
  final double cancellationRate;
  final String ranking;
  final double availableBalance;
  final double pendingBalance;
  final List<WeeklyChartPoint> weeklyChart;

  DashboardSummaryData({
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.totalEarnings,
    required this.currency,
    required this.todayJobs,
    required this.weekJobs,
    required this.totalJobsCompleted,
    required this.activeJobs,
    required this.averageRating,
    required this.totalReviews,
    required this.responseRate,
    required this.completionRate,
    required this.cancellationRate,
    required this.ranking,
    required this.availableBalance,
    required this.pendingBalance,
    required this.weeklyChart,
  });

  factory DashboardSummaryData.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryData(
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      weekEarnings: (json['weekEarnings'] ?? 0).toDouble(),
      monthEarnings: (json['monthEarnings'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'KES',
      todayJobs: json['todayJobs'] ?? 0,
      weekJobs: json['weekJobs'] ?? 0,
      totalJobsCompleted: json['totalJobsCompleted'] ?? 0,
      activeJobs: json['activeJobs'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      responseRate: (json['responseRate'] ?? 0).toDouble(),
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      cancellationRate: (json['cancellationRate'] ?? 0).toDouble(),
      ranking: json['ranking'] ?? 'Building reputation',
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? 0).toDouble(),
      weeklyChart: (json['weeklyChart'] as List? ?? [])
          .map((e) => WeeklyChartPoint.fromJson(e))
          .toList(),
    );
  }
}

class WeeklyChartPoint {
  final String day;
  final double amount;

  WeeklyChartPoint({required this.day, required this.amount});

  factory WeeklyChartPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyChartPoint(
      day: json['day'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class DashboardSummaryState {
  final DashboardSummaryData? summary;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;

  DashboardSummaryState({
    this.summary,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
  });

  factory DashboardSummaryState.initial() {
    return DashboardSummaryState();
  }

  DashboardSummaryState copyWith({
    DashboardSummaryData? summary,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DashboardSummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get lastUpdatedText {
    if (lastUpdated == null) return 'Never';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inSeconds < 30) return 'Just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
