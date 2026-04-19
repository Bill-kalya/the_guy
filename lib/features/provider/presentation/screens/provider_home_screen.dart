import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/availability_toggle.dart';
import '../widgets/incoming_job_card.dart';
import '../../providers/provider_job_provider.dart';
import '../../providers/availability_provider.dart';
import '../../../shared/widgets/loading_widget.dart';

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);
    final availabilityState = ref.watch(availabilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Guy - Provider'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/provider/profile');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Availability toggle
              AvailabilityToggleWidget(),
              
              // Stats cards
              _buildStatsCards(),
              
              const SizedBox(height: 16),
              
              // Active job section
              _buildActiveJobSection(jobState),
              
              const SizedBox(height: 16),
              
              // Today's earnings preview
              _buildEarningsPreview(),
            ],
          ),
          
          // Incoming job popup
          if (jobState.hasIncomingJob && jobState.incomingJob != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IncomingJobCard(
                job: jobState.incomingJob!,
                onAccept: () {
                  ref.read(providerJobProvider.notifier).acceptJob(jobState.incomingJob!.id);
                },
                onDecline: () {
                  ref.read(providerJobProvider.notifier).declineJob(jobState.incomingJob!.id);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text(
                      'Today\'s Earnings',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'KES 0.00',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.work, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Today\'s Jobs',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(height: 8),
                    const Text(
                      'Rating',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '5.0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobSection(ProviderJobState jobState) {
    if (jobState.activeJob == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.work_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No active job',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'ll see incoming job requests here',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.work, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Active Job',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Service: ${jobState.activeJob!.category}'),
            const SizedBox(height: 4),
            Text('Customer: ${jobState.activeJob!.customerName}'),
            const SizedBox(height: 4),
            Text('Status: ${jobState.activeJob!.status}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/provider/active-job');
                },
                child: const Text('View Job Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsPreview() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.green),
        title: const Text('View Earnings'),
        subtitle: const Text('Check your earnings history and statistics'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(context, '/provider/earnings');
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            Navigator.pushNamed(context, '/provider/active-jobs');
            break;
          case 2:
            Navigator.pushNamed(context, '/provider/earnings');
            break;
          case 3:
            Navigator.pushNamed(context, '/provider/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}