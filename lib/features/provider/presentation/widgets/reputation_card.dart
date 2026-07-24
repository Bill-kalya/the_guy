import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/performance_provider.dart';

class ReputationCard extends ConsumerWidget {
  const ReputationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfState = ref.watch(performanceProvider);

    if (perfState.isLoading) {
      return const SizedBox.shrink();
    }

    // Use completion rate as a proxy for reputation (will be replaced with real reputation endpoint)
    final score = perfState.performance != null
        ? ((perfState.performance!.completionRate * 0.4) +
            (perfState.performance!.acceptanceRate * 0.3) +
            (perfState.performance!.repeatCustomerCount * 0.3)).clamp(0, 100).toInt()
        : 0;

    final tier = score >= 90
        ? 'Elite Provider'
        : score >= 75
            ? 'Premium Provider'
            : score >= 50
                ? 'Standard Provider'
                : 'Building Reputation';

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
              Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Reputation Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(_getScoreColor(score)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text('/100', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(score).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tier,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getScoreColor(score),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (perfState.performance != null) ...[
            _buildContributionRow('Job Completion', 0.4, Colors.green),
            _buildContributionRow('Customer Satisfaction', 0.3, Colors.blue),
            _buildContributionRow('Response Rate', 0.2, Colors.purple),
            _buildContributionRow('Consistency', 0.1, Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildContributionRow(String label, double weight, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Text('${(weight * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
