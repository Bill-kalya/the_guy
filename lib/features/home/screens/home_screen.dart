import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/map_widget.dart';
import '../widgets/nearby_providers_list.dart';
import '../providers/location_provider.dart';
import '../../auth/providers/auth_provider.dart';

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
    });
  }

  void _getLocation() async {
    await ref.read(locationProvider.notifier).getCurrentLocation();
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

    return Scaffold(
      body: _buildBody(locationState, isAuthenticated),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: isAuthenticated && _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/request-service'),
              icon: const Icon(Icons.add),
              label: const Text('Request Service'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildBody(LocationState locationState, bool isAuthenticated) {
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
        _buildMarketplaceHome(locationState, isAuthenticated),
        // Jobs tab
        isAuthenticated
            ? const Center(child: Text('My Jobs - Coming Soon'))
            : _buildAuthPromptTab(
                icon: Icons.history,
                title: 'My Jobs',
                description: 'Sign in to view your job history and track active services.',
              ),
        // Profile tab
        isAuthenticated
            ? const Center(child: Text('Profile - Coming Soon'))
            : _buildAuthPromptTab(
                icon: Icons.person,
                title: 'Profile',
                description: 'Sign in to manage your profile, view reviews, and more.',
              ),
      ],
    );
  }

  Widget _buildMarketplaceHome(LocationState locationState, bool isAuthenticated) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section with search
          _buildHeroSection(),
          // Categories
          _buildCategoriesSection(),
          // How It Works
          _buildHowItWorksSection(),
          // Featured Providers
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Featured Service Providers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildFeaturedProviderCard(index, isAuthenticated),
                ),
              ),
            ],
          ),
          // Nearby providers
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Nearby Providers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 120,
            child: MapWidget(position: locationState.currentPosition),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 180,
              child: NearbyProvidersList(
                position: locationState.currentPosition,
              ),
            ),
          ),
          // Testimonials
          _buildTestimonialsSection(),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'The Guy',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Any service. Any time. Right at your doorstep.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for a service...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildSearchChip('Plumbing'),
              _buildSearchChip('Electrician'),
              _buildSearchChip('Cleaning'),
              _buildSearchChip('Tutoring'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.white.withOpacity(0.2),
      onPressed: () {},
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'icon': Icons.plumbing, 'name': 'Plumbing'},
      {'icon': Icons.electrical_services, 'name': 'Electrical'},
      {'icon': Icons.cleaning_services, 'name': 'Cleaning'},
      {'icon': Icons.school, 'name': 'Tutoring'},
      {'icon': Icons.build, 'name': 'Handyman'},
      {'icon': Icons.local_shipping, 'name': 'Moving'},
      {'icon': Icons.pets, 'name': 'Pet Care'},
      {'icon': Icons.health_and_safety, 'name': 'Health'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Category',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(categories[index]['icon'] as IconData,
                          size: 32, color: Colors.blue.shade600),
                      const SizedBox(height: 8),
                      Text(
                        categories[index]['name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    final List<Map<String, dynamic>> steps = [
      {'step': '1', 'title': 'Describe', 'desc': 'Tell us what service you need', 'icon': Icons.edit_note},
      {'step': '2', 'title': 'Match', 'desc': 'Get matched with top providers', 'icon': Icons.people_alt},
      {'step': '3', 'title': 'Book', 'desc': 'Choose your provider & book', 'icon': Icons.calendar_month},
      {'step': '4', 'title': 'Done', 'desc': 'Service completed at your doorstep', 'icon': Icons.check_circle},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How It Works',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: steps.map((step) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          step['step']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['desc']!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProviderCard(int index, bool isAuthenticated) {
    final List<Map<String, dynamic>> providers = [
      {'name': 'John M.', 'profession': 'Plumber', 'rating': '4.9', 'price': 'KSH 1,500/hr'},
      {'name': 'Sarah K.', 'profession': 'Electrician', 'rating': '4.8', 'price': 'KSH 2,000/hr'},
      {'name': 'Peter O.', 'profession': 'Cleaner', 'rating': '4.7', 'price': 'KSH 800/hr'},
      {'name': 'Grace W.', 'profession': 'Tutor', 'rating': '4.9', 'price': 'KSH 1,200/hr'},
      {'name': 'James N.', 'profession': 'Handyman', 'rating': '4.6', 'price': 'KSH 1,000/hr'},
    ];

    final provider = providers[index];
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      provider['name']!.split(' ').first[0],
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          provider['profession']!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(provider['rating']!),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                provider['price']!,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _requireAuthThen(context, () {
                      // Navigate to provider booking
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking service...')),
                      );
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Hire Now', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What Our Users Say',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTestimonialCard(
                  '⭐️⭐️⭐️⭐️⭐️',
                  '"Fixed my leaking pipes in 30 mins. Amazing service!"',
                  '- James K.',
                ),
                _buildTestimonialCard(
                  '⭐️⭐️⭐️⭐️⭐️',
                  '"Found a great tutor for my kids. Very professional."',
                  '- Mary W.',
                ),
                _buildTestimonialCard(
                  '⭐️⭐️⭐️⭐️',
                  '"Electrician arrived on time and did excellent work."',
                  '- David O.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String stars, String text, String author) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stars),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Text(author, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBecomeProviderSection(bool isAuthenticated) {
    return Container(
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
                // Navigate to provider registration
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening provider registration...')),
                );
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

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}