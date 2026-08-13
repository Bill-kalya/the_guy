import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../shared/providers/auto_refresh_mixin.dart';

final adminVerificationProvider = NotifierProvider<AdminVerificationNotifier, AdminVerificationState>(
  AdminVerificationNotifier.new,
);

class AdminVerificationNotifier extends Notifier<AdminVerificationState> with AutoRefreshMixin<AdminVerificationState> {
  late final ApiClient _apiClient;

  @override
  AdminVerificationState build() {
    _apiClient = ref.watch(apiClientProvider);
    startAutoRefresh();
    return AdminVerificationState.initial();
  }

  @override
  Future<void> autoRefresh() => loadPending();

  Future<void> loadPending({int page = 0, int size = 20}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get(
        '${Endpoints.adminVerificationPending}?page=$page&size=$size',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final body = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        final content = body['content'] as List<dynamic>? ?? [];
        state = state.copyWith(
          documents: content.cast<Map<String, dynamic>>(),
          total: body['totalElements'] as int? ?? 0,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load verification queue');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approve(String documentId) async {
    try {
      final response = await _apiClient.post(
        Endpoints.adminVerificationApprove(documentId),
      );
      if (response.statusCode == 200) {
        await loadPending();
        return true;
      }
      state = state.copyWith(actionError: 'Failed to approve document');
    } catch (e) {
      state = state.copyWith(actionError: 'Failed to approve document');
    }
    return false;
  }

  Future<bool> reject(String documentId, {String reason = 'Rejected by admin'}) async {
    try {
      final response = await _apiClient.post(
        Endpoints.adminVerificationReject(documentId),
        data: {'reason': reason},
      );
      if (response.statusCode == 200) {
        await loadPending();
        return true;
      }
      state = state.copyWith(actionError: 'Failed to reject document');
    } catch (e) {
      state = state.copyWith(actionError: 'Failed to reject document');
    }
    return false;
  }

  void clearActionError() => state = state.copyWith(actionError: null);
}

class AdminVerificationState {
  final List<Map<String, dynamic>> documents;
  final int total;
  final bool isLoading;
  final String? error;
  final String? actionError;

  AdminVerificationState({
    this.documents = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.actionError,
  });

  factory AdminVerificationState.initial() => AdminVerificationState();

  AdminVerificationState copyWith({
    List<Map<String, dynamic>>? documents,
    int? total,
    bool? isLoading,
    String? error,
    String? actionError,
  }) {
    return AdminVerificationState(
      documents: documents ?? this.documents,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      actionError: actionError,
    );
  }
}
