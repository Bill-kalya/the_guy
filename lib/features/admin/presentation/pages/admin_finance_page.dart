import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../providers/admin_finance_provider.dart';

class AdminFinancePage extends ConsumerStatefulWidget {
  const AdminFinancePage({super.key});

  @override
  ConsumerState<AdminFinancePage> createState() => _AdminFinancePageState();
}

class _AdminFinancePageState extends ConsumerState<AdminFinancePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminFinanceProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminFinanceProvider);

    return AdminShell(
      currentRoute: 'finance',
      body: state.isLoading && state.summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminPageHeader(title: 'Finance', subtitle: 'Track revenue, payouts and financial health'),
                  const SizedBox(height: 24),
                  _buildKpiCards(state),
                  const SizedBox(height: 24),
                  _buildRevenueChart(state),
                  const SizedBox(height: 24),
                  _buildMainContent(state),
                  const SizedBox(height: 24),
                  _buildBottomRow(state),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCards(AdminFinanceState state) {
    final s = state.summary ?? {};
    final totalRevenue = s['totalRevenue'] ?? 0.0;
    final totalGMV = s['totalGMV'] ?? 0.0;
    final totalEscrow = s['totalEscrow'] ?? 0.0;
    final taxLiability = s['totalTaxLiability'] ?? 0.0;
    final pendingPayouts = s['pendingPayoutsTotal'] ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 5 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Total GMV', value: _fmtMoney(totalGMV), icon: Icons.trending_up, color: AppColors.success)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Platform Revenue', value: _fmtMoney(totalRevenue), icon: Icons.account_balance_wallet, color: AppColors.primary)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Escrow Balance', value: _fmtMoney(totalEscrow), icon: Icons.lock, color: Colors.orange)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Tax Liability', value: _fmtMoney(taxLiability), icon: Icons.receipt, color: Colors.purple)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Pending Payouts', value: _fmtMoney(pendingPayouts), icon: Icons.send, color: Colors.blue)),
          ],
        );
      },
    );
  }

  Widget _buildRevenueChart(AdminFinanceState state) {
    final trend = state.revenueTrend;
    final Map<String, double> gmvByMonth = {};
    for (final entry in trend) {
      final date = entry['date'] ?? '';
      final gmv = (entry['gmv'] ?? 0.0) as num;
      final monthKey = date.toString().substring(0, 7);
      gmvByMonth[monthKey] = (gmvByMonth[monthKey] ?? 0) + gmv.toDouble();
    }

    final chartData = gmvByMonth.entries.toList();
    final shortLabels = chartData.map((e) {
      final parts = e.key.split('-');
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final m = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
      return months[m.clamp(1, 12)];
    }).toList();

    return AdminSectionCard(
      title: 'Revenue Trend',
      titleIcon: Icons.bar_chart,
      child: Column(
        children: [
          if (chartData.isEmpty)
            const SizedBox(
              height: 180,
              child: AdminEmptyState(icon: Icons.bar_chart, title: 'No revenue data', subtitle: 'Revenue trend will appear here'),
            )
          else
            SizedBox(
              height: 180,
              child: AdminMiniBarChart(
                data: List.generate(chartData.length, (i) => MapEntry(shortLabels[i], chartData[i].value)),
                barColor: AppColors.success,
                maxHeight: 160,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AdminFinanceState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildLedgerTable(state)),
              const SizedBox(width: 20),
              SizedBox(width: 280, child: Column(
                children: [
                  _buildFinancialRisk(state),
                  const SizedBox(height: 20),
                  _buildFeeBreakdown(),
                ],
              )),
            ],
          );
        }
        return Column(
          children: [
            _buildLedgerTable(state),
            const SizedBox(height: 20),
            _buildFinancialRisk(state),
            const SizedBox(height: 20),
            _buildFeeBreakdown(),
          ],
        );
      },
    );
  }

  Widget _buildLedgerTable(AdminFinanceState state) {
    final ledger = state.ledger;

    return AdminSectionCard(
      title: 'Ledger Entries',
      titleIcon: Icons.receipt_long,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Text('${ledger.length} entries', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
      ),
      child: ledger.isEmpty
          ? const AdminEmptyState(icon: Icons.receipt_long, title: 'No ledger entries', subtitle: 'Financial entries will appear here')
          : Column(
              children: [
                const AdminTableHeader(columns: ['Account', 'Type', 'Amount', 'Reference'], flexes: [3, 2, 2, 3]),
                const SizedBox(height: 8),
                ...ledger.take(10).map((entry) => _ledgerRow(entry)),
              ],
            ),
    );
  }

  Widget _ledgerRow(dynamic entry) {
    final accountCode = entry['accountCode'] ?? '';
    final entryType = entry['entryType'] ?? '';
    final amount = entry['amount'] ?? 0.0;
    final referenceType = entry['referenceType'] ?? '';
    final typeColor = entryType.toString() == 'CREDIT' ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(accountCode.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)))),
          Expanded(flex: 2, child: AdminStatusBadge(label: entryType.toString(), color: typeColor)),
          Expanded(flex: 2, child: Text(_fmtMoney(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
          Expanded(flex: 3, child: Text(referenceType.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
        ],
      ),
    );
  }

  Widget _buildFinancialRisk(AdminFinanceState state) {
    final s = state.summary ?? {};
    final failedPayments = s['failedPayments'] ?? 0;
    final openDisputes = s['openDisputesTotal'] ?? 0;
    final refundExposure = s['refundExposure'] ?? 0.0;

    return AdminSectionCard(
      title: 'Financial Risk',
      titleIcon: Icons.shield,
      child: Column(
        children: [
          _riskRow('Failed Payments', '$failedPayments', failedPayments > 0 ? Colors.orange : AppColors.success, failedPayments > 0 ? 'Monitor' : 'Healthy'),
          const SizedBox(height: 16),
          _riskRow('Open Disputes', '$openDisputes', openDisputes > 0 ? AppColors.error : AppColors.success, openDisputes > 0 ? 'Requires attention' : 'Clear'),
          const SizedBox(height: 16),
          _riskRow('Refund Exposure', _fmtMoney(refundExposure), refundExposure > 0 ? Colors.orange : AppColors.success, refundExposure > 0 ? 'Monitor' : 'Low risk'),
        ],
      ),
    );
  }

  Widget _riskRow(String label, String value, Color color, String status) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Icon(Icons.circle, size: 10, color: color)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
            Text(status, style: TextStyle(fontSize: 11, color: color)),
          ]),
        ),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildFeeBreakdown() {
    return AdminSectionCard(
      title: 'Fee Structure',
      titleIcon: Icons.percent,
      child: Column(
        children: [
          _feeRow('Service Fee', '10%', Colors.blue),
          const SizedBox(height: 12),
          _feeRow('Platform Commission', '2%', AppColors.primary),
          const SizedBox(height: 12),
          _feeRow('Escrow Fee', '1%', Colors.orange),
          const SizedBox(height: 12),
          _feeRow('Tax (VAT)', '16%', Colors.purple),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String rate, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
        Text(rate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildBottomRow(AdminFinanceState state) {
    final payouts = state.pendingPayouts;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildUpcomingPayouts(payouts)),
              const SizedBox(width: 20),
              Expanded(child: _buildSummaryCard(state)),
            ],
          );
        }
        return Column(
          children: [
            _buildUpcomingPayouts(payouts),
            const SizedBox(height: 20),
            _buildSummaryCard(state),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingPayouts(List<dynamic> payouts) {
    return AdminSectionCard(
      title: 'Pending Payouts',
      titleIcon: Icons.send,
      child: payouts.isEmpty
          ? const AdminEmptyState(icon: Icons.send, title: 'No pending payouts', subtitle: 'Payout requests will appear here')
          : Column(
              children: payouts.take(5).map((p) {
                final name = p['providerName'] ?? 'Unknown';
                final amount = p['amount'] ?? 0.0;
                final method = p['method'] ?? 'UNKNOWN';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: Text(
                          name.toString().split(' ').map((w) => w[0]).take(2).join(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                            Text(method.toString(), style: TextStyle(fontSize: 11, color: Colors.orange)),
                          ],
                        ),
                      ),
                      Text(_fmtMoney(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSummaryCard(AdminFinanceState state) {
    final s = state.summary ?? {};
    final totalGMV = s['totalGMV'] ?? 0.0;
    final totalRevenue = s['totalRevenue'] ?? 0.0;
    final taxLiability = s['totalTaxLiability'] ?? 0.0;
    final totalEscrow = s['totalEscrow'] ?? 0.0;
    final failedPayments = s['failedPayments'] ?? 0;

    return AdminSectionCard(
      title: 'Financial Summary',
      titleIcon: Icons.summarize,
      child: Column(
        children: [
          _summaryRow('Total GMV', _fmtMoney(totalGMV)),
          _summaryRow('Platform Revenue', _fmtMoney(totalRevenue)),
          _summaryRow('Tax Liability', _fmtMoney(taxLiability)),
          _summaryRow('Escrow Balance', _fmtMoney(totalEscrow)),
          _summaryRow('Failed Payments', '$failedPayments'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  String _fmtMoney(dynamic v) {
    final n = v is num ? v.toDouble() : 0.0;
    if (n >= 1000000) return 'KES ${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return 'KES ${(n / 1000).toStringAsFixed(1)}K';
    return 'KES ${n.toStringAsFixed(0)}';
  }
}
