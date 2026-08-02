import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/services/location_api_service.dart';
import '../../../core/utils/location_utils.dart';

final availabilityProvider =
    NotifierProvider<AvailabilityNotifier, AvailabilityState>(
      AvailabilityNotifier.new,
    );

class AvailabilityNotifier extends Notifier<AvailabilityState> {
  late final ApiClient _apiClient;
  late final LocationApiService _locationService;
  Timer? _heartbeatTimer;
  bool _heartbeatSending = false;

  @override
  AvailabilityState build() {
    _apiClient = ref.watch(apiClientProvider);
    _locationService = ref.watch(locationApiServiceProvider);
    ref.onDispose(() => _heartbeatTimer?.cancel());
    _loadInitialStatus();
    return AvailabilityState.initial();
  }

  void _loadInitialStatus() async {
    try {
      final response = await _apiClient.get(Endpoints.providerMe);
      if (response.statusCode == 200) {
        final data = response.data;
        final profileData = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        final isOnline = profileData['isOnline'] ?? false;
        state = state.copyWith(isOnline: isOnline);
        if (isOnline) _startHeartbeat();
      }
    } catch (e) {
      // Keep default online if profile can't be fetched
    }
  }

  Future<void> toggleAvailability() async {
    final newStatus = !state.isOnline;
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.patch(
        EndpointBuilder.providerAvailability(newStatus),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isOnline: newStatus, isLoading: false);
        if (newStatus) {
          _startHeartbeat();
        } else {
          _stopHeartbeat();
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update availability',
        isLoading: false,
      );
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
    _sendHeartbeat();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    if (_heartbeatSending) return;
    _heartbeatSending = true;
    try {
      final position = await LocationUtils.getCurrentLocation();
      if (position != null) {
        await _locationService.updateLocation(
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (_) {
      // Ignore heartbeat failures; next tick will retry
    } finally {
      _heartbeatSending = false;
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
