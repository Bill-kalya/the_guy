import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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
      final response = await _apiClient.post('/jobs/request', data: jobData);

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

  void providerAccepted(Map<String, dynamic> provider) {
    state = state.copyWith(status: JobStatus.accepted, provider: provider);
  }

  void updateStatus(String newStatus) {
    state = state.copyWith(
      status: JobStatus.values.firstWhere(
        (e) => e.toString() == newStatus,
        orElse: () => JobStatus.matching,
      ),
    );
  }

  Future<void> completeJob() async {
    await _apiClient.patch('/jobs/${state.jobId}/complete');
    state = state.copyWith(status: JobStatus.completed);
  }
}
