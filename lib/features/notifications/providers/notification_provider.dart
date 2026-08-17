import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

class NotificationNotifier extends Notifier<NotificationState> {
  late final ApiClient _apiClient;

  @override
  NotificationState build() {
    _apiClient = ref.watch(apiClientProvider);
    return NotificationState.initial();
  }

  Future<void> loadNotifications({int page = 0}) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.get(
        Endpoints.notifications,
        queryParameters: {'page': page, 'size': 20},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List items = data['notifications'] ?? [];
        final notifications = items
            .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          isLoading: false,
          notifications: page == 0
              ? notifications
              : [...state.notifications, ...notifications],
          totalPages: data['totalPages'] ?? 0,
          currentPage: page,
          unreadCount: (data['unreadCount'] ?? 0) as int,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final response = await _apiClient.get(Endpoints.notificationsUnreadCount);
      if (response.statusCode == 200) {
        state = state.copyWith(
            unreadCount: (response.data['unreadCount'] ?? 0) as int);
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.post(Endpoints.notificationsMarkRead);
      state = state.copyWith(
        unreadCount: 0,
        notifications: state.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (state.currentPage < state.totalPages - 1 && !state.isLoadingMore) {
      state = state.copyWith(isLoadingMore: true);
      await loadNotifications(page: state.currentPage + 1);
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

class NotificationState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<AppNotification> notifications;
  final int totalPages;
  final int currentPage;
  final int unreadCount;
  final String? error;

  NotificationState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.notifications = const [],
    this.totalPages = 0,
    this.currentPage = 0,
    this.unreadCount = 0,
    this.error,
  });

  factory NotificationState.initial() => NotificationState();

  NotificationState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<AppNotification>? notifications,
    int? totalPages,
    int? currentPage,
    int? unreadCount,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      notifications: notifications ?? this.notifications,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
    );
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? 'UNKNOWN',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      isRead: json['read'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  IconData get icon {
    return switch (type) {
      'JOB_CREATED' => Icons.add_circle_outline,
      'JOB_ACCEPTED' || 'PROVIDER_ACCEPTED' => Icons.check_circle_outline,
      'JOB_ACCEPTED_SUCCESS' => Icons.verified_outlined,
      'JOB_STARTED' => Icons.play_circle_outline,
      'JOB_AWAITING_CONFIRMATION' => Icons.pending_outlined,
      'JOB_COMPLETED' || 'JOB_AUTO_CONFIRMED' => Icons.task_alt,
      'JOB_PAYMENT_RELEASED' => Icons.account_balance_wallet_outlined,
      'JOB_CANCELLED' => Icons.cancel_outlined,
      'JOB_DISPUTED' => Icons.gavel_outlined,
      _ => Icons.notifications_outlined,
    };
  }
}
