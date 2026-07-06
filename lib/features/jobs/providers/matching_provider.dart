import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchingProvider = NotifierProvider<MatchingNotifier, MatchingState>(
  MatchingNotifier.new,
);

class MatchingNotifier extends Notifier<MatchingState> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  MatchingState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return MatchingState.initial();
  }

  void startMatching(String jobId) {
    state = state.copyWith(jobId: jobId, isMatching: true, elapsedSeconds: 0);

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      state = state.copyWith(elapsedSeconds: _elapsedSeconds);

      // Auto-cancel after 60 seconds
      if (_elapsedSeconds >= 60) {
        stopMatching('No providers found in your area');
      }
    });
  }

  void stopMatching([String? reason]) {
    _timer?.cancel();
    state = state.copyWith(isMatching: false, error: reason);
  }

  void providerFound(Map<String, dynamic> provider) {
    _timer?.cancel();
    state = state.copyWith(
      isMatching: false,
      providerFound: true,
      provider: provider,
    );
  }

  void reset() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    state = MatchingState.initial();
  }
}

class MatchingState {
  final String? jobId;
  final bool isMatching;
  final int elapsedSeconds;
  final bool providerFound;
  final Map<String, dynamic>? provider;
  final String? error;

  MatchingState({
    this.jobId,
    this.isMatching = false,
    this.elapsedSeconds = 0,
    this.providerFound = false,
    this.provider,
    this.error,
  });

  factory MatchingState.initial() {
    return MatchingState();
  }

  MatchingState copyWith({
    String? jobId,
    bool? isMatching,
    int? elapsedSeconds,
    bool? providerFound,
    Map<String, dynamic>? provider,
    String? error,
  }) {
    return MatchingState(
      jobId: jobId ?? this.jobId,
      isMatching: isMatching ?? this.isMatching,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      providerFound: providerFound ?? this.providerFound,
      provider: provider ?? this.provider,
      error: error ?? this.error,
    );
  }

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
