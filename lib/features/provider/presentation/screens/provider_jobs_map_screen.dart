import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/themes/colors.dart';
import '../../../home/providers/location_provider.dart';
import '../../providers/nearby_jobs_provider.dart';
import '../../providers/provider_job_provider.dart';
import '../../models/provider_job_model.dart';

/// Stage 1 job discovery: a map of open jobs around the provider, with green
/// (normal) and red (emergency) pins. Tapping a pin opens the job detail sheet
/// where the provider can accept the job directly.
class ProviderJobsMapScreen extends ConsumerStatefulWidget {
  const ProviderJobsMapScreen({super.key});

  @override
  ConsumerState<ProviderJobsMapScreen> createState() => _ProviderJobsMapScreenState();
}

class _ProviderJobsMapScreenState extends ConsumerState<ProviderJobsMapScreen> {
  final MapController _mapController = MapController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final jobsAsync = ref.watch(nearbyJobsProvider);
    final position = locationState.currentPosition;
    final jobs = jobsAsync.valueOrNull ?? const <ProviderJob>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map with job pins
          Positioned.fill(child: _buildMap(position, jobs)),
          // Location prompt / GPS waiting state
          if (locationState.isLoading || position == null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Finding your location...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (jobs.isEmpty && !jobsAsync.isLoading)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'No jobs within 20 km right now.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
          // Summary alert — tap to zoom out to all pins
          if (jobs.isNotEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 16,
              right: 16,
              child: _buildSummaryPill(jobs),
            ),
          // Nearby jobs list
          if (jobs.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildJobsPanel(jobs, position),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(Position? position, List<ProviderJob> jobs) {
    final currentPosition = position;
    final center = currentPosition != null
        ? LatLng(currentPosition.latitude, currentPosition.longitude)
        : const LatLng(-1.286389, 36.817223);
    final zoom = currentPosition != null ? 14.0 : 6.0;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onMapReady: () {
          if (currentPosition != null && !_initialized) {
            _initialized = true;
            _mapController.move(center, 14.0);
          }
        },
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.the_guy',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        if (currentPosition != null)
          MarkerLayer(markers: [_userMarker(currentPosition)]),
        if (jobs.isNotEmpty)
          MarkerLayer(
            markers: jobs.map((job) => _jobMarker(job)).toList(),
          ),
      ],
    );
  }

  Marker _userMarker(Position position) {
    return Marker(
      point: LatLng(position.latitude, position.longitude),
      width: 40,
      height: 40,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }

  Marker _jobMarker(ProviderJob job) {
    final isEmergency = job.urgency == 'INSTANT';
    final color = isEmergency ? Colors.red : Colors.green;

    return Marker(
      point: LatLng(job.pickupLat, job.pickupLng),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _openJobDetail(job),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEmergency)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'URGENT',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _categoryIcon(job.category),
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(List<ProviderJob> jobs) {
    final urgentCount = jobs.where((j) => j.urgency == 'INSTANT').length;
    final closest = jobs.map((j) => j.distance).reduce((a, b) => a < b ? a : b);
    final closestLabel = closest < 1
        ? '${(closest * 1000).round()} m'
        : '${closest.toStringAsFixed(1)} km';

    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _fitToJobs(jobs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.work, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${jobs.length} jobs nearby',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (urgentCount > 0) ...[
                const SizedBox(width: 10),
                Icon(Icons.emergency, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  '$urgentCount urgent',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Icon(Icons.near_me, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text(
                'Closest $closestLabel',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const Spacer(),
              Icon(Icons.center_focus_strong, size: 18, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  void _fitToJobs(List<ProviderJob> jobs) {
    final position = ref.read(locationProvider).currentPosition;
    if (position == null || jobs.isEmpty) return;

    var minLat = position.latitude, maxLat = position.latitude;
    var minLng = position.longitude, maxLng = position.longitude;
    for (final job in jobs) {
      if (job.pickupLat < minLat) minLat = job.pickupLat;
      if (job.pickupLat > maxLat) maxLat = job.pickupLat;
      if (job.pickupLng < minLng) minLng = job.pickupLng;
      if (job.pickupLng > maxLng) maxLng = job.pickupLng;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 96, 48, 200),
      ),
    );
  }

  Widget _buildJobsPanel(List<ProviderJob> jobs, Position? position) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.32,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              'Jobs Near You',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobCard(job, position);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(ProviderJob job, Position? position) {
    final isEmergency = job.urgency == 'INSTANT';

    return Material(
      color: isEmergency ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openJobDetail(job),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(job.category),
                  color: isEmergency ? Colors.red : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.category,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isEmergency)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.distance.toStringAsFixed(1)} km \u2022 KES ${job.price.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _openJobDetail(ProviderJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _JobDetailSheet(job: job),
    );
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'carpenter':
        return Icons.handyman;
      case 'mason':
        return Icons.construction;
      case 'painting':
        return Icons.format_paint;
      case 'moving':
        return Icons.local_shipping;
      case 'gardening':
      case 'lawn & compound maintenance':
      case 'hedge & fence trimming':
      case 'tree services':
        return Icons.local_florist;
      case 'irrigation & borehole services':
        return Icons.water_drop;
      case 'appliance repair':
        return Icons.home_repair_service;
      case 'tutoring':
        return Icons.school;
      case 'pet care':
        return Icons.pets;
      case 'health':
        return Icons.medical_services;
      case 'cleaning':
      case 'mama fua':
      case 'commercial cleaning':
      case 'carpet & sofa cleaning':
      case 'pressure washing':
        return Icons.cleaning_services;
      default:
        return Icons.handyman;
    }
  }
}

class _JobDetailSheet extends ConsumerWidget {
  final ProviderJob job;

  const _JobDetailSheet({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmergency = job.urgency == 'INSTANT';
    final jobState = ref.watch(providerJobProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isEmergency ? Colors.red.shade50 : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.work,
                    color: isEmergency ? Colors.red : AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.category,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Job for ${job.customerName}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isEmergency)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'EMERGENCY JOB',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _detailRow(Icons.description, 'Description', job.description),
            const SizedBox(height: 8),
            _detailRow(
              Icons.location_on,
              'Distance',
              '${job.distance.toStringAsFixed(1)} km away',
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.attach_money,
              'Budget',
              'KES ${job.price.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 20),
            if (jobState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final declined = await ref
                            .read(providerJobProvider.notifier)
                            .declineJob(job.id);
                        if (declined && context.mounted) Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final accepted = await ref
                            .read(providerJobProvider.notifier)
                            .acceptJob(job.id, job: job);
                        if (accepted && context.mounted) {
                          Navigator.pop(context);
                          context.pushReplacement('/provider/active-job');
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept Job', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      ],
    );
  }
}
