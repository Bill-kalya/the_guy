import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/job_provider.dart';
import '../models/job_state.dart';
import '../../../shared/widgets/service_quality_score.dart';
import '../../../shared/widgets/user_avatar.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String jobId;

  const ActiveJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Job'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => context.push(
              '/chat/${widget.jobId}',
              extra: {'providerName': jobState.provider?['name'] ?? 'Provider'},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusTimeline(jobState.status),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProviderInfo(jobState.provider),
                  const SizedBox(height: 24),
                  _buildJobDetails(jobState.jobDetails),
                  const SizedBox(height: 24),
                  _buildActionButtons(jobState.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(JobStatus status) {
    final steps = [
      JobStatus.accepted,
      JobStatus.enRoute,
      JobStatus.inProgress,
      JobStatus.completed,
    ];
    final currentIndex = steps.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentIndex;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
                  child: Icon(
                    _getIconForStep(steps[index]),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTitleForStep(steps[index]),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCompleted
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProviderInfo(Map<String, dynamic>? provider) {
    if (provider == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: provider['avatar'],
              name: provider['name'] ?? '',
              radius: 30,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   const SizedBox(height: 4),
                   ServiceQualityScore(
                     score: (provider['serviceQualityScore'] ?? provider['rating'] * 20).toDouble(),
                     size: 40,
                     showLabel: false,
                   ),
                   const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_car, size: 16),
                      const SizedBox(width: 4),
                      Text('${provider['eta']} min away'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () {
                // Call provider
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(JobStatus status) {
    switch (status) {
      case JobStatus.completed:
        return ElevatedButton(
          onPressed: () => context.push('/payment/${widget.jobId}'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Proceed to Payment'),
        );

      case JobStatus.inProgress:
        return OutlinedButton(
          onPressed: () {
            // Mark as completed
            ref.read(jobProvider.notifier).completeJob();
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Mark as Completed'),
        );

      default:
        return const SizedBox();
    }
  }

  IconData _getIconForStep(JobStatus step) {
    switch (step) {
      case JobStatus.accepted:
        return Icons.person;
      case JobStatus.enRoute:
        return Icons.directions_car;
      case JobStatus.inProgress:
        return Icons.build;
      case JobStatus.completed:
        return Icons.check;
      default:
        return Icons.circle;
    }
  }

  String _getTitleForStep(JobStatus step) {
    switch (step) {
      case JobStatus.accepted:
        return 'Assigned';
      case JobStatus.enRoute:
        return 'En Route';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      default:
        return '';
    }
  }

  Widget _buildJobDetails(Map<String, dynamic>? jobDetails) {
    if (jobDetails == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Service', jobDetails['category']),
            _buildDetailRow('Description', jobDetails['description']),
            _buildDetailRow('Location', jobDetails['address']),
            _buildDetailRow('Time', _formatTime(jobDetails['createdAt'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.parse(timestamp);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute}';
  }
}
