import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/map_widget.dart';
import '../widgets/provider_detail_sheet.dart';
import '../widgets/nearby_providers_list.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_providers_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/auth_state.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/location_utils.dart';
import '../../../shared/models/nearby_provider_model.dart';
import '../../../core/themes/colors.dart';
import '../../../shared/constants/service_categories.dart';
import '../../../shared/constants/kenya_towns.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../widgets/download_app_section.dart';
import '../providers/platform_stats_provider.dart';
import '../../jobs/screens/request_service_screen.dart';
class HomeScreenDesktop extends ConsumerStatefulWidget {
  const HomeScreenDesktop({super.key});

  @override
  ConsumerState<HomeScreenDesktop> createState() => _HomeScreenDesktopState();
}

class _HomeScreenDesktopState extends ConsumerState<HomeScreenDesktop> {
  final _topNavSearchController = TextEditingController();
  final _heroSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocation();
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _topNavSearchController.dispose();
    _heroSearchController.dispose();
    super.dispose();
  }

  void _goToSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    context.push('/search?q=${Uri.encodeComponent(query)}');
  }

  void _getLocation() async {
    // The landing page is public; don't prompt anonymous visitors for GPS
    // on page load, and don't fire geolocation while a dead session is being
    // torn down.
    if (!ref.read(authProvider).isAuthenticated) return;
    await _requestLocation();
  }

  /// Explicit user action ("Enable" / "Try again" / "Near me"): always fires,
  /// even for anonymous visitors who tapped the button themselves.
  Future<void> _enableLocation() => _requestLocation();

  Future<void> _requestLocation() =>
      ref.read(locationProvider.notifier).getCurrentLocation();

  Future<void> _openLocationSettings() async {
    final opened = await LocationUtils.openLocationSettings();
    if (!opened) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable location'),
          content: const Text(
            'Click the lock or site-settings icon in your browser address bar, '
            'allow location access for this site, then try again.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _enableLocation();
              },
              child: const Text('Retry'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        ),
      );
      return;
    }
    _enableLocation();
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

  void _refreshNearby() {
    _enableLocation();
    ref.invalidate(nearbyProvidersProvider);
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
          _buildTopNavBar(authState, isAuthenticated),
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

  Widget _buildTopNavBar(AuthState authState, bool isAuthenticated) {
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                return Row(
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
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
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
                                context.push('/provider/register');
                              });
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    // Search
                    SizedBox(
                      width: compact ? 160 : 240,
                      height: 40,
                      child: TextField(
                        controller: _topNavSearchController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search services...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
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
                          fillColor: Colors.white,
                        ),
                        onSubmitted: _goToSearch,
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
                          InkWell(
                            onTap: () => context.push('/profile'),
                            borderRadius: BorderRadius.circular(18),
                            child: UserAvatar(
                              imageUrl: authState.user?.avatar,
                              name: authState.user?.name ?? 'User',
                              radius: 18,
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
                              backgroundColor: AppColors.primary,
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
                );
              },
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
        foregroundColor: isActive ? AppColors.primary : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                locationState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: locationState.permissionBlocked ? _openLocationSettings : _enableLocation,
                    icon: Icon(locationState.permissionBlocked ? Icons.settings : Icons.gps_fixed),
                    label: Text(locationState.permissionBlocked ? 'Open Settings' : 'Try Again'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _chooseTownManually,
                    icon: const Icon(Icons.location_city),
                    label: const Text('Choose Location Manually'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (locationState.notice != null) _buildLocationNotice(locationState.notice!),
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

  Widget _buildLocationNotice(String notice) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              notice,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  void _chooseTownManually() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose your location'),
        content: SizedBox(
          width: 360,
          height: 420,
          child: ListView.builder(
            itemCount: kenyaTowns.length,
            itemBuilder: (context, i) {
              final town = kenyaTowns[i];
              return ListTile(
                leading: const Icon(Icons.location_city, color: Colors.grey),
                title: Text(town.name),
                subtitle: Text(town.county),
                onTap: () {
                  ref.read(locationProvider.notifier).selectTown(town);
                  ref.invalidate(nearbyProvidersProvider);
                  Navigator.pop(dialogContext);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final platformStats = ref.watch(platformStatsProvider).valueOrNull ?? {};
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1000;
                final illustration = _heroIllustration(platformStats);
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroLeftColumn(compact: true),
                          const SizedBox(height: 48),
                          SizedBox(width: double.infinity, child: illustration),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _heroLeftColumn(compact: false),
                          ),
                          const SizedBox(width: 48),
                          Expanded(flex: 4, child: illustration),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroLeftColumn({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Trusted\nService Providers\nNear You',
          style: TextStyle(
            fontSize: compact ? 36 : 52,
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
            fontSize: compact ? 17 : 20,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            _heroCheck('Verified professionals'),
            _heroCheck('Real-time tracking'),
            _heroCheck('Secure payments'),
          ],
        ),
        const SizedBox(height: 36),
        _heroSearchBar(),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ServiceCategories.popular.map((cat) {
            return _heroCategoryChip(cat.icon, cat.name);
          }).toList(),
        ),
      ],
    );
  }

  Widget _heroCheck(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade300, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
        ),
      ],
    );
  }

  Widget _heroSearchBar() {
    final searchField = _heroSearchField(
      hintText: 'What service do you need?',
      prefixIcon: Icons.search,
      controller: _heroSearchController,
      onSubmitted: _goToSearch,
    );
    final locationField = _heroSearchField(
      hintText: 'Location',
      prefixIcon: Icons.location_on_outlined,
    );
    return Container(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 680;
          final button = _heroGetAGuyButton(expand: stacked);
          if (stacked) {
            return Column(
              children: [
                searchField,
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                locationField,
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                button,
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                Expanded(flex: 3, child: searchField),
                Container(width: 1, color: Colors.grey.shade200),
                Expanded(flex: 2, child: locationField),
                Container(width: 1, color: Colors.grey.shade200),
                button,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _heroSearchField({
    required String hintText,
    required IconData prefixIcon,
    TextEditingController? controller,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }

  Widget _heroGetAGuyButton({bool expand = false}) {
    final button = ElevatedButton(
      onPressed: () {
        _requireAuthThen(context, () {
          context.push('/request-service');
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
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
    );
    return Padding(
      padding: const EdgeInsets.all(8),
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }

  Widget _heroIllustration(Map<String, dynamic> platformStats) {
    return Container(
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
            '${platformStats['totalProviders'] ?? 0}+ Providers Available',
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Join ${platformStats['totalUsers'] ?? 0}+ users on The Guy',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCategoryChip(IconData icon, String label) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      onPressed: () => context.push('/search?q=${Uri.encodeComponent(label)}'),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final text = Text(
                'Need help urgently? Get matched with nearby professionals instantly.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
              );
              final button = ElevatedButton(
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
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.orange.shade800, size: 36),
                        const SizedBox(width: 12),
                        Expanded(child: text),
                      ],
                    ),
                    const SizedBox(height: 16),
                    button,
                  ],
                );
              }
              return Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.orange.shade800, size: 36),
                  const SizedBox(width: 16),
                  Expanded(child: text),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final platformStats = ref.watch(platformStatsProvider).valueOrNull ?? {};
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = ((constraints.maxWidth - 3 * 16) / 4).clamp(220.0, double.infinity);
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _statCard(Icons.people, '${platformStats['totalProviders'] ?? 0}+', 'Providers', Colors.blue, cardWidth),
                  _statCard(Icons.work, _fmtCount(platformStats['totalJobs'] ?? 0), 'Jobs Done', Colors.green, cardWidth),
                  _statCard(Icons.star, '${platformStats['totalReviews'] ?? 0}', 'Reviews', Colors.amber, cardWidth),
                  _statCard(Icons.timer, '${platformStats['totalUsers'] ?? 0}+', 'Users', Colors.purple, cardWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _fmtCount(dynamic v) {
    final n = v is num ? v.toInt() : 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _statCard(IconData icon, String value, String label, MaterialColor color, double width) {
    return SizedBox(
      width: width,
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
    return ColoredBox(
      color: Colors.white,
      child: Center(
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final n = ServiceCategories.featured.length;
                    final cardWidth = ((constraints.maxWidth - (n - 1) * 16) / 4).clamp(180.0, 380.0);
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: ServiceCategories.featured.map((cat) {
                        return SizedBox(
                          width: cardWidth,
                          child: _serviceCategoryCard(cat.name, cat.icon, cat.color),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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
    return ColoredBox(
      color: Colors.white,
      child: Center(
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
                          onProviderTap: _openProviderDetail,
                          onNearMe: _refreshNearby,
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
                            onEnableLocation: locationState.permissionBlocked
                                ? _openLocationSettings
                                : _enableLocation,
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
                          // While waiting for a fresh GPS fix, show loading
                          // instead of an error flash.
                          isLoading: error.toString().contains('Waiting for GPS fix'),
                          error: error.toString().contains('Waiting for GPS fix')
                              ? null
                              : error.toString(),
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
      ),
    );
  }

  Widget _buildBecomeProviderSection(bool isAuthenticated) {
    final platformStats = ref.watch(platformStatsProvider).valueOrNull ?? {};
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
                            context.push('/provider/register');
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
                          'Join ${platformStats['totalProviders'] ?? 0}+ Active Providers',
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
                                  color: AppColors.primary,
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