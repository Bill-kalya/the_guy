import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/availability_toggle.dart';
import '../widgets/incoming_job_card.dart';
import '../../providers/provider_job_provider.dart';

class ProviderHomeScreenDesktop extends ConsumerStatefulWidget {
  const ProviderHomeScreenDesktop({super.key});

  @override
  ConsumerState<ProviderHomeScreenDesktop> createState() => _ProviderHomeScreenDesktopState();
}

class _ProviderHomeScreenDesktopState extends ConsumerState<ProviderHomeScreenDesktop> {
  String _currentRoute = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildKpiRow(),
                          const SizedBox(height: 24),
                          _buildIncomingJobs(jobState),
                          const SizedBox(height: 24),
                          _buildActiveJobSection(jobState),
                          const SizedBox(height: 24),
                          _buildEarningsChart(),
                          const SizedBox(height: 24),
                          _buildDemandHeatMap(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Incoming job overlay
          if (jobState.hasIncomingJob && jobState.incomingJob != null)
            Positioned(
              top: 80,
              right: 24,
              child: IncomingJobCard(
                job: jobState.incomingJob!,
                onAccept: () => ref.read(providerJobProvider.notifier).acceptJob(jobState.incomingJob!.id),
                onDecline: () => ref.read(providerJobProvider.notifier).declineJob(jobState.incomingJob!.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final menuItems = [
      ('dashboard', 'Dashboard', Icons.dashboard),
      ('jobs', 'Jobs', Icons.work),
      ('earnings', 'Earnings', Icons.attach_money),
      ('reviews', 'Reviews', Icons.star),
      ('profile', 'Profile', Icons.person),
      ('settings', 'Settings', Icons.settings),
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(2, 0))],
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.transparent),
                  child: Image.asset('assets/icons/icon (2).png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                const Text('Provider', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: menuItems.map((item) {
                final isActive = item.$1 == _currentRoute;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _currentRoute = item.$1);
                        if (item.$1 == 'profile') {
                          context.push('/provider/profile');
                        } else if (item.$1 == 'jobs') {
                          context.push('/provider/active-job');
                        } else if (item.$1 == 'earnings') {
                          context.push('/provider/earnings');
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(item.$3, size: 20, color: isActive ? Colors.white : Colors.grey.shade400),
                            const SizedBox(width: 12),
                            Text(item.$2, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade400, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const AvailabilityToggleWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Text('Provider Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Online', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            CircleAvatar(radius: 18, backgroundColor: Colors.blue.shade100, child: const Text('P', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        _kpiCard('Earnings', 'KES 24,500', Icons.attach_money, Colors.green, '↑ 12% this week'),
        _kpiCard('Jobs Today', '18', Icons.work, Colors.blue, '3 in progress'),
        _kpiCard('Rating', '4.9 ★', Icons.star, Colors.amber, 'Based on 142 reviews'),
        _kpiCard('Response', '97%', Icons.timer, Colors.purple, 'Avg 2m 30s'),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, MaterialColor color, String subtitle) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 20, color: color.shade600),
                ),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(subtitle, style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingJobs(ProviderJobState jobState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange, size: 22),
              SizedBox(width: 8),
              Text('Incoming Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 16),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Service', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 1, child: Text('Distance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 1, child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
              ],
            ),
          ),
          // Sample rows
          ...List.generate(3, (i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              children: [
                Expanded(flex: 2, child: Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: Colors.blue.shade100, child: Text('J${i+1}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12))),
                    const SizedBox(width: 8),
                    const Text('John Doe', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  ],
                )),
                Expanded(flex: 2, child: Text('Plumbing', style: TextStyle(fontSize: 14, color: Colors.grey.shade700))),
                Expanded(flex: 1, child: Text('${2 + i * 3}km', style: TextStyle(fontSize: 14, color: Colors.grey.shade700))),
                Expanded(flex: 1, child: Text('KES ${2500 + i * 500}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.green.shade700))),
                Expanded(flex: 2, child: Row(
                  children: [
                    _tableButton('Accept', Colors.green),
                    const SizedBox(width: 8),
                    _tableButton('Decline', Colors.red),
                  ],
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _tableButton(String label, MaterialColor color) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: color.shade50,
        foregroundColor: color.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActiveJobSection(ProviderJobState jobState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.work, color: Colors.green, size: 22),
                    SizedBox(width: 8),
                    Text('Active Job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  ],
                ),
                const SizedBox(height: 16),
                if (jobState.activeJob == null) ...[
                  Icon(Icons.work_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No active job', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Text('You\'ll see incoming job requests here', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ] else ...[
                  _infoRow('Service', jobState.activeJob!.category),
                  const SizedBox(height: 8),
                  _infoRow('Customer', jobState.activeJob!.customerName),
                  const SizedBox(height: 8),
                  _infoRow('Status', jobState.activeJob!.status),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('View Job Details'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 1, height: 120, color: Colors.grey.shade200,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 16),
                _quickAction(Icons.toggle_on, 'Toggle Availability', 'Go online/offline'),
                const SizedBox(height: 12),
                _quickAction(Icons.map, 'View Service Area', 'See demand around you'),
                const SizedBox(height: 12),
                _quickAction(Icons.attach_money, 'Withdraw Earnings', 'KES 24,500 available'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      ],
    );
  }

  Widget _quickAction(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final amounts = [3200.0, 5800.0, 4100.0, 7200.0, 9500.0, 6800.0, 4500.0];
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: 22),
              SizedBox(width: 8),
              Text('This Week Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final height = (amounts[i] / maxAmount) * 160;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('KES ${amounts[i].toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(days[i], style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandHeatMap() {
    final areas = [
      ('Nairobi CBD', 0.85, Colors.green),
      ('Westlands', 0.65, Colors.green),
      ('Karen', 0.45, Colors.amber),
      ('Roysambu', 0.55, Colors.amber),
      ('Kilimani', 0.75, Colors.green),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map, color: Color(0xFF1A1A2E), size: 22),
              SizedBox(width: 8),
              Text('Demand Around You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 20),
          ...areas.map((area) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(area.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                    Text('${(area.$2 * 100).toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: area.$3.shade600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: area.$2,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(area.$3.shade500),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}