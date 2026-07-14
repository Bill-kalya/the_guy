import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/earnings_provider.dart';
import '../../models/earnings_model.dart';
import '../../../../shared/widgets/loading_widget.dart';

class EarningsScreenDesktop extends ConsumerStatefulWidget {
  const EarningsScreenDesktop({super.key});

  @override
  ConsumerState<EarningsScreenDesktop> createState() => _EarningsScreenDesktopState();
}

class _EarningsScreenDesktopState extends ConsumerState<EarningsScreenDesktop> {
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
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: earningsState.isLoading
                ? const LoadingWidget()
                : earningsState.error != null
                    ? _buildErrorWidget(earningsState.error!)
                    : earningsState.earnings != null
                        ? _buildEarningsContent(earningsState.earnings!)
                        : const SizedBox(),
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
            const Text('Earnings Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Updated just now', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(earningsProvider.notifier).refreshEarnings(),
              tooltip: 'Refresh',
            ),
          ],
        ),
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
          Text(error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(earningsProvider.notifier).refreshEarnings(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsContent(EarningsModel earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total earnings hero card
              _buildTotalEarningsCard(earnings),
              const SizedBox(height: 24),
              // Stats grid
              _buildStatsGrid(earnings),
              const SizedBox(height: 24),
              // Weekly chart + Recent transactions side by side
              _buildChartsAndTransactions(earnings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard(EarningsModel earnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.green, Colors.greenAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                  'KES ${earnings.totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                Text('${earnings.totalJobsCompleted} jobs completed', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          Container(width: 1, height: 80, color: Colors.white24),
          const SizedBox(width: 32),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat('Today', 'KES ${earnings.todayEarnings.toStringAsFixed(0)}', '${earnings.todayJobs} jobs'),
                Container(width: 1, height: 40, color: Colors.white24),
                _miniStat('Week', 'KES ${earnings.thisWeekEarnings.toStringAsFixed(0)}', '${earnings.thisWeekJobs} jobs'),
                Container(width: 1, height: 40, color: Colors.white24),
                _miniStat('Month', 'KES ${earnings.thisMonthEarnings.toStringAsFixed(0)}', '${earnings.thisMonthJobs} jobs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String amount, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatsGrid(EarningsModel earnings) {
    final avgPerJob = earnings.totalJobsCompleted > 0
        ? (earnings.totalEarnings / earnings.totalJobsCompleted).toStringAsFixed(2)
        : '0.00';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            children: [
              _statCard(Icons.today, 'Today', 'KES ${earnings.todayEarnings.toStringAsFixed(2)}', '${earnings.todayJobs} jobs', Colors.blue),
              _statCard(Icons.calendar_view_week, 'This Week', 'KES ${earnings.thisWeekEarnings.toStringAsFixed(2)}', '${earnings.thisWeekJobs} jobs', Colors.green),
              _statCard(Icons.calendar_today, 'This Month', 'KES ${earnings.thisMonthEarnings.toStringAsFixed(2)}', '${earnings.thisMonthJobs} jobs', Colors.orange),
              _statCard(Icons.trending_up, 'Average Per Job', 'KES $avgPerJob', 'per job', Colors.purple),
            ],
          );
        }
        return Wrap(
          children: [
            SizedBox(width: constraints.maxWidth / 2 - 12, child: _statCard(Icons.today, 'Today', 'KES ${earnings.todayEarnings.toStringAsFixed(2)}', '${earnings.todayJobs} jobs', Colors.blue)),
            SizedBox(width: constraints.maxWidth / 2 - 12, child: _statCard(Icons.calendar_view_week, 'This Week', 'KES ${earnings.thisWeekEarnings.toStringAsFixed(2)}', '${earnings.thisWeekJobs} jobs', Colors.green)),
            SizedBox(width: constraints.maxWidth / 2 - 12, child: _statCard(Icons.calendar_today, 'This Month', 'KES ${earnings.thisMonthEarnings.toStringAsFixed(2)}', '${earnings.thisMonthJobs} jobs', Colors.orange)),
            SizedBox(width: constraints.maxWidth / 2 - 12, child: _statCard(Icons.trending_up, 'Average Per Job', 'KES $avgPerJob', 'per job', Colors.purple)),
          ],
        );
      },
    );
  }

  Widget _statCard(IconData icon, String title, String amount, String subtitle, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border(top: BorderSide(color: color.shade500, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 20, color: color.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsAndTransactions(EarningsModel earnings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildWeeklyChart(earnings)),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: _buildRecentTransactions(earnings)),
            ],
          );
        }
        return Column(
          children: [
            _buildWeeklyChart(earnings),
            const SizedBox(height: 24),
            _buildRecentTransactions(earnings),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyChart(EarningsModel earnings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 20),
          if (earnings.weeklyEarnings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No earnings data yet', style: TextStyle(color: Colors.grey))),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: earnings.weeklyEarnings.map((day) {
                  final maxAmount = earnings.weeklyEarnings.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
                  final height = maxAmount > 0 ? (day.amount / maxAmount) * 160 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('KES ${day.amount.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.green.shade300, Colors.green.shade600], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(day.day.substring(0, 3), style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(EarningsModel earnings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
              ],
            ),
          ),
          if (earnings.recentTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey))),
            )
          else
            ...earnings.recentTransactions.take(5).map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: Colors.green.shade100,
                          child: Text(t.customerName[0], style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.customerName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                            Text(_formatDate(t.date), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('KES ${t.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.status == 'completed' ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.status[0].toUpperCase() + t.status.substring(1),
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: t.status == 'completed' ? Colors.green.shade700 : Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}