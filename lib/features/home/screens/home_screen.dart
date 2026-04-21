import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/map_widget.dart';
import '../widgets/nearby_providers_list.dart';
import '../providers/location_provider.dart';
import '../../jobs/screens/request_service_screen.dart';

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
    _getLocation();
  }

  void _getLocation() async {
    await ref.read(locationProvider.notifier).getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      body: _buildBody(locationState),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestServiceScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Request Service'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildBody(LocationState locationState) {
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
        // Home tab
        Column(
          children: [
            Expanded(
              flex: 2,
              child: MapWidget(position: locationState.currentPosition),
            ),
            Expanded(
              flex: 1,
              child: NearbyProvidersList(
                position: locationState.currentPosition,
              ),
            ),
          ],
        ),
        // Jobs tab
        const Center(child: Text('My Jobs - Coming Soon')),
        // Profile tab
        const Center(child: Text('Profile - Coming Soon')),
      ],
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
