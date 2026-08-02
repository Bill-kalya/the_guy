import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/incoming_job_card.dart';
import '../../providers/provider_job_provider.dart';
import '../../providers/provider_profile_provider.dart';
import '../../providers/dashboard_summary_provider.dart';
import '../../providers/availability_provider.dart';
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
      ref.read(dashboardSummaryProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(providerJobProvider);
    final profileState = ref.watch(providerProfileProvider);
    final dashboardState = ref.watch(dashboardSummaryProvider);
    final availabilityState = ref.watch(availabilityProvider);

    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text('Provider Dashboard'),
          actions: [
            if (dashboardState.isRefreshing)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            Tooltip(
              message: availabilityState.isOnline ? 'Tap to go offline' : 'Tap to go online',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: availabilityState.isLoading
                    ? null
                    : () => ref.read(availabilityProvider.notifier).toggleAvailability(),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: availabilityState.isOnline ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: availabilityState.isOnline ? Colors.green.shade200 : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: availabilityState.isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(availabilityState.isOnline ? 'Online' : 'Offline', style: TextStyle(color: availabilityState.isOnline ? Colors.green.shade700 : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
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
            dashboardState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : dashboardState.error != null && dashboardState.summary == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text(dashboardState.error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () => ref.read(dashboardSummaryProvider.notifier).refreshDashboard(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                    onRefresh: () => ref.read(dashboardSummaryProvider.notifier).refreshDashboard(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80),
                      physics: const AlwaysScrollableScrollPhysics(),
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
                          _buildKpiGrid(dashboardState),
                          const SizedBox(height: 20),
                          _buildIncomingJobsSection(jobState),
                          const SizedBox(height: 20),
                          _buildActiveJobAndActions(jobState, dashboardState, availabilityState),
                          const SizedBox(height: 20),
                          _buildEarningsChart(dashboardState),
                        ],
                      ),
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

  Widget _buildCompletionBanner(Map<String, dynamic> completion) {
    final score = ((completion['score'] ?? 0) as num).toInt();
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

  Widget _buildKpiGrid(DashboardSummaryState dashboardState) {
    final d = dashboardState.summary;
    final earningsVal = d != null ? 'KES ${_formatNumber(d.todayEarnings)}' : 'KES 0';
    final earningsSub = d != null ? 'KES ${_formatNumber(d.weekEarnings)} this week' : 'Loading...';
    final jobsVal = d != null ? '${d.todayJobs}' : '0';
    final jobsSub = d != null ? '${d.activeJobs} in progress' : 'No active jobs';
    final ratingVal = d != null && d.totalReviews > 0 ? '${d.averageRating.toStringAsFixed(1)} ★' : 'No ratings';
    final ratingSub = d != null ? '${d.totalReviews} reviews' : 'No reviews yet';
    final responseVal = d != null ? '${d.responseRate.toStringAsFixed(0)}%' : '--';
    final responseSub = d != null ? 'Completion ${d.completionRate.toStringAsFixed(0)}%' : 'Loading...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard('Earnings', earningsVal, Icons.attach_money, Colors.green, earningsSub)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Jobs Today', jobsVal, Icons.work, Colors.blue, jobsSub)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kpiCard('Rating', ratingVal, Icons.star, Colors.amber, ratingSub)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Response', responseVal, Icons.timer, Colors.purple, responseSub)),
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

  Widget _buildIncomingJobsSection(ProviderJobState jobState) {
    if (jobState.incomingJob == null && !jobState.hasIncomingJob) {
      return const SizedBox.shrink();
    }

    final job = jobState.incomingJob!;

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
            Container(
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
                        child: Text(job.customerName.isNotEmpty ? job.customerName[0] : '?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${job.category} \u2022 ${job.distance.toStringAsFixed(1)}km', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Text('KES ${_formatNumber(job.price)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => ref.read(providerJobProvider.notifier).acceptJob(job.id),
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
                          onPressed: () => ref.read(providerJobProvider.notifier).declineJob(job.id),
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
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobAndActions(ProviderJobState jobState, DashboardSummaryState dashboardState, AvailabilityState availabilityState) {
    final d = dashboardState.summary;
    final availableBalance = d?.availableBalance ?? 0;

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
                  onPressed: () => context.push('/provider/active-job'),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.grey.shade200),
            ),
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 14),
            _quickAction(Icons.toggle_on, 'Toggle Availability', availabilityState.isOnline ? 'Go offline' : 'Go online', onTap: () {
              ref.read(availabilityProvider.notifier).toggleAvailability();
            }),
            const SizedBox(height: 12),
            _quickAction(Icons.attach_money, 'Withdraw Earnings', 'KES ${_formatNumber(availableBalance)} available', onTap: () => context.push('/provider/earnings')),
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

  Widget _quickAction(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
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

  Widget _buildEarningsChart(DashboardSummaryState dashboardState) {
    final d = dashboardState.summary;
    final chartData = d?.weeklyChart ?? [];

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxAmount = chartData.map((e) => e.amount).fold<double>(0, (a, b) => a > b ? a : b);

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
                children: List.generate(chartData.length, (i) {
                  final point = chartData[i];
                  final height = maxAmount > 0 ? (point.amount / maxAmount) * 120 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('KES ${(point.amount / 1000).toStringAsFixed(1)}k',
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
                          Text(point.day, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
