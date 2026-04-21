import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/earnings_chart.dart';
import '../../providers/earnings_provider.dart';
import '../../models/earnings_model.dart';
import '../../../../shared/widgets/loading_widget.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsProvider.notifier).fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(earningsProvider.notifier).refreshEarnings();
            },
          ),
        ],
      ),
      body: earningsState.isLoading
          ? const LoadingWidget()
          : earningsState.error != null
          ? _buildErrorWidget(earningsState.error!)
          : earningsState.earnings != null
          ? _buildEarningsContent(earningsState.earnings!)
          : const SizedBox(),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(earningsProvider.notifier).refreshEarnings();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsContent(EarningsModel earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total earnings card
          _buildTotalEarningsCard(earnings),
          const SizedBox(height: 16),

          // Stats grid
          _buildStatsGrid(earnings),
          const SizedBox(height: 24),

          // Earnings chart
          EarningsChartWidget(weeklyEarnings: earnings.weeklyEarnings),
          const SizedBox(height: 24),

          // Recent transactions
          _buildRecentTransactions(earnings),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard(EarningsModel earnings) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.greenAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Total Earnings',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'KES ${earnings.totalEarnings.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${earnings.totalJobsCompleted} jobs completed',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(EarningsModel earnings) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Today',
          'KES ${earnings.todayEarnings.toStringAsFixed(2)}',
          '${earnings.todayJobs} jobs',
          Icons.today,
          Colors.blue,
        ),
        _buildStatCard(
          'This Week',
          'KES ${earnings.thisWeekEarnings.toStringAsFixed(2)}',
          '${earnings.thisWeekJobs} jobs',
          Icons.calendar_view_week,
          Colors.green,
        ),
        _buildStatCard(
          'This Month',
          'KES ${earnings.thisMonthEarnings.toStringAsFixed(2)}',
          '${earnings.thisMonthJobs} jobs',
          Icons.calendar_today,
          Colors.orange,
        ),
        _buildStatCard(
          'Average',
          'KES ${(earnings.totalEarnings / earnings.totalJobsCompleted).toStringAsFixed(2)}',
          'per job',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(EarningsModel earnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: earnings.recentTransactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final transaction = earnings.recentTransactions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.attach_money, color: Colors.green),
              ),
              title: Text(transaction.customerName),
              subtitle: Text(_formatDate(transaction.date)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'KES ${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    transaction.status,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
