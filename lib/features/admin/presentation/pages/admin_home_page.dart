import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: 'overview',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            _buildPageHeader(),
            const SizedBox(height: 24),
            // KPI Cards
            _buildKpiCards(),
            const SizedBox(height: 24),
            // Two-column layout for alerts and activity
            _buildMiddleSection(),
            const SizedBox(height: 24),
            // Platform Health
            _buildPlatformHealth(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Platform overview and key metrics',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCards() {
    final kpis = [
      ('Users', '24,567', '↑ 12%', Icons.person, Colors.blue, '+2,340 this week'),
      ('Providers', '3,182', '↑ 8%', Icons.people, Colors.green, '+184 this week'),
      ('Active Jobs', '1,248', '↑ 5%', Icons.work, Colors.amber, '92% completion rate'),
      ('Revenue', 'KES 3.2M', '↑ 15%', Icons.account_balance, Colors.purple, 'This month'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            children: kpis.map((kpi) => Expanded(child: _kpiCard(kpi))).toList(),
          );
        }
        return Wrap(
          children: kpis
              .map((kpi) => SizedBox(
                    width: constraints.maxWidth > 600
                        ? (constraints.maxWidth - 24) / 2
                        : constraints.maxWidth,
                    child: _kpiCard(kpi),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _kpiCard(
      (String, String, String, IconData, MaterialColor, String) kpi) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kpi.$5.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(kpi.$4, size: 22, color: kpi.$5.shade600),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  kpi.$2,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            kpi.$1,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.$2,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.$6,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRiskAlerts()),
              const SizedBox(width: 24),
              Expanded(child: _buildLiveActivity()),
            ],
          );
        }
        return Column(
          children: [
            _buildRiskAlerts(),
            const SizedBox(height: 24),
            _buildLiveActivity(),
          ],
        );
      },
    );
  }

  Widget _buildRiskAlerts() {
    final alerts = [
      ('Fraud', 3, Colors.red),
      ('Abuse', 5, Colors.orange),
      ('Disputes', 12, Colors.amber),
      ('Pending Reviews', 28, Colors.blue),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Risk Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: alert.$3.shade500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.$1,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: alert.$3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alert.$2}',
                      style: TextStyle(
                        color: alert.$3.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  '3 high-risk actions require attention',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveActivity() {
    final activities = [
      ('User requested plumber in Nairobi', '2 min ago', Icons.person),
      ('Provider accepted booking #3842', '5 min ago', Icons.check_circle),
      ('Job completed - Cleaning Service', '12 min ago', Icons.celebration),
      ('New provider registered', '18 min ago', Icons.person_add),
      ('Payment processed - KES 2,500', '25 min ago', Icons.payment),
      ('Dispute opened for Job #3810', '30 min ago', Icons.report),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Marketplace Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          ...activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(activity.$3, size: 18, color: Colors.blue.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.$1,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          activity.$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('View Full Activity Log'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformHealth() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Health',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: _healthMetric('Booking Success Rate', '97.2%', 0.97, Colors.green)),
                    Expanded(child: _healthMetric('Fraud Risk Score', '1.4%', 0.986, Colors.green)),
                    Expanded(child: _healthMetric('Avg Response Time', '3m 12s', 0.85, Colors.blue)),
                    Expanded(child: _healthMetric('Satisfaction Score', '4.8/5', 0.96, Colors.amber)),
                  ],
                );
              }
              return Wrap(
                children: [
                  SizedBox(width: constraints.maxWidth, child: _healthMetric('Booking Success Rate', '97.2%', 0.97, Colors.green)),
                  SizedBox(width: constraints.maxWidth, child: _healthMetric('Fraud Risk Score', '1.4%', 0.986, Colors.green)),
                  SizedBox(width: constraints.maxWidth, child: _healthMetric('Avg Response Time', '3m 12s', 0.85, Colors.blue)),
                  SizedBox(width: constraints.maxWidth, child: _healthMetric('Satisfaction Score', '4.8/5', 0.96, Colors.amber)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _healthMetric(
      String label, String value, double progress, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.shade100,
              valueColor: AlwaysStoppedAnimation(color.shade600),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 0.9 ? 'Excellent' : progress >= 0.8 ? 'Good' : 'Needs Attention',
            style: TextStyle(
              fontSize: 12,
              color: progress >= 0.9
                  ? Colors.green.shade600
                  : progress >= 0.8
                      ? Colors.amber.shade600
                      : Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}