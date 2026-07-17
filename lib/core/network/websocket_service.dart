import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../storage/secure_storage.dart';
import 'endpoints.dart';
import '../../features/jobs/providers/job_provider.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/home/providers/nearby_providers_provider.dart';
import '../../shared/models/nearby_provider_model.dart';
import '../../core/utils/error_handler.dart' as error_handler;

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref);
});

class WebSocketService {
  final Ref _ref;
  StompClient? _client;
  bool _isConnected = false;
  final Set<String> _subscriptions = {};
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  Function(Map<String, dynamic>)? onIncomingJob;
  Function(Map<String, dynamic>)? onJobStatusUpdate;

  WebSocketService(this._ref);

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
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
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
        _handleFrame(destination, frame);
      },
    );
  }

  void _handleFrame(String destination, StompFrame frame) {
    try {
      final data = jsonDecode(frame.body ?? '{}') as Map<String, dynamic>;

      // Handle location updates from providers
      if (data.containsKey('providerId') && data.containsKey('latitude')) {
        final update = ProviderLocationUpdate.fromJson(data);
        _ref.read(providerLocationsProvider.notifier).updateLocation(update);
        return;
      }

      if (destination.startsWith('/queue/customer/')) {
        _handleIncomingMessage(data);
      } else if (destination.startsWith('/queue/provider/')) {
        if (data['type'] == 'NEW_JOB_REQUEST') {
          onIncomingJob?.call(data['job']);
        } else if (data['type'] == 'JOB_UPDATE') {
          onJobStatusUpdate?.call(data['job']);
        }
      } else if (destination.startsWith('/topic/chat/')) {
        final jobId = destination.split('/').last;
        _ref.read(chatProvider(jobId).notifier).addMessage(data);
      } else if (destination.startsWith('/topic/provider/')) {
        // Provider location topic: /topic/provider/{providerId}/location
        if (data.containsKey('latitude')) {
          final update = ProviderLocationUpdate.fromJson(data);
          _ref.read(providerLocationsProvider.notifier).updateLocation(update);
        }
      }
    } catch (e) {
      error_handler.ErrorHandler.logError('WebSocket frame error', e);
    }
  }

  void subscribeToProviderJobs() {
    _ref.read(secureStorageProvider).getUserId().then((providerId) {
      if (providerId == null) return;
      final destination = '/queue/provider/$providerId';
      _subscriptions.add(destination);
      if (_isConnected) {
        _performSubscribe(destination);
      }
    });
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

  void sendProviderStatus(bool isOnline) {
    _client?.send(
      destination: '/app/provider/status',
      body: jsonEncode({
        'isOnline': isOnline,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      switch (type) {
        case 'JOB_MATCHED':
          _ref.read(jobProvider.notifier).updateJobStatus(data['job']);
          break;
        case 'PROVIDER_ACCEPTED':
          _ref.read(jobProvider.notifier).providerAccepted(data['provider']);
          break;
        case 'JOB_STATUS_UPDATE':
          _ref.read(jobProvider.notifier).updateStatus(data['status']);
          break;
      }
    } catch (e) {
      error_handler.ErrorHandler.logError('Message handling error', e);
    }
  }

  void subscribeToChat(String jobId) {
    final destination = '/topic/chat/$jobId';
    _subscriptions.add(destination);
    if (_isConnected) {
      _performSubscribe(destination);
    }
  }

  void unsubscribeFromChat(String jobId) {
    final destination = '/topic/chat/$jobId';
    _subscriptions.remove(destination);
  }

  void sendMessage(String jobId, String message) {
    _client?.send(
      destination: '/app/chat/$jobId',
      body: jsonEncode({
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
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
