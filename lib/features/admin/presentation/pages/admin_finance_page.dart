import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';

class AdminFinancePage extends StatefulWidget {
  const AdminFinancePage({super.key});

  @override
  State<AdminFinancePage> createState() => _AdminFinancePageState();
}

class _AdminFinancePageState extends State<AdminFinancePage> {
  final _searchController = TextEditingController();

  static const _transactions = [
    (id: 'TXN-001', customer: 'John Doe', provider: 'Grace Wanjiku', service: 'Plumbing', amount: 'KES 4,500', fee: 'KES 450', status: 'Completed', time: '10 min ago'),
    (id: 'TXN-002', customer: 'Mary Smith', provider: 'James Mwangi', service: 'Electrical', amount: 'KES 8,200', fee: 'KES 820', status: 'Escrow', time: '30 min ago'),
    (id: 'TXN-003', customer: 'Sarah Njeri', provider: 'Peter Kamau', service: 'Painting', amount: 'KES 12,000', fee: 'KES 1,200', status: 'Disputed', time: '2h ago'),
    (id: 'TXN-004', customer: 'David Ochieng', provider: 'Alice Adhiambo', service: 'Carpentry', amount: 'KES 3,500', fee: 'KES 350', status: 'Refunded', time: '5h ago'),
    (id: 'TXN-005', customer: 'Grace Wanjiku', provider: 'David Ochieng', service: 'Cleaning', amount: 'KES 6,000', fee: 'KES 600', status: 'Completed', time: '8h ago'),
    (id: 'TXN-006', customer: 'Peter Kamau', provider: 'Daniel Kipchoge', service: 'Landscaping', amount: 'KES 15,000', fee: 'KES 1,500', status: 'Pending', time: '1d ago'),
    (id: 'TXN-007', customer: 'Alice Adhiambo', provider: 'Sarah Njeri', service: 'Tailoring', amount: 'KES 2,800', fee: 'KES 280', status: 'Completed', time: '2d ago'),
    (id: 'TXN-008', customer: 'James Mwangi', provider: 'Faith Wambui', service: 'Roofing', amount: 'KES 22,000', fee: 'KES 2,200', status: 'Completed', time: '3d ago'),
  ];

  static const _todaySummary = [
    (label: 'Transactions', value: '47'),
    (label: 'Revenue Collected', value: 'KES 186,400'),
    (label: 'Platform Fees', value: 'KES 18,640'),
    (label: 'Payouts Processed', value: 'KES 124,200'),
    (label: 'Refunds Issued', value: 'KES 8,200'),
    (label: 'Net Revenue', value: 'KES 10,440'),
  ];

  static const _upcomingPayouts = [
    (name: 'Grace Wanjiku', amount: 'KES 45,000', due: 'Today', status: 'Processing'),
    (name: 'James Mwangi', amount: 'KES 32,000', due: 'Today', status: 'Pending'),
    (name: 'David Ochieng', amount: 'KES 28,500', due: 'Tomorrow', status: 'Scheduled'),
    (name: 'Daniel Kipchoge', amount: 'KES 19,800', due: 'Tomorrow', status: 'Scheduled'),
    (name: 'Sarah Njeri', amount: 'KES 14,200', due: 'In 2 days', status: 'Scheduled'),
  ];

