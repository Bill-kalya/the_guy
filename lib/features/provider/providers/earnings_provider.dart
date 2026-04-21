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
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.get(Endpoints.providerEarnings);

      if (response.statusCode == 200) {
        final earnings = EarningsModel.fromJson(response.data);
        state = state.copyWith(earnings: earnings, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load earnings',
        isLoading: false,
      );
    }
  }

  Future<void> refreshEarnings() async {
    await fetchEarnings();
  }
}

class EarningsState {
  final EarningsModel? earnings;
  final bool isLoading;
  final String? error;

  EarningsState({this.earnings, this.isLoading = false, this.error});

  factory EarningsState.initial() {
    return EarningsState();
  }

  EarningsState copyWith({
    EarningsModel? earnings,
    bool? isLoading,
    String? error,
  }) {
    return EarningsState(
      earnings: earnings ?? this.earnings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
