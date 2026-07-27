import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../providers/admin_overview_provider.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminOverviewProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOverviewProvider);

    return AdminShell(
      currentRoute: 'overview',
      body: state.isLoading && state.userSummary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 24),
                  _buildKpiCards(state),
                  const SizedBox(height: 24),
                  _buildMiddleSection(state),
                  const SizedBox(height: 24),
                  _buildPlatformHealth(state),
                ],
              ),
            ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text('Platform overview and key metrics', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildKpiCards(AdminOverviewState state) {
    final users = state.userSummary ?? {};
    final providers = state.providerSummary ?? {};
    final jobs = state.jobsSummary ?? {};
    final finance = state.financeSummary ?? {};

    final totalUsers = users['totalUsers'] ?? 0;
    final totalProviders = providers['totalProviders'] ?? 0;
    final activeJobs = jobs['activeJobs'] ?? 0;
    final gmv = finance['totalGMV'] ?? 0.0;
    final gmvStr = _formatMoney(gmv);

    final kpis = [
      ('Users', _fmtInt(totalUsers), Icons.person, Colors.blue, null),
      ('Providers', _fmtInt(totalProviders), Icons.people, Colors.green, null),
      ('Active Jobs', _fmtInt(activeJobs), Icons.work, Colors.amber, null),
      ('Total GMV', gmvStr, Icons.account_balance, Colors.purple, 'All time'),
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

  Widget _kpiCard((String, String, IconData, MaterialColor, String?) kpi) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kpi.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(kpi.$3, size: 22, color: kpi.$4.shade600),
          ),
          const SizedBox(height: 16),
          Text(kpi.$1, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(kpi.$2, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          if (kpi.$5 != null) ...[
            const SizedBox(height: 4),
            Text(kpi.$5!, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _buildMiddleSection(AdminOverviewState state) {
    final riskOverview = state.safetySummary ?? {};
    final auditLogs = state.auditLogs ?? {};
    final content = auditLogs['content'] as List<dynamic>? ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRiskAlerts(riskOverview)),
              const SizedBox(width: 24),
              Expanded(child: _buildLiveActivity(content)),
            ],
          );
        }
        return Column(
          children: [
            _buildRiskAlerts(riskOverview),
            const SizedBox(height: 24),
            _buildLiveActivity(content),
          ],
        );
      },
    );
  }

  Widget _buildRiskAlerts(Map<String, dynamic> riskOverview) {
    final high = riskOverview['high'] ?? 0;
    final critical = riskOverview['critical'] ?? 0;
    final medium = riskOverview['medium'] ?? 0;
    final low = riskOverview['low'] ?? 0;

    final alerts = [
      ('Critical', (critical as num).toInt(), Colors.red),
      ('High Risk', (high as num).toInt(), Colors.orange),
      ('Medium', (medium as num).toInt(), Colors.amber),
      ('Low', (low as num).toInt(), Colors.blue),
    ];

    return AdminSectionCard(
      title: 'Risk Overview',
      titleIcon: Icons.shield,
      trailing: TextButton(
        onPressed: () => context.go('/admin/trust-safety'),
        child: const Text('View All'),
      ),
      child: Column(
        children: [
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: alert.$3.shade500, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(alert.$1, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: alert.$3.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${alert.$2}', style: TextStyle(color: alert.$3.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          if (critical > 0 || high > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade100)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text('${critical + high} high-priority actions require attention', style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveActivity(List<dynamic> auditLogs) {
    return AdminSectionCard(
      title: 'Recent Activity',
      titleIcon: Icons.timeline,
      child: auditLogs.isEmpty
          ? AdminEmptyState(icon: Icons.history, title: 'No recent activity', subtitle: 'Audit logs will appear here')
          : Column(
              children: auditLogs.where((log) => log != null).take(6).map((log) {
                final actionType = log['actionType'] ?? 'Unknown';
                final targetType = log['targetType'] ?? '';
                final createdAt = log['createdAt'] ?? '';
                final icon = _actionIcon(actionType.toString());
                final color = _actionColor(actionType.toString());
                final timeStr = _timeAgo(createdAt.toString());

                return AdminActivityTile(
                  icon: icon,
                  color: color,
                  title: _formatActionType(actionType.toString()),
                  subtitle: targetType.toString(),
                  time: timeStr,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPlatformHealth(AdminOverviewState state) {
    final jobs = state.jobsSummary ?? {};
    final users = state.userSummary ?? {};
    final providers = state.providerSummary ?? {};

    final completionRate = (jobs['completionRate'] ?? 0.0) as num;
    final verifiedPct = (users['verifiedPercentage'] ?? 0.0) as num;
    final avgRating = (providers['avgRating'] ?? 0.0) as num;
    final onlineNow = providers['onlineNow'] ?? 0;

    return AdminSectionCard(
      title: 'Platform Health',
      titleIcon: Icons.monitor_heart,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          if (isWide) {
            return Row(
              children: [
                Expanded(child: _healthMetric('Job Completion Rate', '${completionRate.toStringAsFixed(1)}%', (completionRate / 100).clamp(0.0, 1.0).toDouble(), Colors.green)),
                Expanded(child: _healthMetric('User Verification', '${verifiedPct.toStringAsFixed(1)}%', (verifiedPct / 100).clamp(0.0, 1.0).toDouble(), Colors.blue)),
                Expanded(child: _healthMetric('Avg Provider Rating', '${avgRating.toStringAsFixed(1)}/5', (avgRating / 5).clamp(0.0, 1.0).toDouble(), Colors.amber)),
                Expanded(child: _healthMetric('Providers Online', '$onlineNow', onlineNow > 0 ? 1.0 : 0.0, Colors.teal)),
              ],
            );
          }
          return Column(
            children: [
              _healthMetric('Job Completion Rate', '${completionRate.toStringAsFixed(1)}%', (completionRate / 100).clamp(0.0, 1.0).toDouble(), Colors.green),
              const SizedBox(height: 16),
              _healthMetric('User Verification', '${verifiedPct.toStringAsFixed(1)}%', (verifiedPct / 100).clamp(0.0, 1.0).toDouble(), Colors.blue),
              const SizedBox(height: 16),
              _healthMetric('Avg Provider Rating', '${avgRating.toStringAsFixed(1)}/5', (avgRating / 5).clamp(0.0, 1.0).toDouble(), Colors.amber),
              const SizedBox(height: 16),
              _healthMetric('Providers Online', '$onlineNow', onlineNow > 0 ? 1.0 : 0.0, Colors.teal),
            ],
          );
        },
      ),
    );
  }

  Widget _healthMetric(String label, String value, double progress, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: color.shade100, valueColor: AlwaysStoppedAnimation(color.shade600), minHeight: 6),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 0.9 ? 'Excellent' : progress >= 0.7 ? 'Good' : progress >= 0.4 ? 'Fair' : 'Needs Attention',
            style: TextStyle(
              fontSize: 12,
              color: progress >= 0.9 ? Colors.green.shade600 : progress >= 0.7 ? Colors.amber.shade600 : Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtInt(dynamic v) {
    final n = v is num ? v.toInt() : 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatMoney(dynamic v) {
    final n = v is num ? v.toDouble() : 0.0;
    if (n >= 1000000) return 'KES ${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return 'KES ${(n / 1000).toStringAsFixed(1)}K';
    return 'KES ${n.toStringAsFixed(0)}';
  }

  IconData _actionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'IMPERSONATION': return Icons.remove_red_eye;
      case 'USER_SUSPEND': case 'PROVIDER_SUSPEND': return Icons.block;
      case 'USER_BAN': return Icons.gavel;
      case 'USER_ACTION': return Icons.security;
      default: return Icons.admin_panel_settings;
    }
  }

  Color _actionColor(String type) {
    switch (type.toUpperCase()) {
      case 'IMPERSONATION': return AppColors.primary;
      case 'USER_SUSPEND': case 'PROVIDER_SUSPEND': return Colors.orange;
      case 'USER_BAN': return AppColors.error;
      default: return Colors.grey;
    }
  }

  String _formatActionType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  String _timeAgo(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
