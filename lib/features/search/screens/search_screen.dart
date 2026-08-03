import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../repository/search_repository.dart';
import '../../home/providers/location_provider.dart';
import '../../../shared/constants/service_categories.dart';
import '../../../shared/constants/kenya_towns.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit(String q) {
    if (q.trim().isEmpty) return;
    // Navigate to results screen with query as argument
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchResultsScreen(query: q.trim())));
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text;
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(q));

    return Scaffold(
      appBar: AppBar(title: const Text('Search services'), leading: BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'What service do you need?',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() {}),
              onSubmitted: _onSubmit,
            ),
            const SizedBox(height: 12),
            const Text('Popular Services', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: 
              ServiceCategories.popular.map((cat) => _chip(cat.name)).toList(),
            ),
            const SizedBox(height: 16),
            if (q.isNotEmpty) ...[
              const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              suggestionsAsync.when(
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((s) => ListTile(title: Text(s), onTap: () => _onSubmit(s))).toList(),
                ),
                loading: () => const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox.shrink(),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => ActionChip(label: Text(label), onPressed: () => _onSubmit(label));
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