import 'package:flutter/material.dart';

class JobStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const JobStatusTimeline({
    super.key,
    required this.currentStatus,
    this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      StatusStep(
        label: 'Requested',
        icon: Icons.add_circle_outline,
        isCompleted: createdAt != null,
        timestamp: createdAt,
      ),
      StatusStep(
        label: 'Accepted',
        icon: Icons.check_circle_outline,
        isCompleted: acceptedAt != null,
        timestamp: acceptedAt,
      ),
      StatusStep(
        label: 'In Progress',
        icon: Icons.build,
        isCompleted: startedAt != null,
        timestamp: startedAt,
      ),
      StatusStep(
        label: 'Completed',
        icon: Icons.done_all,
        isCompleted: completedAt != null,
        timestamp: completedAt,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (index) {
              return _buildStep(steps[index], index, steps.length);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(StatusStep step, int index, int total) {
    final isLast = index == total - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isCompleted
                      ? Colors.green.shade500
                      : Colors.grey.shade300,
                ),
                child: Icon(step.icon, size: 18, color: Colors.white),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: step.isCompleted
                      ? Colors.green.shade500
                      : Colors.grey.shade300,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: step.isCompleted
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: step.isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                if (step.timestamp != null)
                  Text(
                    _formatTime(step.timestamp!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class StatusStep {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final DateTime? timestamp;

  const StatusStep({
    required this.label,
    required this.icon,
    required this.isCompleted,
    this.timestamp,
  });
}
