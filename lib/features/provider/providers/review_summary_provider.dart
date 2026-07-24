import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final reviewSummaryProvider =
    NotifierProvider<ReviewSummaryNotifier, ReviewSummaryState>(
  ReviewSummaryNotifier.new,
);

class ReviewSummaryNotifier extends Notifier<ReviewSummaryState> {
  late final ApiClient _apiClient;

  @override
  ReviewSummaryState build() {
    _apiClient = ref.watch(apiClientProvider);
    return ReviewSummaryState.initial();
  }

  Future<void> fetchReviewSummary(String providerId) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.get(
        Endpoints.reviewSummary(providerId),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final summary = ReviewSummaryData.fromJson(data);
        state = state.copyWith(summary: summary, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load review summary',
        isLoading: false,
      );
    }
  }
}

class ReviewSummaryData {
  final double overallSqs;
  final int totalReviews;
  final Map<String, double> categories;
  final String recentTrend;

  ReviewSummaryData({
    required this.overallSqs,
    required this.totalReviews,
    required this.categories,
    required this.recentTrend,
  });

  factory ReviewSummaryData.fromJson(Map<String, dynamic> json) {
    return ReviewSummaryData(
      overallSqs: (json['overallSqs'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      categories: Map<String, double>.from(
        (json['categories'] ?? {}).map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      recentTrend: json['recentTrend'] ?? 'stable',
    );
  }
}

class ReviewSummaryState {
  final ReviewSummaryData? summary;
  final bool isLoading;
  final String? error;

  ReviewSummaryState({this.summary, this.isLoading = false, this.error});

  factory ReviewSummaryState.initial() {
    return ReviewSummaryState();
  }

  ReviewSummaryState copyWith({
    ReviewSummaryData? summary,
    bool? isLoading,
    String? error,
  }) {
    return ReviewSummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
