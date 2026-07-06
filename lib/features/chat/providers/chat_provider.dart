import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message_model.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, jobId) => ChatNotifier(ref, jobId),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final String jobId;
  final Ref _ref;

  late final ApiClient _apiClient;
  late final WebSocketService _webSocket;

  ChatNotifier(this._ref, this.jobId) : super(ChatState.initial()) {
    _initialize();
  }

  void _initialize() {
    _apiClient = _ref.read(apiClientProvider);
    _webSocket = _ref.read(webSocketServiceProvider);

    _loadMessages();
    _subscribeToChat();
  }

  Future<void> _loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get('${Endpoints.chatHistory}/$jobId');

      if (response.statusCode == 200) {
        final messages = (response.data as List)
            .map((json) => MessageModel.fromJson(json))
            .toList();

        state = state.copyWith(
          messages: messages,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Failed to load messages',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load messages: $e',
        isLoading: false,
      );
    }
  }

  void _subscribeToChat() {
    _webSocket.subscribeToChat(jobId);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final tempMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      jobId: jobId,
      senderId: 'current_user',
      senderName: 'You',
      receiverId: '',
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // optimistic UI update
    state = state.copyWith(
      messages: [...state.messages, tempMessage],
      error: null,
    );

    try {
      _webSocket.sendMessage(jobId, content);
    } catch (e) {
      // rollback if failed
      state = state.copyWith(
        messages: state.messages
            .where((m) => m.id != tempMessage.id)
            .toList(),
        error: 'Failed to send message',
      );
    }
  }

  void markAsRead(String messageId) {
    final updatedMessages = state.messages.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(isRead: true);
      }
      return msg;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  void addMessage(Map<String, dynamic> messageJson) {
    final message = MessageModel.fromJson(messageJson);

    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  @override
  void dispose() {
    _webSocket.unsubscribeFromChat(jobId);
    super.dispose();
  }
}

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  factory ChatState.initial() {
    return const ChatState(messages: []);
  }

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
