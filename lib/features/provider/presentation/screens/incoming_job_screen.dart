import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/provider_job_provider.dart';
import '../../models/provider_job_model.dart';

class IncomingJobScreen extends ConsumerStatefulWidget {
  const IncomingJobScreen({super.key});

  @override
  ConsumerState<IncomingJobScreen> createState() => _IncomingJobScreenState();
}

class _IncomingJobScreenState extends ConsumerState<IncomingJobScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playNotificationSound();
    _listenForJobTimeout();
  }

  void _playNotificationSound() async {
    await _audioPlayer.play(AssetSource('sounds/incoming_job.mp3'));
  }

  void _listenForJobTimeout() {
    Future.delayed(const Duration(seconds: 30), () {
      final currentJob = ref.read(providerJobProvider).incomingJob;
      if (currentJob != null && !currentJob.hasResponded) {
        _autoDeclineJob(currentJob);
      }
    });
  }

  void _autoDeclineJob(ProviderJob job) async {
    await ref.read(providerJobProvider.notifier).declineJob(job.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job automatically declined after 30 seconds'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);
    final job = jobState.incomingJob;

    if (job == null) {
      return const Scaffold(body: Center(child: Text('No incoming jobs')));
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildJobDetails(job),
              const SizedBox(height: 32),
              _buildActionButtons(job),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active,
            color: Colors.orange.shade800,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'NEW SERVICE REQUEST!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A customer needs your service',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildJobDetails(ProviderJob job) {
    return Column(
      children: [
        _buildDetailRow(Icons.category, 'Service', job.category),
        const Divider(),
        _buildDetailRow(Icons.description, 'Description', job.description),
        const Divider(),
        _buildDetailRow(
          Icons.location_on,
          'Distance',
          '${job.distance} km away',
        ),
        const Divider(),
        _buildDetailRow(Icons.attach_money, 'Price', 'KES ${job.price}'),
        const Divider(),
        _buildDetailRow(
          Icons.access_time,
          'Requested',
          _formatTime(job.requestedAt),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ProviderJob job) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await ref.read(providerJobProvider.notifier).declineJob(job.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'DECLINE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final accepted = await ref
                  .read(providerJobProvider.notifier)
                  .acceptJob(job.id);
              if (accepted && mounted) {
                Navigator.pushReplacementNamed(context, '/provider/active-job');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ACCEPT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    return '${difference.inHours} hours ago';
  }
}
