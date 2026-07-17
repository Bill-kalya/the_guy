import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../storage/secure_storage.dart';
import '../network/endpoints.dart';
import '../../shared/models/nearby_provider_model.dart';
import '../../features/home/providers/nearby_providers_provider.dart';

final locationSocketServiceProvider = Provider<LocationSocketService>((ref) {
  return LocationSocketService(ref);
});

/// WebSocket service specifically for real-time provider location tracking
/// Uses the existing STOMP connection from WebSocketService
class LocationSocketService {
  final Ref _ref;
  StompClient? _client;
  bool _isConnected = false;
  final Set<String> _subscriptions = {};
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  LocationSocketService(this._ref);

  Future<void> connect() async {
    final token = await _ref.read(secureStorageProvider).getAccessToken();
    if (token == null) return;

    _client = StompClient(
      config: StompConfig.sockJS(
        url: '${Endpoints.wsUrl}/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          _isConnected = true;
          _reconnectAttempts = 0;
          _resubscribeAll();
        },
        onWebSocketError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onStompError: (frame) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDisconnect: (frame) {
          _isConnected = false;
        },
      ),
    );

    _client?.activate();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: _getBackoffDelay());
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  int _getBackoffDelay() {
    return (1 << _reconnectAttempts).clamp(1, 16);
  }

  void _resubscribeAll() {
    for (final destination in _subscriptions) {
      _performSubscribe(destination);
    }
  }

  void _performSubscribe(String destination) {
    _client?.subscribe(
      destination: destination,
      callback: (frame) {
        _handleLocationFrame(destination, frame);
      },
    );
  }

  void _handleLocationFrame(String destination, StompFrame frame) {
    try {
      final data = jsonDecode(frame.body ?? '{}') as Map<String, dynamic>;

      // Parse location update
      if (data.containsKey('providerId') && data.containsKey('latitude')) {
        final update = ProviderLocationUpdate.fromJson(data);
        _ref.read(providerLocationsProvider.notifier).updateLocation(update);
      }
    } catch (e) {
      // Silently handle parse errors
    }
  }

  /// Subscribe to live location updates for a specific provider
  void subscribeToProviderLocation(String providerId) {
    final destination = '/topic/provider/$providerId/location';
    _subscriptions.add(destination);
    if (_isConnected) {
      _performSubscribe(destination);
    }
  }

  /// Unsubscribe from a provider's location updates
  void unsubscribeFromProviderLocation(String providerId) {
    final destination = '/topic/provider/$providerId/location';
    _subscriptions.remove(destination);
  }

  /// Subscribe to all nearby provider location updates
  void subscribeToNearbyProviders(List<String> providerIds) {
    for (final id in providerIds) {
      subscribeToProviderLocation(id);
    }
  }

  /// Send location update from provider app
  void sendLocationUpdate(ProviderLocationUpdate update) {
    _client?.send(
      destination: '/app/location/update',
      body: jsonEncode(update.toJson()),
    );
  }

  /// Request to track a specific provider (customer side)
  void requestTrackProvider(String providerId) {
    _client?.send(
      destination: '/app/location/track/$providerId',
      body: jsonEncode({'action': 'track'}),
    );
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _subscriptions.clear();
    _reconnectAttempts = 0;
    _client?.deactivate();
    _isConnected = false;
  }
}