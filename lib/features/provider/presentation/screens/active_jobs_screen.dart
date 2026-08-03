import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/provider_job_provider.dart';
import '../../models/provider_job_model.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/services/tracking_engine.dart';
import '../../../../core/utils/location_utils.dart';

class ActiveJobsScreen extends ConsumerStatefulWidget {
  const ActiveJobsScreen({super.key});

  @override
  ConsumerState<ActiveJobsScreen> createState() => _ActiveJobsScreenState();
}

class _ActiveJobsScreenState extends ConsumerState<ActiveJobsScreen> {
  String? _trackedJobId;

  @override
  void initState() {
    super.initState();
    ref.listenManual(providerJobProvider, (prev, next) {
      _handleJobChange(next.activeJob);
    });
  }

  void _handleJobChange(ProviderJob? job) {
    final engine = ref.read(trackingEngineProvider);

    if (job == null) {
      if (_trackedJobId != null) {
        engine.stopTracking();
        _trackedJobId = null;
      }
      return;
    }

    if (job.status == 'completed' || job.status == 'cancelled' || job.status == 'awaiting_confirmation') {
      if (_trackedJobId != null) {
        engine.stopTracking();
        _trackedJobId = null;
      }
      return;
    }

    if (engine.isTracking && _trackedJobId == job.id) return;

    if (['accepted', 'en_route', 'arrived', 'in_progress'].contains(job.status)) {
      engine.startProviderTracking(job.id);
      _trackedJobId = job.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);
    final activeJob = jobState.activeJob;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Jobs')),
      body: activeJob == null
          ? _buildEmptyState()
          : _buildActiveJobDetails(activeJob),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No active jobs', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(
            'When you accept a job, it will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobDetails(ProviderJob job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJobHeroCard(job),
          const SizedBox(height: 20),
          _buildJobTimeline(job),
          const SizedBox(height: 20),
          _buildCustomerNotes(job),
          const SizedBox(height: 20),
          if (job.status == 'awaiting_confirmation') ...[
            _buildCompletionEvidence(job),
            const SizedBox(height: 20),
          ],
          _buildActionButtons(job),
        ],
      ),
    );
  }

  Widget _buildJobHeroCard(ProviderJob job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(job.status),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              if (job.distance > 0)
                Text(
                  '${job.distance.toStringAsFixed(1)} km away',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job.category,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            job.description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroStat(Icons.person, 'Customer'),
              const SizedBox(width: 20),
              _heroStat(Icons.attach_money, 'KES ${job.price.toStringAsFixed(0)}'),
              const SizedBox(width: 20),
              _heroStat(Icons.schedule, _formatTime(job.requestedAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildJobTimeline(ProviderJob job) {
    final steps = [
      ('Accepted', Icons.check_circle, 'accepted'),
      ('Driving', Icons.directions_car, 'en_route'),
      ('Arrived', Icons.location_on, 'arrived'),
      ('Working', Icons.build, 'in_progress'),
      ('Confirming', Icons.pending, 'waiting_confirmation'),
      ('Completed', Icons.done_all, 'completed'),
    ];

    final currentStatusIndex = steps.indexWhere((s) => s.$3 == job.status);
    final activeIndex = currentStatusIndex >= 0 ? currentStatusIndex : 0;

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
          const Text('Job Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final (label, icon, status) = steps[index];
            final isCompleted = index < activeIndex;
            final isActive = index == activeIndex;
            final isFuture = index > activeIndex;

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : isActive
                                ? AppColors.primary
                                : Colors.grey.shade200,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : icon,
                        color: isCompleted || isActive ? Colors.white : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 24,
                        color: isCompleted ? Colors.green.shade300 : Colors.grey.shade200),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isFuture ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerNotes(ProviderJob job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Customer Notes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionEvidence(ProviderJob job) {
    return Container(
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
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Completion Evidence Submitted',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (job.completionNotes != null && job.completionNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              job.completionNotes!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
          if (job.completionPhotos != null && job.completionPhotos!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: job.completionPhotos!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    job.completionPhotos![i],
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
    );
  }

  Widget _buildActionButtons(ProviderJob job) {
    final notifier = ref.read(providerJobProvider.notifier);

    switch (job.status) {
      case 'accepted':
        return _primaryAction(
          label: 'Start Driving',
          icon: Icons.directions_car,
          onPressed: () => notifier.updateJobStatus(job.id, 'en_route'),
        );
      case 'en_route':
        return _primaryAction(
          label: 'Arrived at Location',
          icon: Icons.location_on,
          onPressed: () => notifier.updateJobStatus(job.id, 'arrived'),
        );
      case 'arrived':
        return _primaryAction(
          label: 'Start Job',
          icon: Icons.build,
          onPressed: () => notifier.updateJobStatus(job.id, 'in_progress'),
        );
      case 'in_progress':
        return _primaryAction(
          label: 'Complete Job',
          icon: Icons.check_circle,
          onPressed: () => _showCompletionDialog(job),
          color: Colors.green,
        );
      case 'awaiting_confirmation':
        return _buildAwaitingConfirmationCard(job);
      default:
        return const SizedBox();
    }
  }

  Widget _buildAwaitingConfirmationCard(ProviderJob job) {
    final deadline = job.confirmationDeadline ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_top, size: 40, color: Colors.orange.shade400),
          const SizedBox(height: 8),
          const Text(
            'Waiting for Customer Confirmation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'The customer has 72 hours to confirm. You will be notified once they respond.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (deadline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Auto-confirms after: $deadline',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showCompletionDialog(ProviderJob job) async {
    final notesController = TextEditingController();
    final pickedFiles = <File>[];
    final uploadedUrls = <String>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Complete Job',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Completion Notes (optional)',
                      hintText: 'Describe what was done...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.camera);
                          if (image != null) {
                            setDialogState(() => pickedFiles.add(File(image.path)));
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final images = await picker.pickMultiImage();
                          for (final img in images) {
                            setDialogState(() => pickedFiles.add(File(img.path)));
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                  if (pickedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pickedFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  pickedFiles[i],
                                  width: 80, height: 80, fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0, right: 0,
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => pickedFiles.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final notifier = ref.read(providerJobProvider.notifier);

                        Position? pos;
                        try {
                          pos = await LocationUtils.getCurrentLocation();
                        } catch (_) {}

                        notifier.completeJob(
                          job.id,
                          completionNotes: notesController.text.isNotEmpty
                              ? notesController.text : null,
                          completionPhotos: uploadedUrls.isNotEmpty
                              ? uploadedUrls : null,
                          latitude: pos?.latitude,
                          longitude: pos?.longitude,
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Submit Completion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _primaryAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 22),
            label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _secondaryAction(Icons.phone, 'Call', () {}),
            _secondaryAction(Icons.message, 'Chat', () {}),
            _secondaryAction(Icons.emergency, 'Emergency', () {}, isDestructive: true),
          ],
        ),
      ],
    );
  }

  Widget _secondaryAction(IconData icon, String label, VoidCallback onPressed, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.withValues(alpha: 0.1) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDestructive ? Colors.red : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 11,
            color: isDestructive ? Colors.red : Colors.grey.shade600,
          )),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted': return 'Accepted';
      case 'en_route': return 'Driving';
      case 'arrived': return 'Arrived';
      case 'in_progress': return 'Working';
      case 'awaiting_confirmation': return 'Awaiting Confirmation';
      case 'completed': return 'Completed';
      default: return status;
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
