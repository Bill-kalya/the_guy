import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/map_widget.dart';
import '../widgets/nearby_providers_list.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_providers_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/websocket_service.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../shared/constants/service_categories.dart';
import '../widgets/download_app_section.dart';
class HomeScreenDesktop extends ConsumerStatefulWidget {
  const HomeScreenDesktop({super.key});

  @override
  ConsumerState<HomeScreenDesktop> createState() => _HomeScreenDesktopState();
}

class _HomeScreenDesktopState extends ConsumerState<HomeScreenDesktop> {
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
    final nearbyProvidersAsync = ref.watch(nearbyProvidersProvider);
    final liveLocations = ref.watch(providerLocationsProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildTopNavBar(isAuthenticated),
          Expanded(
            child: _buildBody(
              locationState,
              isAuthenticated,
              nearbyProvidersAsync,
              liveLocations,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavBar(bool isAuthenticated) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.transparent,
                      ),
                      child: Image.asset('assets/icons/icon (2).png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'The Guy',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 48),
                // Nav Links
          Expanded(
            child: Row(
              children: [
                _navLink('Home', true, () {}),
                const SizedBox(width: 24),
                _navLink('Services', false, () => context.push('/search')),
                const SizedBox(width: 24),
                _navLink('How It Works', false, () {
                  // Scroll to the How It Works section
                }),
                const SizedBox(width: 24),
                _navLink('Become a Provider', false, () {
                  _requireAuthThen(context, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening provider registration...')),
                    );
                  });
                }),
              ],
            ),
          ),
                // Search
                SizedBox(
                  width: 240,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Auth buttons or profile
                if (isAuthenticated)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifications coming soon')),
                          );
                        },
                        tooltip: 'Notifications',
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.push('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, bool isActive, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.blue.shade700 : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          fontSize: 15,
        ),
      ),
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

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(),
          _buildUrgentHelpBanner(),
          _buildStatsSection(),
          _buildServiceCategories(),
          _buildHowItWorks(),
          _buildNearbySection(
            locationState,
            nearbyProvidersAsync,
            liveLocations,
          ),
          _buildBecomeProviderSection(isAuthenticated),
          const DownloadAppSection(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700, Colors.blue.shade500],
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
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Trusted\nService Providers\nNear You',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Connect with verified professionals for home, business, and personal services anywhere in Kenya.',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade300, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Verified professionals',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                          ),
                          const SizedBox(width: 24),
                          Icon(Icons.check_circle, color: Colors.green.shade300, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Real-time tracking',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                          ),
                          const SizedBox(width: 24),
                          Icon(Icons.check_circle, color: Colors.green.shade300, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Secure payments',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'What service do you need?',
                                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                color: Colors.grey.shade200,
                              ),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Location',
                                    prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                color: Colors.grey.shade200,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _requireAuthThen(context, () {
                                      context.push('/request-service');
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Get a Guy',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Category chips
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ServiceCategories.popular.map((cat) {
                          return _heroCategoryChip(cat.icon, cat.name);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // Hero illustration area
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '500+ Providers Available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '24/7 Service • Nairobi • Mombasa • Kisumu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Padding(
                              padding: EdgeInsets.only(left: i > 0 ? -8 : 0),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue.shade300,
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join 10,000+ satisfied customers',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCategoryChip(IconData icon, String label) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      onPressed: () => context.push('/search'),
    );
  }

  Widget _buildUrgentHelpBanner() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade100, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange.shade800, size: 36),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Need help urgently? Get matched with nearby professionals instantly.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _requireAuthThen(context, () {
                    context.push('/request-service');
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Get Help Now', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              _statCard(Icons.people, '500+', 'Providers', Colors.blue),
              _statCard(Icons.work, '10K+', 'Jobs Done', Colors.green),
              _statCard(Icons.star, '4.8', 'Avg Rating', Colors.amber),
              _statCard(Icons.timer, '< 5 min', 'Avg Response', Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color.shade600),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular Services',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find what you need from our trusted professionals',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: ServiceCategories.featured.map((cat) {
                  return Expanded(
                    child: _serviceCategoryCard(cat.name, cat.icon, cat.color),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCategoryCard(String label, IconData icon, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From KES 500',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: Column(
              children: [
                Text(
                  'How It Works',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get help in three simple steps',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    _stepCard(
                      '1',
                      'Request a Service',
                      'Tell us what you need and when. Our smart matching finds the best provider for you.',
                      Icons.edit_note,
                      Colors.blue,
                    ),
                    _stepCard(
                      '2',
                      'Get Matched',
                      'Receive offers from verified providers near you. Compare ratings, prices, and availability.',
                      Icons.people_alt,
                      Colors.green,
                    ),
                    _stepCard(
                      '3',
                      'Job Done',
                      'Track your service in real-time, pay securely, and rate your experience.',
                      Icons.celebration,
                      Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepCard(String step, String title, String description, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.shade600,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Icon(icon, size: 40, color: color.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySection(
    LocationState locationState,
    AsyncValue<List<NearbyProviderModel>> nearbyProvidersAsync,
    Map<String, ProviderLocationUpdate> liveLocations,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Providers',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Professionals available near your location',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/search'),
                    icon: const Text('View All'),
                    label: const Icon(Icons.arrow_forward, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 480,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: MapWidget(
                          position: locationState.currentPosition,
                          providers: nearbyProvidersAsync.valueOrNull,
                          liveLocations: liveLocations,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 7,
                    child: nearbyProvidersAsync.when(
                      data: (providers) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (providers.isNotEmpty) {
                            final wsService = ref.read(webSocketServiceProvider);
                            wsService.subscribeToNearbyProviders(
                              providers.map((p) => p.id).toList(),
                            );
                          }
                        });

                        return SizedBox(
                          height: 480,
                          child: NearbyProvidersList(
                            position: locationState.currentPosition,
                            providers: providers,
                            isLoading: false,
                          ),
                        );
                      },
                      loading: () => SizedBox(
                        height: 480,
                        child: NearbyProvidersList(
                          position: locationState.currentPosition,
                          isLoading: true,
                        ),
                      ),
                      error: (error, stack) => SizedBox(
                        height: 480,
                        child: NearbyProvidersList(
                          position: locationState.currentPosition,
                          error: error.toString(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBecomeProviderSection(bool isAuthenticated) {
    return Container(
      width: double.infinity,
      color: Colors.green.shade50,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Become a Provider',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Earn money on your own schedule. Join thousands of trusted providers on The Guy and start receiving job offers today.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Set your own rates', style: TextStyle(color: Colors.green.shade700, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Work when you want', style: TextStyle(color: Colors.green.shade700, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.check, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Get paid instantly', style: TextStyle(color: Colors.green.shade700, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          _requireAuthThen(context, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening provider registration...')),
                            );
                          });
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Get Started Today'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.green.shade100,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_history, size: 64, color: Colors.green.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Join 500+ Active Providers',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Average earnings: KES 45,000/month',
                          style: TextStyle(fontSize: 15, color: Colors.green.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/icons/icon (2).png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'The Guy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting you with verified professionals for home, business, and personal services.',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    _footerColumn('Company', ['About Us', 'Careers', 'Blog', 'Press']),
                    const SizedBox(width: 48),
                    _footerColumn('Services', [...ServiceCategories.popular.map((c) => c.name), 'All Services']),
                    const SizedBox(width: 48),
                    _footerColumn('Support', ['Help Center', 'Safety', 'Terms of Service', 'Privacy Policy']),
                  ],
                ),
                const SizedBox(height: 40),
                Divider(color: Colors.grey.shade800),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© 2024 The Guy. All rights reserved.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.facebook, color: Colors.grey.shade400, size: 22),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade400, size: 22),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.alternate_email, color: Colors.grey.shade400, size: 22),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerColumn(String title, List<String> items) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  item,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              )),
        ],
      ),
    );
  }
}