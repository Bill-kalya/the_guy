import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../repository/search_repository.dart';
import '../../../shared/constants/service_categories.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

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
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'What service do you need?'),
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

class SearchResultsScreen extends ConsumerWidget {
  final String query;
  const SearchResultsScreen({Key? key, required this.query}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use a placeholder for location; callers should provide real location in production
    final req = SearchRequest(query: query, lat: 0.0, lng: 0.0);
    final resultsAsync = ref.watch(searchResultsProvider(req));

    return Scaffold(
      appBar: AppBar(title: Text(query)),
      body: resultsAsync.when(
        data: (res) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('${res.totalResults} providers near you', style: const TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: res.providers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
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

class _ProviderCard extends StatelessWidget {
  final dynamic provider;
  const _ProviderCard({Key? key, required this.provider}) : super(key: key);

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
      subtitle: Text('\u2B50 ${sqs.toStringAsFixed(0)}% SQS • \u{1F4CD} ${distance}m • ETA ${eta} min'),
      trailing: verified ? const Icon(Icons.verified, color: Colors.green) : null,
      onTap: () {},
    );
  }
}
