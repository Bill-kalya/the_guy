import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../storage/secure_storage.dart';
import 'endpoints.dart';
import '../../features/jobs/providers/job_provider.dart';
import '../../features/chat/providers/chat_provider.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref);
});

class WebSocketService {
  final Ref _ref;
  StompClient? _client;
  bool _isConnected = false;

  Function(Map<String, dynamic>)? onIncomingJob;
  Function(Map<String, dynamic>)? onJobStatusUpdate;

  WebSocketService(this._ref);

  Future<void> connect() async {
    final token = await _ref.read(secureStorageProvider).getAccessToken();

    _client = StompClient(
      config: StompConfig(
        url: '${Endpoints.wsUrl}/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          _isConnected = true;
          print('WebSocket connected');
          _subscribeToUserQueue();
        },
        onWebSocketError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
      ),
    );

    _client?.activate();
  }

  void _subscribeToUserQueue() {
    final userId = _ref.read(secureStorageProvider).getUserId();
    if (_client != null) {
      _client!.subscribe(
        destination: '/queue/customer/$userId',
        callback: (frame) {
          _handleIncomingMessage(frame);
        },
      );
    }
  }

  void subscribeToProviderJobs() {
    final providerId = _ref.read(secureStorageProvider).getUserId();
    if (_client != null) {
      _client!.subscribe(
        destination: '/queue/provider/$providerId',
        callback: (frame) {
          try {
            final data = jsonDecode(frame.body ?? '{}');
            if (data['type'] == 'NEW_JOB_REQUEST') {
              onIncomingJob?.call(data['job']);
            } else if (data['type'] == 'JOB_UPDATE') {
              onJobStatusUpdate?.call(data['job']);
            }
          } catch (e) {
            print('Error handling provider WebSocket message: $e');
          }
        },
      );
    }
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

  void _handleIncomingMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body ?? '{}');
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
      print('Error handling WebSocket message: $e');
    }
  }

  void subscribeToChat(String jobId) {
    _client?.subscribe(
      destination: '/topic/chat/$jobId',
      callback: (frame) {
        final message = jsonDecode(frame.body ?? '{}');
        _ref.read(chatProvider(jobId).notifier).addMessage(message);
      },
    );
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
    _client?.deactivate();
    _isConnected = false;
  }
}
