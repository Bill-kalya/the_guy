import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../models/provider_profile_model.dart';

final providerProfileProvider = NotifierProvider<ProviderProfileNotifier, ProviderProfileState>(
  ProviderProfileNotifier.new,
);

class ProviderProfileNotifier extends Notifier<ProviderProfileState> {
  late final ApiClient _apiClient;

  @override
  ProviderProfileState build() {
    _apiClient = ref.watch(apiClientProvider);
    return ProviderProfileState.initial();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.get(Endpoints.providerMe);

      if (response.statusCode == 200) {
        final data = response.data;
        final profileData = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        final profile = ProviderProfileModel.fromJson(profileData);
        state = state.copyWith(profile: profile, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load provider profile',
        isLoading: false,
      );
    }
  }

  Future<void> fetchCompletion() async {
    try {
      final response = await _apiClient.get(Endpoints.providerMeCompletion);

      if (response.statusCode == 200) {
        final data = response.data;
        final completionData = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        state = state.copyWith(completion: completionData);
      }
    } catch (e) {
      // Silent fail — completion is non-critical
    }
  }

  Future<void> refreshProfile() async {
    await fetchProfile();
    await fetchCompletion();
  }
}

class ProviderProfileState {
  final ProviderProfileModel? profile;
  final Map<String, dynamic>? completion;
  final bool isLoading;
  final String? error;

  ProviderProfileState({this.profile, this.completion, this.isLoading = false, this.error});

  factory ProviderProfileState.initial() {
    return ProviderProfileState();
  }

  ProviderProfileState copyWith({
    ProviderProfileModel? profile,
    Map<String, dynamic>? completion,
    bool? isLoading,
    String? error,
  }) {
    return ProviderProfileState(
      profile: profile ?? this.profile,
      completion: completion ?? this.completion,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