  static const _monthlyRevenue = [
    (month: 'Jan', revenue: 2100000.0),
    (month: 'Feb', revenue: 2450000.0),
    (month: 'Mar', revenue: 2800000.0),
    (month: 'Apr', revenue: 2650000.0),
    (month: 'May', revenue: 3200000.0),
    (month: 'Jun', revenue: 3450000.0),
    (month: 'Jul', revenue: 3100000.0),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: 'finance',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title: 'Finance',
              subtitle: 'Track revenue, payouts and financial health',
            ),
            const SizedBox(height: 24),
            _buildKpiCards(),
            const SizedBox(height: 24),
            _buildRevenueChart(),
            const SizedBox(height: 24),
            _buildMainContent(),
            const SizedBox(height: 24),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 5 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Total Revenue', value: 'KES 18.6M', icon: Icons.trending_up, color: AppColors.success, subtitle: '+18% vs last month')),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Platform Fees', value: 'KES 1.86M', icon: Icons.account_balance_wallet, color: AppColors.primary)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Provider Payouts', value: 'KES 14.2M', icon: Icons.send, color: Colors.blue)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Escrow Balance', value: 'KES 2.4M', icon: Icons.lock, color: Colors.orange)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Tax Collected', value: 'KES 2.8M', icon: Icons.receipt, color: Colors.purple)),
          ],
        );
      },
    );
  }

  Widget _buildRevenueChart() {
    return AdminSectionCard(
      title: 'Revenue Overview',
      titleIcon: Icons.bar_chart,
      trailing: Wrap(
        spacing: 8,
        children: ['Week', 'Month', 'Quarter'].map((period) {
          final isSelected = period == 'Month';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(period, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.grey.shade600)),
          );
        }).toList(),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: AdminMiniBarChart(
              data: _monthlyRevenue.map((m) => MapEntry(m.month, m.revenue)).toList(),
              barColor: AppColors.success,
              maxHeight: 160,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text('Monthly Revenue (KES)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildTransactionTable()),
              const SizedBox(width: 20),
              SizedBox(width: 280, child: Column(
                children: [
                  _buildTodaySummary(),
                  const SizedBox(height: 20),
                  _buildFeeBreakdown(),
                ],
              )),
            ],
          );
        }
        return Column(
          children: [
            _buildTransactionTable(),
            const SizedBox(height: 20),
            _buildTodaySummary(),
            const SizedBox(height: 20),
            _buildFeeBreakdown(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTable() {
    return AdminSectionCard(
      title: 'Transactions',
      titleIcon: Icons.receipt_long,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Text('${_transactions.length} recent', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
      ),
      child: Column(
        children: [
          const AdminTableHeader(
            columns: ['ID', 'Customer \u2192 Provider', 'Service', 'Amount', 'Fee', 'Status'],
            flexes: [1, 3, 2, 2, 2, 2],
          ),
          const SizedBox(height: 8),
          ..._transactions.map((t) => _transactionRow(t)),
        ],
      ),
    );
  }

  Widget _transactionRow(dynamic t) {
    final statusColor = t.status == 'Completed'
        ? AppColors.success
        : t.status == 'Escrow' || t.status == 'Pending'
            ? Colors.orange
            : t.status == 'Disputed'
                ? AppColors.error
                : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(t.id, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.customer} \u2192 ${t.provider}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                Text(t.time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
              child: Text(t.service, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(t.amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          ),
          Expanded(
            flex: 2,
            child: Text(t.fee, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ),
          Expanded(flex: 2, child: AdminStatusBadge(label: t.status, color: statusColor)),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return AdminSectionCard(
      title: "Today's Summary",
      titleIcon: Icons.today,
      child: Column(
        children: _todaySummary.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text(s.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            ],
          ),
        )).toList(),
      ),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
        Text(rate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildUpcomingPayouts()),
              const SizedBox(width: 20),
              Expanded(child: _buildRiskCard()),
            ],
          );
        }
        return Column(
          children: [
            _buildUpcomingPayouts(),
            const SizedBox(height: 20),
            _buildRiskCard(),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingPayouts() {
    return AdminSectionCard(
      title: 'Upcoming Payouts',
      titleIcon: Icons.send,
      child: Column(
        children: _upcomingPayouts.map((p) {
          final statusColor = p.status == 'Processing'
              ? Colors.blue
              : p.status == 'Pending'
                  ? Colors.orange
                  : Colors.grey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    p.name.toString().split(' ').map((w) => w[0]).take(2).join(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                      Text('${p.due} \u00b7 ${p.status}', style: TextStyle(fontSize: 11, color: statusColor)),
                    ],
                  ),
                ),
                Text(p.amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRiskCard() {
    return AdminSectionCard(
      title: 'Financial Risk',
      titleIcon: Icons.shield,
      child: Column(
        children: [
          _riskRow('Fraud Detection', '0.02%', AppColors.success, 'Low risk'),
          const SizedBox(height: 16),
          _riskRow('Failed Payments', '1.3%', Colors.orange, 'Monitor'),
          const SizedBox(height: 16),
          _riskRow('Chargeback Rate', '0.1%', AppColors.success, 'Healthy'),
          const SizedBox(height: 16),
          _riskRow('Dispute Resolution', '94%', AppColors.primary, 'Above target'),
        ],
      ),
    );
  }

  Widget _riskRow(String label, String value, Color color, String status) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.circle, size: 10, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
              Text(status, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
