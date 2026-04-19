import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, jobId) {
  final apiClient = ref.watch(apiClientProvider);
  final webSocket = ref.watch(webSocketServiceProvider);
  return ChatNotifier(jobId, apiClient, webSocket, ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final String jobId;
  final ApiClient _apiClient;
  final WebSocketService _webSocket;
  final Ref _ref;

  ChatNotifier(
    this.jobId,
    this._apiClient,
    this._webSocket,
    this._ref,
  ) : super(ChatState.initial()) {
    _loadMessages();
    _subscribeToChat();
  }

  Future<void> _loadMessages() async {
    state = state.copyWith(isLoading: true);
    
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
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load messages',
        isLoading: false,
      );
    }
  }

  void _subscribeToChat() {
    _webSocket.subscribeToChat(jobId, (message) {
      final newMessage = MessageModel.fromJson(message);
      state = state.copyWith(
        messages: [...state.messages, newMessage],
      );
    });
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
    
    // Optimistically add message
    state = state.copyWith(
      messages: [...state.messages, tempMessage],
    );
    
    try {
      await _webSocket.sendMessage(jobId, content);
    } catch (e) {
      // Remove failed message
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != tempMessage.id).toList(),
        error: 'Failed to send message',
      );
    }
  }

  void markAsRead(String messageId) {
    // Implement mark as read
  }
}

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  factory ChatState.initial() {
    return ChatState(messages: []);
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