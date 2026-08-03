import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../core/themes/colors.dart';

Future<void> showProviderDetailSheet(
  BuildContext context,
  NearbyProviderModel provider, {
  required VoidCallback onRequestService,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ProviderDetailSheet(
      provider: provider,
      onRequestService: onRequestService,
    ),
  );
}

class ProviderDetailSheet extends StatelessWidget {
  final NearbyProviderModel provider;
  final VoidCallback onRequestService;

  const ProviderDetailSheet({
    super.key,
    required this.provider,
    required this.onRequestService,
  });

  String get _distanceText {
    final km = provider.distance / 1000;
    return km < 1 ? '${provider.distance.round()}m away' : '${km.toStringAsFixed(1)}km away';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: provider.imageUrl != null && provider.imageUrl!.isNotEmpty
                          ? NetworkImage(provider.imageUrl!)
                          : null,
                      child: provider.imageUrl == null || provider.imageUrl!.isEmpty
                          ? Text(
                              provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    if (provider.isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              provider.category,
                              style: const TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            provider.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat(icon: Icons.work_outline, value: '${provider.jobsCompleted}', label: 'Jobs'),
                _stat(icon: Icons.location_on_outlined, value: _distanceText, label: 'Distance'),
                _stat(icon: Icons.access_time, value: '${provider.etaMinutes} min', label: 'ETA'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'From KES ${provider.priceEstimate.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/provider/${provider.id}');
                    },
                    icon: const Icon(Icons.person_outline),
                    label: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRequestService();
                    },
                    icon: const Icon(Icons.bolt),
                    label: const Text('Request Service'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
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

  Widget _stat({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
