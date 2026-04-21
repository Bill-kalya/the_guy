import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/secure_storage.dart';

final availabilityProvider =
    NotifierProvider<AvailabilityNotifier, AvailabilityState>(
      AvailabilityNotifier.new,
    );

class AvailabilityNotifier extends Notifier<AvailabilityState> {
  late final ApiClient _apiClient;
  late final SecureStorage _secureStorage;

  @override
  AvailabilityState build() {
    _apiClient = ref.watch(apiClientProvider);
    _secureStorage = ref.watch(secureStorageProvider);
    _loadInitialStatus();
    return AvailabilityState.initial();
  }

  void _loadInitialStatus() async {
    // Load saved status or default to online
    final savedStatus = await _secureStorage
        .getUserRole(); // You can store this
    state = state.copyWith(isOnline: true); // Default online
  }

  Future<void> toggleAvailability() async {
    final newStatus = !state.isOnline;
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.patch(
        Endpoints.updateAvailability,
        data: {'isOnline': newStatus},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isOnline: newStatus, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update availability',
        isLoading: false,
      );
    }
  }

  Future<void> setAvailability(bool isOnline) async {
    if (state.isOnline == isOnline) return;
    await toggleAvailability();
  }
}

class AvailabilityState {
  final bool isOnline;
  final bool isLoading;
  final String? error;

  AvailabilityState({this.isOnline = true, this.isLoading = false, this.error});

  factory AvailabilityState.initial() {
    return AvailabilityState();
  }

  AvailabilityState copyWith({bool? isOnline, bool? isLoading, String? error}) {
    return AvailabilityState(
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
