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
  Timer? _syncTimer;
  bool _heartbeatSending = false;
  int _heartbeatFailures = 0;

  @override
  AvailabilityState build() {
    _apiClient = ref.watch(apiClientProvider);
    _locationService = ref.watch(locationApiServiceProvider);
    ref.onDispose(() {
      _heartbeatTimer?.cancel();
      _syncTimer?.cancel();
    });

    _loadInitialStatus();
    // Reconcile with the backend so "Online" always reflects reality: the
    // server silently flips idle providers offline (stale-location sweep), so
    // without this the toggle would keep lying after the app is backgrounded.
    _syncTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadInitialStatus(),
    );
    return AvailabilityState.initial();
  }

  Future<void> _loadInitialStatus() async {
    try {
      final response = await _apiClient.get(Endpoints.providerMe);
      if (response.statusCode != 200) {
        _markUnverified();
        return;
      }
      final data = response.data;
      final profileData = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      final isOnline = profileData['isOnline'] ?? false;
      final wasOnline = state.isOnline;

      state = state.copyWith(
        isOnline: isOnline,
        isVerified: true,
        error: null,
        notice: _heartbeatFailures >= 2 && isOnline
            ? _locationLostNotice
            : null,
      );

      if (isOnline && _heartbeatTimer == null) {
        _startHeartbeat();
      } else if (!isOnline && wasOnline) {
        // The backend flipped us offline (e.g., stale-location sweep) while we
        // still thought we were online.
        _stopHeartbeat();
        state = state.copyWith(
          notice: _heartbeatFailures >= 2 ? _locationLostNotice : null,
        );
      }
    } catch (_) {
      _markUnverified();
    }
  }

  void _markUnverified() {
    if (!state.isVerified) return;
    state = state.copyWith(
      isVerified: false,
      notice: 'Could not verify your online status. Check your connection.',
    );
  }

  Future<void> toggleAvailability() async {
    final newStatus = !state.isOnline;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.patch(
        EndpointBuilder.providerAvailability(newStatus),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isOnline: newStatus,
          isLoading: false,
          isVerified: true,
          error: null,
          notice: null,
        );
        if (newStatus) {
          _startHeartbeat();
        } else {
          _stopHeartbeat();
        }
      } else {
        state = state.copyWith(
          error: 'Failed to update availability',
          isLoading: false,
        );
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
    _heartbeatFailures = 0;
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
    _sendHeartbeat();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _heartbeatFailures = 0;
  }

  Future<void> _sendHeartbeat() async {
    if (_heartbeatSending) return;
    _heartbeatSending = true;
    var succeeded = false;
    try {
      final position = await LocationUtils.getCurrentLocation();
      if (position != null) {
        await _locationService.updateLocation(
          lat: position.latitude,
          lng: position.longitude,
        );
        succeeded = true;
      }
    } catch (_) {
      // fall through to failure handling below
    } finally {
      _heartbeatSending = false;
    }

    if (succeeded) {
      _heartbeatFailures = 0;
      if (state.notice != null && state.isOnline) {
        state = state.copyWith(notice: null);
      }
      return;
    }

    _heartbeatFailures++;
    if (_heartbeatFailures >= 2 && state.isOnline) {
      state = state.copyWith(notice: _locationLostNotice);
    }
  }

  static const String _locationLostNotice =
      'Location signal lost — customers may not see you. '
      'Keep this tab open and allow location access.';

  Future<void> setAvailability(bool isOnline) async {
    if (state.isOnline == isOnline) return;
    await toggleAvailability();
  }
}

class AvailabilityState {
  final bool isOnline;
  final bool isLoading;
  /// Whether the online flag was confirmed with the backend. False while the
  /// initial status fetch is in flight or has failed.
  final bool isVerified;
  final String? error;
  final String? notice;

  AvailabilityState({
    this.isOnline = false,
    this.isLoading = false,
    this.isVerified = false,
    this.error,
    this.notice,
  });

  factory AvailabilityState.initial() {
    return AvailabilityState();
  }

  AvailabilityState copyWith({
    bool? isOnline,
    bool? isLoading,
    bool? isVerified,
    Object? error = _unset,
    Object? notice = _unset,
  }) {
    return AvailabilityState(
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      isVerified: isVerified ?? this.isVerified,
      error: identical(error, _unset) ? this.error : error as String?,
      notice: identical(notice, _unset) ? this.notice : notice as String?,
    );
  }

  static const Object _unset = Object();
}
