import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provider_job_provider.dart';
import '../../models/provider_job_model.dart';

class ActiveJobsScreen extends ConsumerStatefulWidget {
  const ActiveJobsScreen({super.key});

  @override
  ConsumerState<ActiveJobsScreen> createState() => _ActiveJobsScreenState();
}

class _ActiveJobsScreenState extends ConsumerState<ActiveJobsScreen> {
  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);
    final activeJob = jobState.activeJob;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Jobs')),
      body: activeJob == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No active jobs',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When you accept a job, it will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _buildActiveJobDetails(activeJob),
    );
  }

  Widget _buildActiveJobDetails(ProviderJob job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status timeline
          _buildStatusTimeline(job.status),
          const SizedBox(height: 24),

          // Customer info
          _buildCustomerInfo(job),
          const SizedBox(height: 16),

          // Job details
          _buildJobDetails(job),
          const SizedBox(height: 16),

          // Location info
          _buildLocationInfo(job),
          const SizedBox(height: 24),

          // Action buttons based on status
          _buildActionButtons(job),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    final steps = [
      'accepted',
      'en_route',
      'arrived',
      'in_progress',
      'completed',
    ];
    final currentIndex = steps.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
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
                      _getStatusIcon(steps[index]),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusLabel(steps[index]),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCompleted ? Colors.green : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(ProviderJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        job.customerPhone,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    // Make phone call
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    // Navigate to chat
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetails(ProviderJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Service', job.category),
            _buildDetailRow('Description', job.description),
            _buildDetailRow('Price', 'KES ${job.price}'),
            _buildDetailRow('Requested', _formatDate(job.requestedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(ProviderJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Pickup', job.address ?? 'Address not specified'),
            if (job.dropoffLat != null)
              _buildDetailRow('Dropoff', 'Dropoff location set'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Open maps
                },
                icon: const Icon(Icons.map),
                label: const Text('Open in Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ProviderJob job) {
    final notifier = ref.read(providerJobProvider.notifier);

    switch (job.status) {
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  notifier.updateJobStatus(job.id, 'en_route');
                },
                icon: const Icon(Icons.directions_car),
                label: const Text('Start Driving'),
              ),
            ),
          ],
        );

      case 'en_route':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  notifier.updateJobStatus(job.id, 'arrived');
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Arrived at Location'),
              ),
            ),
          ],
        );

      case 'arrived':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  notifier.updateJobStatus(job.id, 'in_progress');
                },
                icon: const Icon(Icons.build),
                label: const Text('Start Job'),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  notifier.updateJobStatus(job.id, 'completed');
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete Job'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'en_route':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check;
      default:
        return Icons.circle;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'en_route':
        return 'En Route';
      case 'arrived':
        return 'Arrived';
      case 'in_progress':
        return 'Working';
      case 'completed':
        return 'Done';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute}';
  }
}
