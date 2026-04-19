enum JobStatus {
  idle,
  loading,
  matching,
  matched,
  accepted,
  enRoute,
  arrived,
  inProgress,
  completed,
  cancelled,
  error,
}

class JobState {
  final JobStatus status;
  final String? jobId;
  final Map<String, dynamic>? jobDetails;
  final Map<String, dynamic>? provider;
  final String? error;

  const JobState({
    this.status = JobStatus.idle,
    this.jobId,
    this.jobDetails,
    this.provider,
    this.error,
  });

  factory JobState.initial() => const JobState();

  factory JobState.loading() => const JobState(status: JobStatus.loading);

  factory JobState.matching(String jobId) => JobState(
        status: JobStatus.matching,
        jobId: jobId,
      );

  factory JobState.matched(String jobId, Map<String, dynamic> provider) => JobState(
        status: JobStatus.matched,
        jobId: jobId,
        provider: provider,
      );

  factory JobState.error(String message) => JobState(
        status: JobStatus.error,
        error: message,
      );

  JobState copyWith({
    JobStatus? status,
    String? jobId,
    Map<String, dynamic>? jobDetails,
    Map<String, dynamic>? provider,
    String? error,
  }) {
    return JobState(
      status: status ?? this.status,
      jobId: jobId ?? this.jobId,
      jobDetails: jobDetails ?? this.jobDetails,
      provider: provider ?? this.provider,
      error: error ?? this.error,
    );
  }

  bool get isMatching => status == JobStatus.matching;
  bool get isMatched => status == JobStatus.matched;
  bool get isActive => [
    JobStatus.accepted,
    JobStatus.enRoute,
    JobStatus.arrived,
    JobStatus.inProgress,
  ].contains(status);
  bool get isCompleted => status == JobStatus.completed;
  bool get hasError => status == JobStatus.error;
}