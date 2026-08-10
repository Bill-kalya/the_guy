import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../models/job_state.dart';


final jobProvider = NotifierProvider<JobNotifier, JobState>(JobNotifier.new);

class JobNotifier extends Notifier<JobState> {
  late final ApiClient _apiClient;

  @override
  JobState build() {
    _apiClient = ref.watch(apiClientProvider);
    return JobState.initial();
  }

  Future<void> createJob(Map<String, dynamic> jobData) async {
    state = state.copyWith(status: JobStatus.loading);

    try {
      final response = await _apiClient.post(Endpoints.requestJob, data: jobData);

      if (response.statusCode == 201) {
        state = state.copyWith(
          status: JobStatus.matching,
          jobId: response.data['id'],
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: JobStatus.error,
        error: 'Failed to create job request',
      );
    }
  }

  void updateJobStatus(Map<String, dynamic> jobData) {
    state = state.copyWith(
      status: JobStatus.matched,
      provider: jobData['provider'],
      jobDetails: jobData,
    );
  }

  /// Sets the current job into the matching state (called when the request
  /// screen navigates to the matching screen).
  void startMatching(String jobId) {
    state = JobState.matching(jobId);
  }

  void markCancelled() {
    state = state.copyWith(status: JobStatus.cancelled);
  }

  void providerAccepted(Map<String, dynamic> provider) {
    state = state.copyWith(status: JobStatus.accepted, provider: provider);
  }

  void updateStatus(String newStatus) {
    final normalized = newStatus
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    state = state.copyWith(
      status: JobStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == normalized,
        orElse: () => JobStatus.matching,
      ),
    );
  }

  void markInProgress() {
    state = state.copyWith(status: JobStatus.inProgress);
  }

  void markCompleted() {
    state = state.copyWith(status: JobStatus.completed);
  }

  void setAwaitingConfirmation(Map<String, dynamic> jobData) {
    state = state.copyWith(
      status: JobStatus.awaitingConfirmation,
      jobDetails: jobData,
    );
  }

  Future<void> confirmCompletion() async {
    if (state.jobId == null) return;
    try {
      await _apiClient.post(EndpointBuilder.confirmCompletion(state.jobId!));
      state = state.copyWith(status: JobStatus.completed);
    } catch (e) {
      state = state.copyWith(error: 'Failed to confirm completion');
    }
  }

  Future<void> rejectCompletion(String reason) async {
    if (state.jobId == null) return;
    try {
      await _apiClient.post(
        EndpointBuilder.rejectCompletion(state.jobId!),
        data: {'reason': reason},
      );
      state = state.copyWith(status: JobStatus.cancelled);
    } catch (e) {
      state = state.copyWith(error: 'Failed to reject completion');
    }
  }
}
