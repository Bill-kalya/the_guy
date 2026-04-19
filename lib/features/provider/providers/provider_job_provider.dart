import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../models/provider_job_model.dart';
import '../../../core/network/endpoints.dart';

final providerJobProvider = StateNotifierProvider<ProviderJobNotifier, ProviderJobState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final webSocket = ref.watch(webSocketServiceProvider);
  return ProviderJobNotifier(apiClient, webSocket, ref);
});

class ProviderJobNotifier extends StateNotifier<ProviderJobState> {
  final ApiClient _apiClient;
  final WebSocketService _webSocket;
  final Ref _ref;

  ProviderJobNotifier(this._apiClient, this._webSocket, this._ref) 
      : super(ProviderJobState.initial()) {
    _listenForIncomingJobs();
  }

  void _listenForIncomingJobs() {
    _webSocket.onIncomingJob = (jobData) {
      final job = ProviderJob.fromJson(jobData);
      state = state.copyWith(
        incomingJob: job,
        hasIncomingJob: true,
      );
    };

    _webSocket.onJobUpdate = (jobData) {
      final updatedJob = ProviderJob.fromJson(jobData);
      if (state.activeJob?.id == updatedJob.id) {
        state = state.copyWith(activeJob: updatedJob);
      }
      if (state.incomingJob?.id == updatedJob.id && updatedJob.hasResponded) {
        state = state.copyWith(incomingJob: null, hasIncomingJob: false);
      }
    };
  }

  Future<bool> acceptJob(String jobId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final response = await _apiClient.patch('${Endpoints.acceptJob}/$jobId');
      
      if (response.statusCode == 200) {
        final acceptedJob = ProviderJob.fromJson(response.data);
        state = state.copyWith(
          activeJob: acceptedJob,
          incomingJob: null,
          hasIncomingJob: false,
          isLoading: false,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to accept job',
        isLoading: false,
      );
    }
    
    return false;
  }

  Future<void> declineJob(String jobId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _apiClient.patch('${Endpoints.declineJob}/$jobId');
      state = state.copyWith(
        incomingJob: null,
        hasIncomingJob: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to decline job',
        isLoading: false,
      );
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      final response = await _apiClient.patch(
        '${Endpoints.updateJobStatus}/$jobId',
        data: {'status': status},
      );
      
      if (response.statusCode == 200) {
        final updatedJob = ProviderJob.fromJson(response.data);
        state = state.copyWith(activeJob: updatedJob);
      }
    } catch (e) {
      print('Error updating job status: $e');
    }
  }

  Future<void> completeJob(String jobId) async {
    await updateJobStatus(jobId, 'completed');
  }

  Future<void> startJob(String jobId) async {
    await updateJobStatus(jobId, 'in_progress');
  }

  Future<void> arriveAtLocation(String jobId) async {
    await updateJobStatus(jobId, 'arrived');
  }

  void clearIncomingJob() {
    state = state.copyWith(
      incomingJob: null,
      hasIncomingJob: false,
    );
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