import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/review_summary_provider.dart';

class SqsBreakdownCard extends ConsumerWidget {
  final String providerId;

  const SqsBreakdownCard({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(reviewSummaryProvider);

    if (summaryState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (summaryState.summary == null) {
      return const SizedBox.shrink();
    }

    final summary = summaryState.summary!;

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
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Review Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSqsColor(summary.overallSqs).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.overallSqs.toStringAsFixed(0)}/100',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getSqsColor(summary.overallSqs),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${summary.totalReviews} reviews', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ...summary.categories.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCategoryName(entry.key),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      Text(
                        entry.value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: entry.value / 100.0,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(_getSqsColor(entry.value)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getSqsColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatCategoryName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
