import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/earnings_provider.dart';
import '../../models/earnings_model.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import 'earnings_screen_desktop.dart';
import '../../../../core/themes/colors.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _selectedPeriod = 'Month';

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

    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text('Earnings'),
          actions: [
            if (earningsState.isRefreshing)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (earningsState.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    earningsState.lastUpdatedText,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(earningsProvider.notifier).refreshEarnings(),
            ),
          ],
        ),
        body: earningsState.isLoading && earningsState.earnings == null
            ? _buildSkeleton()
            : earningsState.error != null && earningsState.earnings == null
                ? _buildErrorWidget(earningsState.error!)
                : earningsState.earnings != null
                    ? _buildContent(earningsState)
                    : const SizedBox(),
      ),
      desktop: EarningsScreenDesktop(),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Container(
                height: 100,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 8, right: i == 1 ? 0 : 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (i) => Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          )),
        ],
      ),
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
            onPressed: () => ref.read(earningsProvider.notifier).refreshEarnings(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EarningsState state) {
    final earnings = state.earnings!;
    return RefreshIndicator(
      onRefresh: () => ref.read(earningsProvider.notifier).refreshEarnings(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletSection(earnings),
            const SizedBox(height: 24),
            _buildAnalyticsSection(earnings),
            const SizedBox(height: 24),
            _buildRecentTransactions(earnings),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection(EarningsModel earnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: earnings.availableBalance > 0 ? () {} : null,
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('Withdraw'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                'KES ${earnings.availableBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _walletMiniCard(
              'Pending', 'KES ${earnings.pendingBalance.toStringAsFixed(0)}',
              Icons.hourglass_empty, Colors.orange,
            )),
            const SizedBox(width: 12),
            Expanded(child: _walletMiniCard(
              'Lifetime', 'KES ${(earnings.totalEarnings / 1000).toStringAsFixed(1)}K',
              Icons.account_balance, Colors.green,
            )),
          ],
        ),
      ],
    );
  }

  Widget _walletMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(EarningsModel earnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: ['Today', 'Week', 'Month', 'Year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildEarningsChart(earnings),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _analyticsStat('Jobs', '${_getPeriodJobs(earnings)}', Icons.work, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _analyticsStat('Avg/Job', 'KES ${_getAvgPerJob(earnings)}', Icons.trending_up, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsChart(EarningsModel earnings) {
    final isWeek = _selectedPeriod == 'Week';

    if (isWeek && earnings.weeklyEarnings.isEmpty ||
        !isWeek && earnings.monthlyEarnings.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: Text('No chart data yet', style: TextStyle(color: Colors.grey))),
      );
    }

    if (isWeek) {
      final data = earnings.weeklyEarnings;
      final maxAmount = data.map((e) => e.amount).fold(0.0, (a, b) => a > b ? a : b);

      return Container(
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.take(7).map((item) {
            final height = maxAmount > 0 ? (item.amount / maxAmount) * 100 : 0.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${(item.amount / 1000).toStringAsFixed(1)}K',
                      style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: height.clamp(4.0, 80.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.day, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else {
      final data = earnings.monthlyEarnings;
      final maxAmount = data.map((e) => e.amount).fold(0.0, (a, b) => a > b ? a : b);

      return Container(
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.take(7).map((item) {
            final height = maxAmount > 0 ? (item.amount / maxAmount) * 100 : 0.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${(item.amount / 1000).toStringAsFixed(1)}K',
                      style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: height.clamp(4.0, 80.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.month, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _analyticsStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(EarningsModel earnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (earnings.recentTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey))),
          )
        else
          ...earnings.recentTransactions.take(10).map((tx) => _transactionTile(tx)),
      ],
    );
  }

  Widget _transactionTile(EarningTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verified Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(_formatDate(tx.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${tx.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
              ),
              Text(tx.status, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  int _getPeriodJobs(EarningsModel earnings) {
    switch (_selectedPeriod) {
      case 'Today': return earnings.todayJobs;
      case 'Week': return earnings.thisWeekJobs;
      case 'Month': return earnings.thisMonthJobs;
      case 'Year': return earnings.totalJobsCompleted;
      default: return earnings.totalJobsCompleted;
    }
  }

  String _getAvgPerJob(EarningsModel earnings) {
    int jobs = _getPeriodJobs(earnings);
    if (jobs == 0) return '0';
    double total;
    switch (_selectedPeriod) {
      case 'Today': total = earnings.todayEarnings; break;
      case 'Week': total = earnings.thisWeekEarnings; break;
      case 'Month': total = earnings.thisMonthEarnings; break;
      default: total = earnings.totalEarnings;
    }
    return (total / jobs).toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
