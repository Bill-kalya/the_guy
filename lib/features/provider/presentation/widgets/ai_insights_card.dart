import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/review_summary_provider.dart';

class AiInsightsCard extends ConsumerWidget {
  final String providerId;

  const AiInsightsCard({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(reviewSummaryProvider);

    if (summaryState.isLoading || summaryState.summary == null) {
      return const SizedBox.shrink();
    }

    final categories = summaryState.summary!.categories;
    if (categories.isEmpty) return const SizedBox.shrink();

    // Sort categories by score
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strengths = sorted.where((e) => e.value >= 85).take(3).toList();
    final improvements = sorted.where((e) => e.value < 85).take(3).toList();

    if (strengths.isEmpty && improvements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          if (strengths.isNotEmpty) ...[
            Text('Strengths', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
            const SizedBox(height: 8),
            ...strengths.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_formatCategoryName(e.key)} — ${_getStrengthMessage(e.key)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
          ],
          if (improvements.isNotEmpty) ...[
            Text('Areas to Improve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
            const SizedBox(height: 8),
            ...improvements.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.orange.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_formatCategoryName(e.key)} — ${_getImprovementMessage(e.key)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  String _formatCategoryName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _getStrengthMessage(String category) {
    switch (_formatCategoryName(category)) {
      case 'Professionalism': return 'Customers frequently praise your professionalism';
      case 'Communication': return 'Your clear communication keeps customers informed';
      case 'Timeliness': return 'Consistently arrive on time, customers love this';
      case 'Work Quality': return 'Consistently deliver clean, high-quality work';
      case 'Reliability': return 'Customers trust you to complete jobs reliably';
      case 'Courtesy': return 'Your friendly attitude makes customers comfortable';
      case 'Value For Money': return 'Customers feel they get great value';
      default: return 'Strong performance';
    }
  }

  String _getImprovementMessage(String category) {
    switch (_formatCategoryName(category)) {
      case 'Professionalism': return 'Consider more formal presentation';
      case 'Communication': return 'Try updating customers before arrival';
      case 'Timeliness': return 'Focus on punctuality for better ratings';
      case 'Work Quality': return 'Pay extra attention to finishing details';
      case 'Reliability': return 'Ensure consistent follow-through';
      case 'Courtesy': return 'Small gestures improve customer experience';
      case 'Value For Money': return 'Communicate value clearly before starting';
      default: return 'Room to improve';
    }
  }
}
