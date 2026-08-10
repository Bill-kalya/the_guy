import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../shared/widgets/provider_badge.dart';
import '../../../core/themes/colors.dart';
import '../../jobs/screens/request_service_screen.dart';

class ProviderPublicProfileScreen extends StatelessWidget {
  final NearbyProviderModel provider;

  const ProviderPublicProfileScreen({super.key, required this.provider});

  String get _distanceText {
    final km = provider.distance / 1000;
    return km < 1 ? '${provider.distance.round()}m' : '${km.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            backgroundImage: provider.imageUrl != null && provider.imageUrl!.isNotEmpty
                                ? NetworkImage(provider.imageUrl!)
                                : null,
                            child: provider.imageUrl == null || provider.imageUrl!.isEmpty
                                ? Text(
                                    provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          if (provider.isOnline)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          provider.category,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      if (provider.badge != null) ...[
                        const SizedBox(height: 8),
                        ProviderBadgeChip(badge: provider.badge),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(context, Icons.star, provider.rating.toStringAsFixed(1), 'Rating'),
                      _stat(context, Icons.work_outline, '${provider.jobsCompleted}', 'Jobs Done'),
                      _stat(context, Icons.location_on_outlined, _distanceText, 'Away'),
                      _stat(context, Icons.access_time, '${provider.etaMinutes}', 'Min ETA'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _infoRow(Icons.verified_outlined, 'Verification',
                      provider.verificationLevel == 'NONE' ? 'Not verified' : 'Verified'),
                  const Divider(height: 24),
                  _infoRow(Icons.analytics_outlined, 'Service Quality',
                      '${(provider.serviceQualityScore ?? 0).toStringAsFixed(0)}%'),
                  const Divider(height: 24),
                  _infoRow(Icons.payments_outlined, 'Price range',
                      provider.priceLabel),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {
              context.push(
                '/request-service',
                extra: RequestServiceArgs(
                  category: provider.category,
                  providerId: provider.id,
                  providerName: provider.name,
                ),
              );
            },
            icon: const Icon(Icons.bolt),
            label: const Text('Request Service'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}
