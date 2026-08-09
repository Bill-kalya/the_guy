import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../repository/search_repository.dart';
import '../../home/providers/location_provider.dart';
import '../../home/providers/nearby_providers_provider.dart';
import '../../../shared/constants/service_categories.dart';
import '../../../shared/constants/kenya_towns.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../core/themes/colors.dart';
import '../../jobs/screens/request_service_screen.dart';

/// Supermarket-style service discovery: category buttons on top, and below a
/// shuffled grid of real service offers from providers near you.
///
/// "Search when you know. Discover when you don't." Submitting the search box
/// jumps straight to [SearchResultsScreen].
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String? _selectedCategory;

  // Shuffle the card order once per dataset so browsing feels like a store
  // shelf rather than a static, distance-sorted list.
  List<NearbyProviderModel>? _cards;
  List<NearbyProviderModel>? _cardsSource;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit(String q) {
    if (q.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchResultsScreen(query: q.trim())),
    );
  }

  void _openProviderDetail(NearbyProviderModel provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ServiceDetailSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text;
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(q));
    final locationState = ref.watch(locationProvider);

    final providersAsync = _selectedCategory == null
        ? ref.watch(nearbyProvidersProvider)
        : ref.watch(nearbyProvidersByCategoryProvider(_selectedCategory!));
    final providers = providersAsync.valueOrNull ?? const <NearbyProviderModel>[];

    if (!identical(_cardsSource, providers)) {
      _cardsSource = providers;
      _cards = [...providers]..shuffle();
    }
    final cards = _cards ?? const <NearbyProviderModel>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: q.isEmpty
                ? _buildBrowse(cards, providersAsync, locationState)
                : _buildSuggestions(suggestionsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'What can we help you with?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Search when you know, discover when you don\u2019t',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (v) => setState(() {}),
                  onSubmitted: _onSubmit,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search for a service...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(AsyncValue<List<String>> suggestionsAsync) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        suggestionsAsync.when(
          data: (items) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.search, color: AppColors.primary),
                      title: Text(s),
                      onTap: () => _onSubmit(s),
                    ))
                .toList(),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBrowse(
    List<NearbyProviderModel> cards,
    AsyncValue<List<NearbyProviderModel>> providersAsync,
    LocationState locationState,
  ) {
    final needsLocation =
        providersAsync.hasError && !locationState.isFresh;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildCategoryRow()),
        SliverToBoxAdapter(child: _buildSectionHeader(cards.length)),
        if (providersAsync.isLoading && cards.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (needsLocation)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildLocationPrompt(),
          )
        else if (cards.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final provider = cards[index];
                  return _ServiceCard(
                    provider: provider,
                    onTap: () => _openProviderDetail(provider),
                  );
                },
                childCount: cards.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'What do you need?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _categoryButton(null, Icons.apps, 'All'),
              ...ServiceCategories.all.map((c) => _categoryButton(c.name, c.icon, c.name)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryButton(String? category, IconData icon, String label) {
    final selected = _selectedCategory == category;
    final bool isActive = selected || category == null && _selectedCategory == null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isActive ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            _selectedCategory = selected ? null : category;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    final label = _selectedCategory == null
        ? 'Services around you \u2728'
        : '$_selectedCategory around you \u2728';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          Text(
            '$count nearby',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Turn on location to see services near you',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Cards are built from providers physically close to you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(locationProvider.notifier).getCurrentLocation(),
              icon: const Icon(Icons.gps_fixed, color: AppColors.primary),
              label: const Text('Use my location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.primaryLight),
            const SizedBox(height: 12),
            const Text(
              'No services found nearby',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Try another category or check back later.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// A service card backed by a real nearby provider: large photo, category,
/// rating, distance, starting price, and trust badges. Tapping it opens the
/// provider detail sheet where the customer can request the service directly.
class _ServiceCard extends StatelessWidget {
  final NearbyProviderModel provider;
  final VoidCallback onTap;

  const _ServiceCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = ServiceCategories.getByName(provider.category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large imagery — photo, or a big playful icon for the category
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: provider.imageUrl != null && provider.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(provider.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: provider.imageUrl == null || provider.imageUrl!.isEmpty
                    ? Icon(
                        category?.icon ?? Icons.handyman,
                        color: AppColors.primary,
                        size: 44,
                      )
                    : null,
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '\u2B50 ${provider.rating.toStringAsFixed(1)} \u2022 ${_distanceLabel(provider.distance)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Row(
                      children: [
                        if (provider.isOnline)
                          _badge(Icons.circle, Colors.green, 'Online')
                        else
                          _badge(Icons.circle_outlined, Colors.grey, 'Offline'),
                        const SizedBox(width: 6),
                        if (provider.verificationLevel != 'NONE')
                          _badge(Icons.verified, Colors.green, 'Verified'),
                      ],
                    ),
                    Text(
                      'From KES ${provider.priceEstimate.round()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  String _distanceLabel(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

/// Bottom sheet with provider + service details and a direct "Request Service"
/// action that pre-selects the category and targets this specific provider.
class _ServiceDetailSheet extends ConsumerWidget {
  final NearbyProviderModel provider;

  const _ServiceDetailSheet({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ServiceCategories.getByName(provider.category);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    image: provider.imageUrl != null && provider.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(provider.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: provider.imageUrl == null || provider.imageUrl!.isEmpty
                      ? Icon(
                          category?.icon ?? Icons.handyman,
                          color: AppColors.primary,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.category,
                        style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.star, 'Rating', '\u2B50 ${provider.rating.toStringAsFixed(1)}'),
            const SizedBox(height: 8),
            _detailRow(Icons.location_on, 'Distance', _distanceLabel(provider.distance)),
            const SizedBox(height: 8),
            _detailRow(Icons.attach_money, 'Budget', 'From KES ${provider.priceEstimate.round()}'),
            const SizedBox(height: 8),
            _detailRow(Icons.work_history, 'Experience', '${provider.jobsCompleted} jobs completed'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/request-service',
                    extra: RequestServiceArgs(
                      category: provider.category,
                      providerId: provider.id,
                      providerName: provider.name,
                    ),
                  );
                },
                icon: const Icon(Icons.request_quote),
                label: const Text('Request Service', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  String _distanceLabel(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  KenyaTown? _selectedTown;

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final pos = locationState.currentPosition;

    final double? lat = pos?.latitude ?? _selectedTown?.latitude;
    final double? lng = pos?.longitude ?? _selectedTown?.longitude;
    final String locationLabel = _selectedTown?.name ?? 'your current location';

    if (lat == null || lng == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.query)),
        body: _LocationPicker(
          isLoading: locationState.isLoading,
          onUseGps: () => ref.read(locationProvider.notifier).getCurrentLocation(),
          onSelectTown: (town) => setState(() => _selectedTown = town),
        ),
      );
    }

    final req = SearchRequest(query: widget.query, lat: lat, lng: lng);
    final resultsAsync = ref.watch(searchResultsProvider(req));

    return Scaffold(
      appBar: AppBar(title: Text(widget.query)),
      body: resultsAsync.when(
        data: (res) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  res.totalResults == 0
                      ? 'No ${widget.query} services available near $locationLabel'
                      : '${res.totalResults} providers near $locationLabel',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: res.providers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _ProviderCard(provider: res.providers[i]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onUseGps;
  final ValueChanged<KenyaTown> onSelectTown;

  const _LocationPicker({
    required this.isLoading,
    required this.onUseGps,
    required this.onSelectTown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.location_off, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        const Text('We could not get your location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Enable GPS or select a town to find providers near you',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onUseGps,
            icon: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.gps_fixed),
            label: const Text('Use my location'),
          ),
        ),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Or choose your town', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: kenyaTowns.length,
            itemBuilder: (context, i) {
              final town = kenyaTowns[i];
              return ListTile(
                leading: const Icon(Icons.location_city, color: Colors.grey),
                title: Text(town.name),
                subtitle: Text(town.county),
                onTap: () => onSelectTown(town),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final dynamic provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Expect NearbyProviderModel
    final name = provider.name ?? 'Provider';
    final sqs = provider.serviceQualityScore ?? 0.0;
    final distance = provider.distance?.toStringAsFixed(0) ?? '0';
    final eta = provider.etaMinutes ?? 0;
    final verified = (provider.verificationLevel ?? 'NONE') != 'NONE';

    return ListTile(
      title: Text(name),
      subtitle: Text('\u2B50 ${sqs.toStringAsFixed(0)}% SQS • \u{1F4CD} ${distance}m • ETA $eta min'),
      trailing: verified ? const Icon(Icons.verified, color: Colors.green) : null,
      onTap: () {},
    );
  }
}
