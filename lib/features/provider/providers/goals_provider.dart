import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final goalsProvider = NotifierProvider<GoalsNotifier, GoalsState>(
  GoalsNotifier.new,
);

class GoalsNotifier extends Notifier<GoalsState> {
  late final ApiClient _apiClient;

  @override
  GoalsState build() {
    _apiClient = ref.watch(apiClientProvider);
    return GoalsState.initial();
  }

  Future<void> fetchGoals() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.get(Endpoints.providerMeGoals);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final goals = GoalsData.fromJson(data);
        state = state.copyWith(goals: goals, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load goals',
        isLoading: false,
      );
    }
  }
}

class GoalAchievement {
  final String id;
  final String title;
  final String icon;
  final bool unlocked;
  final String? date;
  final int? progress;
  final int? target;

  GoalAchievement({
    required this.id,
    required this.title,
    required this.icon,
    required this.unlocked,
    this.date,
    this.progress,
    this.target,
  });

  factory GoalAchievement.fromJson(Map<String, dynamic> json) {
    return GoalAchievement(
      id: json['id'],
      title: json['title'],
      icon: json['icon'],
      unlocked: json['unlocked'] ?? false,
      date: json['date'],
      progress: json['progress'],
      target: json['target'],
    );
  }
}

class GoalsData {
  final double weeklyTarget;
  final double weeklyProgress;
  final int weeklyPercentage;
  final List<GoalAchievement> achievements;

  GoalsData({
    required this.weeklyTarget,
    required this.weeklyProgress,
    required this.weeklyPercentage,
    required this.achievements,
  });

  factory GoalsData.fromJson(Map<String, dynamic> json) {
    return GoalsData(
      weeklyTarget: (json['weeklyTarget'] ?? 25000).toDouble(),
      weeklyProgress: (json['weeklyProgress'] ?? 0).toDouble(),
      weeklyPercentage: json['weeklyPercentage'] ?? 0,
      achievements: (json['achievements'] as List? ?? [])
          .map((e) => GoalAchievement.fromJson(e))
          .toList(),
    );
  }
}

class GoalsState {
  final GoalsData? goals;
  final bool isLoading;
  final String? error;

  GoalsState({this.goals, this.isLoading = false, this.error});

  factory GoalsState.initial() {
    return GoalsState();
  }

  GoalsState copyWith({
    GoalsData? goals,
    bool? isLoading,
    String? error,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
