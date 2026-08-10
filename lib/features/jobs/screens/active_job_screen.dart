import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../providers/job_provider.dart';
import '../models/job_state.dart';
import '../../../shared/widgets/service_quality_score.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../core/services/tracking_engine.dart';
import '../../../core/utils/location_utils.dart';
import '../../home/widgets/map_widget.dart';
import '../../home/providers/nearby_providers_provider.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String jobId;

  const ActiveJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  String? _providerId;
  Duration _currentEta = Duration.zero;
  Position? _currentPosition;
  LatLng? _deadReckonPosition;

  @override
  void initState() {
    super.initState();
    _initTracking();
    _getCurrentLocation();
  }

  Future<void> _initTracking() async {
    final jobState = ref.read(jobProvider);
    final providerData = jobState.provider;
    if (providerData == null) return;

    final pid = providerData['id'] as String?;
    if (pid == null) return;

    setState(() => _providerId = pid);

    final engine = ref.read(trackingEngineProvider);
    engine.onLocationReceived = (update) {
      if (mounted) {
        setState(() {});
      }
    };
    engine.onEtaUpdated = (eta) {
      if (mounted) {
        setState(() => _currentEta = eta);
      }
    };
    engine.onDeadReckoningUpdate = (position, heading) {
      if (mounted) {
        setState(() => _deadReckonPosition = position);
      }
    };
    engine.startCustomerTracking(widget.jobId, pid);
  }

  Future<void> _getCurrentLocation() async {
    final pos = await LocationUtils.getCurrentLocation();
    if (mounted && pos != null) {
      setState(() => _currentPosition = pos);
    }
  }

  @override
  void dispose() {
    ref.read(trackingEngineProvider).stopTracking();
    super.dispose();
  }

  Map<String, ProviderLocationUpdate> _getLiveLocations() {
    final locations = ref.read(providerLocationsProvider);
    if (_providerId == null) return {};
    final filtered = <String, ProviderLocationUpdate>{};
    if (locations.containsKey(_providerId)) {
      filtered[_providerId!] = locations[_providerId!]!;
    }
    return filtered;
  }

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
          if (jobState.isActive) _buildTrackingMap(),
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

  Widget _buildTrackingMap() {
    final engine = ref.read(trackingEngineProvider);
    final liveLocations = _getLiveLocations();

    return Container(
      height: 220,
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          MapWidget(
            position: _currentPosition,
            liveLocations: liveLocations,
            selectedProviderId: _providerId,
            polyline: engine.routePolyline,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _buildEtaBadge(),
          ),
          if (_deadReckonPosition != null)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Estimating location',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEtaBadge() {
    if (_currentEta == Duration.zero) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            LocationUtils.formatETA(_currentEta),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
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
      JobStatus.awaitingConfirmation,
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
                       Text(
                         _currentEta > Duration.zero
                             ? '${LocationUtils.formatETA(_currentEta)} away'
                             : '${provider['eta']} min away',
                       ),
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
      case JobStatus.accepted:
      case JobStatus.enRoute:
      case JobStatus.arrived:
      case JobStatus.inProgress:
        return _buildEscrowPaymentButton();

      case JobStatus.awaitingConfirmation:
        return _buildCompletionReview();

      case JobStatus.completed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Job completed. Payment was held in escrow and released to the provider.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildEscrowPaymentButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.push('/payment/${widget.jobId}'),
          icon: const Icon(Icons.lock_outline),
          label: const Text('Pay Now — Fund Escrow'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pay to secure your job. Funds are held in escrow and released to the '
          'provider only after you confirm the work is done.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCompletionReview() {
    final jobData = ref.watch(jobProvider).jobDetails;
    final notes = jobData?['completionNotes'] as String?;
    final photos = jobData?['completionPhotos'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Provider has marked this job as complete',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  notes,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
              if (photos != null && photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photos[i],
                        width: 80, height: 80, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80, height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(jobProvider.notifier).confirmCompletion();
                },
                icon: const Icon(Icons.thumb_up),
                label: const Text('Confirm & Release Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(),
                icon: const Icon(Icons.thumb_down, color: Colors.red),
                label: const Text('Not Satisfied — Open Dispute',
                  style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showRejectDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please explain why you are rejecting the completion. This will open a dispute.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Dispute', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      ref.read(jobProvider.notifier).rejectCompletion(result);
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
      case JobStatus.awaitingConfirmation:
        return Icons.hourglass_top;
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
      case JobStatus.awaitingConfirmation:
        return 'Review';
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
