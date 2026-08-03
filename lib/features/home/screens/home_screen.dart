import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/map_widget.dart';
import '../widgets/provider_detail_sheet.dart';
import '../widgets/provider_browse_sheet.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_providers_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/presentation/widgets/admin_mode_banner.dart';
import '../../jobs/screens/request_service_screen.dart';
import '../../../core/network/websocket_service.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../core/themes/colors.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/constants/service_categories.dart';
import 'home_screen_desktop.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedCategory;
  String? _selectedProviderId;
  final GlobalKey<MapWidgetState> _mapKey = GlobalKey<MapWidgetState>();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocation();
      _connectWebSocket();
    });
  }

  void _getLocation() async {
    await ref.read(locationProvider.notifier).getCurrentLocation();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _connectWebSocket() async {
    final wsService = ref.read(webSocketServiceProvider);
    await wsService.connect();
  }

  void _requireAuthThen(BuildContext context, VoidCallback action) {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      action();
    } else {
      context.push('/login', extra: {'redirectAfterLogin': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;

    // Watch nearby providers data
    final nearbyProvidersAsync = ref.watch(nearbyProvidersProvider);
    final liveLocations = ref.watch(providerLocationsProvider);

    return ResponsiveLayout(
      mobile: Scaffold(
        body: Column(
          children: [
            const AdminModeBanner(),
            Expanded(
              child: _buildBody(locationState, isAuthenticated, nearbyProvidersAsync, liveLocations),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton: isAuthenticated && _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/request-service'),
                icon: const Icon(Icons.add),
                label: const Text('Request Service'),
                backgroundColor: Colors.blue,
              )
            : null,
      ),
      desktop: HomeScreenDesktop(),
    );
  }

  Widget _buildBody(
    LocationState locationState,
    bool isAuthenticated,
    AsyncValue<List<NearbyProviderModel>> nearbyProvidersAsync,
    Map<String, ProviderLocationUpdate> liveLocations,
  ) {
    if (locationState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return IndexedStack(
      index: _currentIndex,
      children: [
        // Home tab - map-first marketplace
        _buildMapHome(locationState, nearbyProvidersAsync, liveLocations),
        // Services tab
        _buildServicesTab(),
        // Profile tab
        isAuthenticated
            ? _buildProfileTab()
            : _buildAuthPromptTab(
                icon: Icons.person,
                title: 'Profile',
                description: 'Sign in to manage your profile, view reviews, and more.',
              ),
      ],
    );
  }

  Widget _buildMapHome(
    LocationState locationState,
    AsyncValue<List<NearbyProviderModel>> nearbyProvidersAsync,
    Map<String, ProviderLocationUpdate> liveLocations,
  ) {
    final position = locationState.currentPosition;
    final providers = nearbyProvidersAsync.valueOrNull;

    // Subscribe to live locations once nearby providers load
    if (providers != null && providers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final wsService = ref.read(webSocketServiceProvider);
        wsService.subscribeToNearbyProviders(providers.map((p) => p.id).toList());
      });
    }

    final filteredProviders = _selectedCategory == null
        ? (providers ?? const <NearbyProviderModel>[])
        : (providers ?? const <NearbyProviderModel>[])
            .where((p) => p.category == _selectedCategory)
            .toList();

    return Stack(
      children: [
        // Full-screen map with provider markers
        Positioned.fill(
          child: MapWidget(
            key: _mapKey,
            position: position,
            providers: providers,
            liveLocations: liveLocations,
            selectedProviderId: _selectedProviderId,
            onProviderTap: _onProviderTap,
            onNearMe: _refreshNearby,
            nearMeAlignment: Alignment.topRight,
          ),
        ),

        // Top overlay: search bar + location prompt
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildMapSearchBar(),
              ),
              if (position == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildLocationPrompt(),
                ),
            ],
          ),
        ),

        // Bottom overlay: collapsible browse sheet (category + provider cards)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            // Bound the height: DraggableScrollableSheet needs bounded
            // constraints, and a bare Positioned without top/height gives none.
            height: MediaQuery.sizeOf(context).height,
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.34,
              minChildSize: 0.14,
              maxChildSize: 0.6,
              snap: true,
              snapSizes: const [0.14, 0.34, 0.6],
              builder: (context, scrollController) => ProviderBrowseSheet(
                scrollController: scrollController,
                categories: ServiceCategories.popular,
                selectedCategory: _selectedCategory,
                providers: filteredProviders,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _selectedProviderId = null;
                  });
                },
                onProviderTap: _onProviderCardTap,
                onRequestService: _openProviderDetail,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _refreshNearby() {
    _getLocation();
    ref.invalidate(nearbyProvidersProvider);
  }

  void _onProviderCardTap(NearbyProviderModel provider) {
    setState(() => _selectedProviderId = provider.id);
    _mapKey.currentState?.moveTo(
      LatLng(provider.latitude, provider.longitude),
      16.0,
    );
  }

  void _openProviderDetail(NearbyProviderModel provider) {
    showProviderDetailSheet(
      context,
      provider,
      onRequestService: () {
        _requireAuthThen(context, () {
          context.push(
            '/request-service',
            extra: RequestServiceArgs(
              category: provider.category,
              providerId: provider.id,
              providerName: provider.name,
            ),
          );
        });
      },
    );
  }

  Widget _buildMapSearchBar() {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/search'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Text(
                'Search for plumbing, cleaning, tutoring...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPrompt() {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Enable location to see nearby providers',
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(onPressed: _getLocation, child: const Text('Enable')),
          ],
        ),
      ),
    );
  }

  void _onProviderTap(NearbyProviderModel provider) {
    setState(() => _selectedProviderId = provider.id);
    showProviderDetailSheet(
      context,
      provider,
      onRequestService: () {
        _requireAuthThen(context, () {
          context.push(
            '/request-service',
            extra: RequestServiceArgs(
              category: provider.category,
              providerId: provider.id,
              providerName: provider.name,
            ),
          );
        });
      },
    );
  }

  Widget _buildAuthPromptTab({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Services',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Browse all available services and find what you need.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Services'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage your profile, view reviews, and update settings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.person),
              label: const Text('View Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
