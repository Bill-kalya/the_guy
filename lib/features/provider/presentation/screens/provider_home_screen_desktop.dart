import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/availability_toggle.dart';
import '../widgets/incoming_job_card.dart';
import '../../providers/provider_job_provider.dart';
import '../../providers/dashboard_summary_provider.dart';
import '../../../../core/themes/colors.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/providers/auth_provider.dart';

class ProviderHomeScreenDesktop extends ConsumerStatefulWidget {
  const ProviderHomeScreenDesktop({super.key});

  @override
  ConsumerState<ProviderHomeScreenDesktop> createState() => _ProviderHomeScreenDesktopState();
}

class _ProviderHomeScreenDesktopState extends ConsumerState<ProviderHomeScreenDesktop> {
  String _currentRoute = 'dashboard';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardSummaryProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);
    final dashboardState = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: dashboardState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          color: Colors.grey.shade50,
                          child: RefreshIndicator(
                            onRefresh: () => ref.read(dashboardSummaryProvider.notifier).refreshDashboard(),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildKpiRow(dashboardState),
                                  const SizedBox(height: 24),
                                  _buildActiveJobSection(jobState, dashboardState),
                                  const SizedBox(height: 24),
                                  _buildEarningsChart(dashboardState),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
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
            Builder(
              builder: (context) {
                final user = ref.watch(authProvider).user;
                return UserAvatar(
                  imageUrl: user?.avatar,
                  name: user?.name ?? 'Provider',
                  radius: 18,
                  onTap: () => context.push('/provider/profile'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(DashboardSummaryState dashboardState) {
    final d = dashboardState.summary;
    final earningsVal = d != null ? 'KES ${_formatNumber(d.todayEarnings)}' : 'KES 0';
    final earningsSub = d != null ? 'KES ${_formatNumber(d.weekEarnings)} this week' : 'Loading...';
    final jobsVal = d != null ? '${d.todayJobs}' : '0';
    final jobsSub = d != null ? '${d.activeJobs} in progress' : 'No active jobs';
    final ratingVal = d != null && d.totalReviews > 0 ? '${d.averageRating.toStringAsFixed(1)} \u2605' : 'No ratings';
    final ratingSub = d != null ? 'Based on ${d.totalReviews} reviews' : 'No reviews yet';
    final responseVal = d != null ? '${d.responseRate.toStringAsFixed(0)}%' : '--';
    final responseSub = d != null ? 'Completion ${d.completionRate.toStringAsFixed(0)}%' : 'Loading...';

    return Row(
      children: [
        _kpiCard('Earnings', earningsVal, Icons.attach_money, Colors.green, earningsSub),
        _kpiCard('Jobs Today', jobsVal, Icons.work, Colors.blue, jobsSub),
        _kpiCard('Rating', ratingVal, Icons.star, Colors.amber, ratingSub),
        _kpiCard('Response', responseVal, Icons.timer, Colors.purple, responseSub),
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

  Widget _buildActiveJobSection(ProviderJobState jobState, DashboardSummaryState dashboardState) {
    final d = dashboardState.summary;
    final availableBalance = d?.availableBalance ?? 0;

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
                    onPressed: () => context.push('/provider/active-job'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
                _quickAction(Icons.attach_money, 'Withdraw Earnings', 'KES ${_formatNumber(availableBalance)} available'),
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
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.primary),
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

  Widget _buildEarningsChart(DashboardSummaryState dashboardState) {
    final d = dashboardState.summary;
    final chartData = d?.weeklyChart ?? [];

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxAmount = chartData.map((e) => e.amount).fold<double>(0, (a, b) => a > b ? a : b);

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
              children: List.generate(chartData.length, (i) {
                final point = chartData[i];
                final height = maxAmount > 0 ? (point.amount / maxAmount) * 160 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('KES ${point.amount.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(point.day, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
