import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../models/earnings_model.dart';

final earningsProvider = NotifierProvider<EarningsNotifier, EarningsState>(
  EarningsNotifier.new,
);

class EarningsNotifier extends Notifier<EarningsState> {
  late final ApiClient _apiClient;

  @override
  EarningsState build() {
    _apiClient = ref.watch(apiClientProvider);
    return EarningsState.initial();
  }

  Future<void> fetchEarnings() async {
    if (state.earnings == null) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isRefreshing: true);
    }

    try {
      final response = await _apiClient.get(Endpoints.providerEarnings);

      if (response.statusCode == 200) {
        final earnings = EarningsModel.fromJson(response.data);
        state = state.copyWith(
          earnings: earnings,
          isLoading: false,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      if (state.earnings == null) {
        state = state.copyWith(
          error: 'Failed to load earnings',
          isLoading: false,
        );
      } else {
        state = state.copyWith(isRefreshing: false);
      }
    }
  }

  Future<void> refreshEarnings() async {
    await fetchEarnings();
  }
}

class EarningsState {
  final EarningsModel? earnings;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;

  EarningsState({
    this.earnings,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
  });

  factory EarningsState.initial() {
    return EarningsState();
  }

  EarningsState copyWith({
    EarningsModel? earnings,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
  }) {
    return EarningsState(
      earnings: earnings ?? this.earnings,
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
