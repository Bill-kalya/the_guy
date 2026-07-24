import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/map_widget.dart';
import '../widgets/nearby_providers_list.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_providers_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/presentation/widgets/admin_mode_banner.dart';
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

    if (locationState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(locationState.error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _getLocation, child: const Text('Retry')),
          ],
        ),
      );
    }

    return IndexedStack(
      index: _currentIndex,
      children: [
        // Home tab - Marketplace landing
        _buildMarketplaceHome(locationState, isAuthenticated, nearbyProvidersAsync, liveLocations),
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

  Widget _buildMarketplaceHome(
    LocationState locationState,
    bool isAuthenticated,
    AsyncValue<List<NearbyProviderModel>> nearbyProvidersAsync,
    Map<String, ProviderLocationUpdate> liveLocations,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section with search
          _buildHeroSection(),
          // Urgent help banner
          _buildUrgentHelpBanner(),
          // What service do you need?
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'What service do you need?',
              style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold),
            ),
          ),

          // Nearby providers with map and live tracking
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Nearby Providers',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Map with provider markers
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MapWidget(
                        position: locationState.currentPosition,
                        providers: nearbyProvidersAsync.valueOrNull,
                        liveLocations: liveLocations,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nearby providers list
                  nearbyProvidersAsync.when(
                    data: (providers) {
                      // Subscribe to live locations for nearby providers
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (providers.isNotEmpty) {
                          final wsService = ref.read(webSocketServiceProvider);
                          wsService.subscribeToNearbyProviders(
                            providers.map((p) => p.id).toList(),
                          );
                        }
                      });

                      return SizedBox(
                        height: 400,
                        child: NearbyProvidersList(
                          position: locationState.currentPosition,
                          providers: providers,
                          isLoading: false,
                        ),
                      );
                    },
                    loading: () => SizedBox(
                      height: 200,
                      child: NearbyProvidersList(
                        position: locationState.currentPosition,
                        isLoading: true,
                      ),
                    ),
                    error: (error, stack) => SizedBox(
                      height: 200,
                      child: NearbyProvidersList(
                        position: locationState.currentPosition,
                        error: error.toString(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Become a Provider CTA
          _buildBecomeProviderSection(isAuthenticated),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient.colors.toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
      ),
      child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final titleSize = constraints.maxWidth < 600 ? 32.0 : 48.0;
                        return Text(
                          'The Guy',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Connect with verified professionals for home, business, and personal services anywhere in Kenya.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Fast • Trusted • Nearby',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Search for plumbing, cleaning, tutoring...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category icons as horizontal scrollable list below search
                        SizedBox(
                          height: 72,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: ServiceCategories.popular.map((cat) {
                              return _buildSearchCategoryChip(cat.icon, cat.name);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: _getGuyButton(),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _getGuyButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _requireAuthThen(context, () {
          context.push('/request-service');
        });
      },
      icon: const Icon(Icons.person_search),
      label: const Text('Get a Guy'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildSearchCategoryChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, color: Colors.white, size: 18),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        onPressed: () {},
      ),
    );
  }


  Widget _buildBecomeProviderSection(bool isAuthenticated) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Become a Provider',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Earn money on your own schedule. Join thousands of providers on The Guy.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _requireAuthThen(context, () {
                    context.push('/provider/register');
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildUrgentHelpBanner() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade100, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.amber.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.orange.shade800,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Need help urgently? Get matched with nearby professionals instantly.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
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