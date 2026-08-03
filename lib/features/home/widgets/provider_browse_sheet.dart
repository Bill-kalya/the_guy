import 'package:flutter/material.dart';
import '../../../shared/constants/service_categories.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../core/themes/colors.dart';

/// Collapsible browse panel: category chips, a count header, and a scrollable
/// list of provider cards. Rendered inside a DraggableScrollableSheet so the
/// map stays visible above it.
class ProviderBrowseSheet extends StatelessWidget {
  final ScrollController scrollController;
  final List<ServiceCategory> categories;
  final String? selectedCategory;
  final List<NearbyProviderModel> providers;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<NearbyProviderModel> onProviderTap;
  final ValueChanged<NearbyProviderModel> onRequestService;

  const ProviderBrowseSheet({
    super.key,
    required this.scrollController,
    required this.categories,
    required this.selectedCategory,
    required this.providers,
    required this.onCategorySelected,
    required this.onProviderTap,
    required this.onRequestService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryChips(),
          const SizedBox(height: 8),
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: providers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: providers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      return _ProviderCard(
                        provider: provider,
                        onTap: () => onProviderTap(provider),
                        onRequest: () => onRequestService(provider),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(label: 'All', value: null),
          ...categories.map(
            (cat) => _chip(label: cat.name, value: cat.name),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required String? value}) {
    final selected = selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(color: Colors.grey.shade300),
        onSelected: (_) => onCategorySelected(value),
      ),
    );
  }

  Widget _buildHeader() {
    final title = selectedCategory ?? 'All Services';
    final count = providers.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(
            selectedCategory == null
                ? Icons.grid_view_rounded
                : Icons.handyman_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            '$count ${count == 1 ? 'provider' : 'providers'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No providers found in this category',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final NearbyProviderModel provider;
  final VoidCallback onTap;
  final VoidCallback onRequest;

  const _ProviderCard({
    required this.provider,
    required this.onTap,
    required this.onRequest,
  });

  String get _distanceText {
    final km = provider.distance / 1000;
    return km < 1
        ? '${provider.distance.round()}m'
        : '${km.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = provider.imageUrl != null && provider.imageUrl!.isNotEmpty;

    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: hasImage
                        ? NetworkImage(provider.imageUrl!)
                        : null,
                    child: hasImage
                        ? null
                        : Text(
                            provider.name.isNotEmpty
                                ? provider.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: provider.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          _distanceText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'From KES ${provider.priceEstimate.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
