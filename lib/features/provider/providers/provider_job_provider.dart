import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/error_handler.dart';
import '../models/provider_job_model.dart';
import '../../../core/network/endpoints.dart';

final providerJobProvider =
    NotifierProvider<ProviderJobNotifier, ProviderJobState>(
      ProviderJobNotifier.new,
    );

class ProviderJobNotifier extends Notifier<ProviderJobState> {
  late final ApiClient _apiClient;
  late final WebSocketService _webSocket;

  @override
  ProviderJobState build() {
    _apiClient = ref.watch(apiClientProvider);
    _webSocket = ref.watch(webSocketServiceProvider);
    _listenForIncomingJobs();
    _webSocket.subscribeToProviderJobs();
    return ProviderJobState.initial();
  }

  void _listenForIncomingJobs() {
    _webSocket.onIncomingJob = (jobData) {
      final job = ProviderJob.fromJson(jobData);
      state = state.copyWith(incomingJob: job, hasIncomingJob: true);
    };

    _webSocket.onJobStatusUpdate = (jobData) {
      final updatedJob = ProviderJob.fromJson(jobData);
      if (state.activeJob?.id == updatedJob.id) {
        state = state.copyWith(activeJob: updatedJob);
      }
      if (state.incomingJob?.id == updatedJob.id && updatedJob.hasResponded) {
        state = state.copyWith(incomingJob: null, hasIncomingJob: false);
      }
    };
  }

  Future<bool> acceptJob(String jobId, {ProviderJob? job}) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.post(EndpointBuilder.acceptJob(jobId));

      if (response.statusCode == 200) {
        // The backend confirms with a generic success envelope; build the
        // active job from the passed-in (map) job or the incoming broadcast.
        final source = job ?? state.incomingJob;
        final acceptedJob = source?.copyWith(
          status: 'accepted',
          hasResponded: true,
        );
        state = state.copyWith(
          activeJob: acceptedJob,
          incomingJob: null,
          hasIncomingJob: false,
          isLoading: false,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept job', isLoading: false);
    }

    return false;
  }

  Future<bool> declineJob(String jobId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _apiClient.post(EndpointBuilder.declineJob(jobId));
      state = state.copyWith(
        incomingJob: null,
        hasIncomingJob: false,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to decline job', isLoading: false);
      return false;
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      final response = await _apiClient.patch(
        EndpointBuilder.updateJobStatus(jobId),
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final current = state.activeJob;
        if (current != null && current.id == jobId) {
          state = state.copyWith(activeJob: current.copyWith(status: status));
        }
      }
    } catch (e) {
      ErrorHandler.logError('Error updating job status', e);
    }
  }

  Future<void> completeJob(String jobId, {
    String? completionNotes,
    List<String>? completionPhotos,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (completionNotes != null) data['completionNotes'] = completionNotes;
      if (completionPhotos != null) data['completionPhotos'] = completionPhotos;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;

      final response = await _apiClient.post(
        EndpointBuilder.completeJob(jobId),
        data: data,
      );

      if (response.statusCode == 200) {
        // The backend returns {success, message, data: JobResponseDTO}.
        // Keep the local job model and just surface the new lifecycle state.
        Map<String, dynamic>? payload;
        final result = response.data;
        if (result is Map<String, dynamic> &&
            result['data'] is Map<String, dynamic>) {
          payload = result['data'] as Map<String, dynamic>;
        }

        final current = state.activeJob;
        if (current != null && current.id == jobId) {
          state = state.copyWith(
            activeJob: current.copyWith(
              status: 'awaiting_confirmation',
              completionNotes:
                  payload?['completionNotes'] as String? ?? current.completionNotes,
              completionPhotos: payload?['completionPhotos'] is List
                  ? List<String>.from(payload!['completionPhotos'] as List)
                  : current.completionPhotos,
              completionLatitude:
                  (payload?['completionLatitude'] as num?)?.toDouble() ??
                      current.completionLatitude,
              completionLongitude:
                  (payload?['completionLongitude'] as num?)?.toDouble() ??
                      current.completionLongitude,
              confirmationDeadline:
                  payload?['confirmationDeadline'] as String? ??
                      current.confirmationDeadline,
            ),
          );
        }
      }
    } catch (e) {
      ErrorHandler.logError('Error completing job', e);
    }
  }

  /// Marks the active job completed when the customer confirms (or the backend
  /// auto-confirms) and escrow is released.
  void markActiveJobCompleted(Object? jobId) {
    final current = state.activeJob;
    if (current == null) return;
    if (jobId != null && current.id != jobId.toString()) return;
    state = state.copyWith(activeJob: current.copyWith(status: 'completed'));
  }

  /// Marks the active job cancelled/disputed so it drops out of the active list.
  void markActiveJobCancelled(Object? jobId) {
    final current = state.activeJob;
    if (current == null) return;
    if (jobId != null && current.id != jobId.toString()) return;
    state = state.copyWith(activeJob: current.copyWith(status: 'cancelled'));
  }

  Future<void> startJob(String jobId) async {
    await updateJobStatus(jobId, 'in_progress');
  }

  Future<void> arriveAtLocation(String jobId) async {
    await updateJobStatus(jobId, 'arrived');
  }

  void clearIncomingJob() {
    state = state.copyWith(incomingJob: null, hasIncomingJob: false);
  }

  void clearActiveJob() {
    state = state.copyWith(activeJob: null);
  }
}

class ProviderJobState {
  final ProviderJob? incomingJob;
  final ProviderJob? activeJob;
  final bool hasIncomingJob;
  final bool isLoading;
  final String? error;

  ProviderJobState({
    this.incomingJob,
    this.activeJob,
    this.hasIncomingJob = false,
    this.isLoading = false,
    this.error,
  });

  factory ProviderJobState.initial() {
    return ProviderJobState();
  }

  ProviderJobState copyWith({
    ProviderJob? incomingJob,
    ProviderJob? activeJob,
    bool? hasIncomingJob,
    bool? isLoading,
    String? error,
  }) {
    return ProviderJobState(
      incomingJob: incomingJob ?? this.incomingJob,
      activeJob: activeJob ?? this.activeJob,
      hasIncomingJob: hasIncomingJob ?? this.hasIncomingJob,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
