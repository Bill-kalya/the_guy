import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/incoming_job_card.dart';
import '../../providers/provider_job_provider.dart';
import '../../providers/provider_profile_provider.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import 'provider_home_screen_desktop.dart';
import '../../../../core/themes/colors.dart';

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerProfileProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);
    final profileState = ref.watch(providerProfileProvider);

    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text('Provider Dashboard'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('Online', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () => context.push('/provider/profile'),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                children: [
                  if (profileState.profileNotFound) ...[
                    const SizedBox(height: 16),
                    _buildCompleteProfileBanner(),
                  ] else if (profileState.profile != null &&
                      profileState.completion != null &&
                      (profileState.completion!['score'] ?? 0) < 100) ...[
                    const SizedBox(height: 16),
                    _buildCompletionBanner(profileState.completion!),
                  ],
                  const SizedBox(height: 16),
                  _buildKpiGrid(),
                  const SizedBox(height: 20),
                  _buildIncomingJobsSection(jobState),
                  const SizedBox(height: 20),
                  _buildActiveJobAndActions(jobState),
                  const SizedBox(height: 20),
                  _buildEarningsChart(),
                  const SizedBox(height: 20),
                  _buildDemandHeatMap(),
                ],
              ),
            ),
            if (jobState.hasIncomingJob && jobState.incomingJob != null)
              Positioned(
                top: 0, left: 0, right: 0,
                child: IncomingJobCard(
                  job: jobState.incomingJob!,
                  onAccept: () => ref.read(providerJobProvider.notifier).acceptJob(jobState.incomingJob!.id),
                  onDecline: () => ref.read(providerJobProvider.notifier).declineJob(jobState.incomingJob!.id),
                ),
              ),
          ],
        ),
      ),
      desktop: ProviderHomeScreenDesktop(),
    );
  }

  // ── Complete Profile Banner (no provider entity) ──────────
  Widget _buildCompleteProfileBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Complete Your Provider Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Set up your service category, portfolio, verification documents, and location to start receiving jobs.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/provider/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Set Up Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Completion Progress Banner ─────────────────────────
  Widget _buildCompletionBanner(Map<String, dynamic> completion) {
    final score = (completion['score'] ?? 0) as int;
    final items = completion['items'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.amber.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile $score% Complete',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100.0,
                backgroundColor: Colors.amber.shade100,
                valueColor: AlwaysStoppedAnimation(Colors.amber.shade600),
                minHeight: 6,
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...items.where((item) => item['completed'] == false).take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.amber.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['label']?.toString() ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.amber.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.push('/provider/register'),
              child: const Text('Complete Profile'),
            ),
          ],
        ),
      ),
    );
  }

  // ── KPI Grid (2×2) ──────────────────────────────────────
  Widget _buildKpiGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard('Earnings', 'KES 24,500', Icons.attach_money, Colors.green, '↑ 12% this week')),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Jobs Today', '18', Icons.work, Colors.blue, '3 in progress')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kpiCard('Rating', '4.9 ★', Icons.star, Colors.amber, '142 reviews')),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Response', '97%', Icons.timer, Colors.purple, 'Avg 2m 30s')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, MaterialColor color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(subtitle, style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  // ── Incoming Jobs ────────────────────────────────────────
  Widget _buildIncomingJobsSection(ProviderJobState jobState) {
    final sampleJobs = [
      ('John Doe', 'Plumbing', '2km', 'KES 2,500'),
      ('Jane Smith', 'Cleaning', '5km', 'KES 3,000'),
      ('Peter Kamau', 'Electrical', '8km', 'KES 4,500'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Incoming Jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              ],
            ),
            const SizedBox(height: 14),
            ...sampleJobs.map((job) => _incomingJobRow(job.$1, job.$2, job.$3, job.$4)),
          ],
        ),
      ),
    );
  }

  Widget _incomingJobRow(String customer, String service, String distance, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(customer[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('$service • $distance', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text(price, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Job + Quick Actions ───────────────────────────
  Widget _buildActiveJobAndActions(ProviderJobState jobState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Job
            const Row(
              children: [
                Icon(Icons.work, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Active Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              ],
            ),
            const SizedBox(height: 14),
            if (jobState.activeJob == null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(Icons.work_off, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text('No active job', style: TextStyle(fontSize: 15, color: Colors.grey)),
                      const SizedBox(height: 4),
                      const Text('Incoming requests will appear here', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              _infoRow('Service', jobState.activeJob!.category),
              const SizedBox(height: 6),
              _infoRow('Customer', jobState.activeJob!.customerName),
              const SizedBox(height: 6),
              _infoRow('Status', jobState.activeJob!.status),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/provider/active-job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Job Details'),
                ),
              ),
            ],
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.grey.shade200),
            ),
            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 14),
            _quickAction(Icons.toggle_on, 'Toggle Availability', 'Go online/offline'),
            const SizedBox(height: 12),
            _quickAction(Icons.map, 'View Service Area', 'See demand around you'),
            const SizedBox(height: 12),
            _quickAction(Icons.attach_money, 'Withdraw Earnings', 'KES 24,500 available'),
          ],
        ),
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
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  // ── Earnings Chart ───────────────────────────────────────
  Widget _buildEarningsChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final amounts = [3200.0, 5800.0, 4100.0, 7200.0, 9500.0, 6800.0, 4500.0];
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('This Week Earnings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (i) {
                  final height = (amounts[i] / maxAmount) * 120;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('KES ${(amounts[i] / 1000).toStringAsFixed(1)}k',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                          const SizedBox(height: 3),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade400, Colors.green.shade600],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(days[i], style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Demand Heat Map ──────────────────────────────────────
  Widget _buildDemandHeatMap() {
    final areas = [
      ('Nairobi CBD', 0.85, Colors.green),
      ('Westlands', 0.65, Colors.green),
      ('Karen', 0.45, Colors.amber),
      ('Roysambu', 0.55, Colors.amber),
      ('Kilimani', 0.75, Colors.green),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, color: Color(0xFF1A1A2E), size: 20),
                SizedBox(width: 8),
                Text('Demand Around You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              ],
            ),
            const SizedBox(height: 16),
            ...areas.map((area) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(area.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                      Text('${(area.$2 * 100).toInt()}%',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: area.$3.shade600)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: area.$2,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(area.$3.shade500),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

}
