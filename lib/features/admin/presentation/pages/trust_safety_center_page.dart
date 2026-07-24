import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/admin_shell.dart';
import '../providers/admin_safety_provider.dart';
import '../../../../core/themes/colors.dart';

class TrustSafetyCenterPage extends ConsumerStatefulWidget {
  const TrustSafetyCenterPage({super.key});

  @override
  ConsumerState<TrustSafetyCenterPage> createState() => _TrustSafetyCenterPageState();
}

class _TrustSafetyCenterPageState extends ConsumerState<TrustSafetyCenterPage> {
  String _queueFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSafetyProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final safety = ref.watch(adminSafetyProvider);

    return AdminShell(
      currentRoute: 'safety',
      body: safety.isLoading && safety.summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(safety),
                  const SizedBox(height: 24),
                  _buildThreatSummaryCards(safety),
                  const SizedBox(height: 24),
                  _buildCriticalAlerts(safety),
                  const SizedBox(height: 24),
                  _buildRiskHeatMap(safety),
                  const SizedBox(height: 24),
                  _buildProviderModerationTable(safety),
                ],
              ),
            ),
    );
  }

  Widget _buildPageHeader(AdminSafetyState safety) {
    final summary = safety.summary;
    final totalProviders = summary?['totalProviders'] ?? 0;
    final activeRisk = summary?['activeRiskScores'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trust & Safety Center',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Platform Risk Intelligence',
          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.shield, color: Colors.white.withValues(alpha: 0.9), size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Status: Active Monitoring',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalProviders providers monitored • $activeRisk active risk scores',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('All Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThreatSummaryCards(AdminSafetyState safety) {
    final summary = safety.summary ?? {};
    final fraudPct = summary['fraudRiskPercent'] ?? 0;
    final suspicious = summary['suspiciousAccounts'] ?? 0;
    final openDisputes = summary['openDisputes'] ?? 0;
    final banned = summary['bannedProviders'] ?? 0;

    final threats = [
      ('Fraud Risk', '$fraudPct%', Icons.credit_score, Colors.red, 'Platform-wide'),
      ('Suspicious', '$suspicious Accounts', Icons.person_off, Colors.orange, 'Need review'),
      ('Disputes', '$openDisputes Open', Icons.gavel, Colors.amber, 'In progress'),
      ('Banned', '$banned Providers', Icons.block, Colors.grey, 'Permanent'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            children: threats.map((t) => Expanded(child: _threatCard(t))).toList(),
          );
        }
        return Wrap(
          children: threats
              .map((t) => SizedBox(
                    width: constraints.maxWidth > 600
                        ? (constraints.maxWidth - 24) / 2
                        : constraints.maxWidth,
                    child: _threatCard(t),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _threatCard((String, String, IconData, MaterialColor, String) threat) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border(top: BorderSide(color: threat.$4.shade500, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: threat.$4.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(threat.$3, size: 20, color: threat.$4.shade600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Text(threat.$5, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(threat.$1, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(threat.$2, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _buildCriticalAlerts(AdminSafetyState safety) {
    final alerts = safety.alerts;

    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.warning, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text('Critical Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    Text('No critical alerts', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            ...alerts.map((alert) {
              final isCritical = alert['riskLevel'] == 'CRITICAL';
              final color = isCritical ? Colors.red : Colors.orange;
              final userName = alert['userName'] ?? 'Unknown';
              final score = alert['score'] ?? 0;
              final riskLevel = alert['riskLevel'] ?? 'UNKNOWN';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCritical ? Colors.red.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isCritical ? Colors.red.shade200 : Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCritical ? Icons.error : Icons.warning_amber,
                        size: 20,
                        color: isCritical ? Colors.red.shade600 : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$userName — Risk Score: $score',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCritical ? FontWeight.w600 : FontWeight.normal,
                                color: isCritical ? Colors.red.shade800 : const Color(0xFF1A1A2E),
                              ),
                            ),
                            if (alert['recommendations'] != null)
                              Text(
                                alert['recommendations'].toString().split('\n').first,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCritical ? Colors.red.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          riskLevel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRiskHeatMap(AdminSafetyState safety) {
    final heatmap = safety.heatmap;

    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.map, color: Color(0xFF1A1A2E), size: 22),
              SizedBox(width: 8),
              Text('Risk Heat Map by City', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 20),
          if (heatmap.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No location data available', style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ...heatmap.map((city) {
              final avgRisk = (city['avgRiskScore'] as num? ?? 0).toDouble();
              final providerCount = city['providerCount'] ?? 0;
              final normalizedRisk = (avgRisk / 100.0).clamp(0.0, 1.0);
              final color = avgRisk >= 50 ? Colors.red : avgRisk >= 20 ? Colors.orange : Colors.green;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${city['city']} ($providerCount providers)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
                        ),
                        Text(
                          '${avgRisk.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: normalizedRisk,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color.shade500),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, 'Low'),
              const SizedBox(width: 16),
              _legendDot(Colors.amber, 'Medium'),
              const SizedBox(width: 16),
              _legendDot(Colors.orange, 'High'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Critical'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildProviderModerationTable(AdminSafetyState safety) {
    final queue = safety.moderationQueue;

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Row(
                children: [
                  Icon(Icons.table_chart, color: Color(0xFF1A1A2E), size: 22),
                  SizedBox(width: 8),
                  Text('Provider Moderation Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                ],
              ),
              Row(
                children: [
                  _filterChip('ALL', 'ALL'),
                  const SizedBox(width: 6),
                  _filterChip('ACTIVE', 'Active'),
                  const SizedBox(width: 6),
                  _filterChip('SUSPENDED', 'Suspended'),
                  const SizedBox(width: 6),
                  _filterChip('BANNED', 'Banned'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Provider Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 1, child: Text('Risk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
              ],
            ),
          ),
          if (queue.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text('No providers found', style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ...queue.map((provider) => _providerRow(provider)),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _queueFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _queueFilter = value);
        ref.read(adminSafetyProvider.notifier).fetchModerationQueue(
              status: value == 'ALL' ? null : value,
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _providerRow(Map<String, dynamic> provider) {
    final providerId = provider['providerId'] ?? '';
    final fullName = provider['fullName'] ?? 'Unknown';
    final status = provider['status'] ?? 'ACTIVE';
    final riskScore = provider['riskScore'] as int?;
    final category = provider['category'] ?? '';
    final isOnline = provider['isOnline'] ?? false;

    final statusColor = status == 'SUSPENDED'
        ? Colors.orange
        : status == 'BANNED'
            ? Colors.red
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: statusColor.shade100,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0] : '?',
                    style: TextStyle(color: statusColor.shade700, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                    Text(
                      '$category${isOnline ? ' • Online' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor.shade700),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: riskScore != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskScore > 50 ? Colors.red.shade50 : riskScore > 20 ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$riskScore',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: riskScore > 50
                            ? Colors.red.shade700
                            : riskScore > 20
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                      ),
                    ),
                  )
                : Text('—', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'ACTIVE') ...[
                  _actionButton('Suspend', Colors.orange, () => _confirmAction('suspend', providerId, fullName)),
                  const SizedBox(width: 4),
                  _actionButton('Ban', Colors.red, () => _confirmAction('ban', providerId, fullName)),
                ] else ...[
                  _actionButton('Reinstate', Colors.green, () => _confirmAction('reinstate', providerId, fullName)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, MaterialColor color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          backgroundColor: color.withValues(alpha: 0.05),
          foregroundColor: color.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _confirmAction(String action, String providerId, String providerName) {
    final actionLabel = action == 'suspend' ? 'Suspend' : action == 'ban' ? 'Ban' : 'Reinstate';
    final color = action == 'ban' ? Colors.red : action == 'suspend' ? Colors.orange : Colors.green;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel Provider'),
        content: Text('Are you sure you want to $actionLabel $providerName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(adminSafetyProvider.notifier);
              bool success;
              if (action == 'suspend') {
                success = await notifier.suspendProvider(providerId);
              } else if (action == 'ban') {
                success = await notifier.banProvider(providerId);
              } else {
                success = await notifier.reinstateProvider(providerId);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '$actionLabel successful' : '$actionLabel failed'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: color),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
