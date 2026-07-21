import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

class CustomerStats {
  final int totalJobs;
  final int completedJobs;
  final int activeJobs;

  CustomerStats({required this.totalJobs, required this.completedJobs, required this.activeJobs});

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      totalJobs: json['totalJobs'] ?? 0,
      completedJobs: json['completedJobs'] ?? 0,
      activeJobs: json['activeJobs'] ?? 0,
    );
  }
}

final customerStatsProvider = FutureProvider<CustomerStats>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get(Endpoints.customerStats);
    if (response.statusCode == 200 && response.data['data'] != null) {
      return CustomerStats.fromJson(response.data['data']);
    }
  } catch (_) {}
  return CustomerStats(totalJobs: 0, completedJobs: 0, activeJobs: 0);
});
