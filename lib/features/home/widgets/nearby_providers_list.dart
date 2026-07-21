import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../core/themes/colors.dart';


class NearbyProvidersList extends StatelessWidget {
  final Position? position;
  final List<NearbyProviderModel>? providers;
  final bool isLoading;
  final String? error;

  const NearbyProvidersList({
    super.key,
    this.position,
    this.providers,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (error != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 32, color: Colors.red),
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    // No location state
    if (position == null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 32, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Enable location to see nearby providers'),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (providers == null || providers!.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 32, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('No providers found nearby'),
              const SizedBox(height: 4),
              Text(
                'Try expanding your search radius',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: providers!.length,
      itemBuilder: (context, index) {
        final provider = providers![index];
        return _buildProviderCard(context, provider);
      },
    );
  }

  Widget _buildProviderCard(BuildContext context, NearbyProviderModel provider) {

    final distanceKm = provider.distance / 1000;
    final distanceStr = distanceKm < 1
        ? '${provider.distance.round()}m'
        : '${distanceKm.toStringAsFixed(1)}km';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/provider/${provider.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Provider avatar with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      provider.name.isNotEmpty
                          ? provider.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (provider.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Provider details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Rating
                        Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '(${provider.jobsCompleted} jobs)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Distance
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          distanceStr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 8),

                        // ETA
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          '${provider.etaMinutes} min',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category and price
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            provider.category,
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        Text(
                          'KSH ${provider.priceEstimate.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}