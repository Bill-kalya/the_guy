import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/admin_shell.dart';
import '../../../../core/themes/colors.dart';
import '../../providers/admin_overview_provider.dart';
import '../../providers/admin_finance_provider.dart';

class AdminAnalyticsPage extends ConsumerStatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  ConsumerState<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends ConsumerState<AdminAnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _counterAnimation = CurvedAnimation(parent: _counterController, curve: Curves.easeOutCubic);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    Future.microtask(() {
      ref.read(adminOverviewProvider.notifier).loadAll();
      ref.read(adminFinanceProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _counterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(adminOverviewProvider);
    final finance = ref.watch(adminFinanceProvider);

    return AdminShell(
      currentRoute: 'analytics',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildLiveKPIs(overview),
            const SizedBox(height: 28),
            _buildRevenueSparkline(finance),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text('Platform performance at a glance', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _pulseAnimation.value,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  ),
                  const SizedBox(width: 8),
                  const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1.2)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveKPIs(AdminOverviewState overview) {
    final users = overview.userSummary ?? {};
    final providers = overview.providerSummary ?? {};
    final jobs = overview.jobsSummary ?? {};
    final finance = overview.financeSummary ?? {};

    final totalUsers = users['totalUsers'] ?? 0;
    final activeProviders = providers['onlineNow'] ?? 0;
    final totalJobs = jobs['totalJobs'] ?? 0;
    final gmv = finance['totalGMV'] ?? 0.0;

    return AnimatedBuilder(
      animation: _counterAnimation,
      builder: (context, _) {
        return Row(
          children: [
            _KpiCard(
              label: 'Total Users',
              value: (_counterAnimation.value * (totalUsers as num).toDouble()).toInt(),
              icon: Icons.people_rounded,
              color: const Color(0xFF5C6BC0),
            ),
            const SizedBox(width: 16),
            _KpiCard(
              label: 'Active Providers',
              value: (_counterAnimation.value * (activeProviders as num).toDouble()).toInt(),
              icon: Icons.handyman_rounded,
              color: const Color(0xFF26A69A),
            ),
            const SizedBox(width: 16),
            _KpiCard(
              label: 'Total Jobs',
              value: (_counterAnimation.value * (totalJobs as num).toDouble()).toInt(),
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFFEF6C00),
            ),
            const SizedBox(width: 16),
            _KpiCard(
              label: 'Total GMV',
              value: (_counterAnimation.value * (gmv as num).toDouble() / 1000000).toStringAsFixed(1),
              suffix: 'M',
              prefix: 'KES ',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF43A047),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueSparkline(AdminFinanceState finance) {
    final trend = finance.revenueTrend;

    List<double> gmvData = [];
    List<double> revenueData = [];
    List<double> payoutData = [];

    for (final entry in trend) {
      gmvData.add((entry['gmv'] ?? 0.0).toDouble());
      revenueData.add((entry['revenue'] ?? 0.0).toDouble());
      payoutData.add((entry['payouts'] ?? 0.0).toDouble());
    }

    if (gmvData.isEmpty) {
      gmvData = List.filled(30, 0.0);
      revenueData = List.filled(30, 0.0);
      payoutData = List.filled(30, 0.0);
    }

    return _SectionCard(
      title: 'Revenue Trend',
      subtitle: 'Last 30 days',
      trailing: _LegendRow(items: [
        _LegendItem('GMV', const Color(0xFF42A5F5)),
        _LegendItem('Revenue', const Color(0xFF66BB6A)),
        _LegendItem('Payouts', const Color(0xFFFFA726)),
      ]),
      height: 280,
      child: AnimatedBuilder(
        animation: _counterAnimation,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _SparklinePainter(
              progress: _counterAnimation.value,
              series: [
                _SparklineData(gmvData, const Color(0xFF42A5F5)),
                _SparklineData(revenueData, const Color(0xFF66BB6A)),
                _SparklineData(payoutData, const Color(0xFFFFA726)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// COMPONENTS
// ═══════════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String label;
  final dynamic value;
  final String suffix;
  final String prefix;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              '$prefix${_formatValue(value)}$suffix',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1, height: 1.1),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic v) {
    if (v is int) {
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toString();
    }
    return v.toString();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final double? height;
  final Widget child;

  const _SectionCard({required this.title, required this.subtitle, this.trailing, this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: child)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final List<_LegendItem> items;
  const _LegendRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(item.label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      )).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}

// ═══════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════

class _SparklineData {
  final List<double> values;
  final Color color;
  const _SparklineData(this.values, this.color);
}

class _SparklinePainter extends CustomPainter {
  final double progress;
  final List<_SparklineData> series;

  _SparklinePainter({required this.progress, required this.series});

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = series.expand((s) => s.values).toList();
    final maxVal = allValues.isEmpty ? 1.0 : allValues.reduce(max);
    if (maxVal == 0) return;
    final padTop = 16.0;
    final padBottom = 28.0;
    final padLeft = 4.0;
    final padRight = 4.0;
    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    final gridPaint = Paint()..color = Colors.grey.shade100..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padTop + (chartH / 4) * i;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    for (final data in series) {
      final points = <Offset>[];
      final len = data.values.length;
      if (len < 2) continue;
      for (int i = 0; i < len; i++) {
        final x = padLeft + (chartW / (len - 1)) * i;
        final normalizedVal = data.values[i] / maxVal;
        final y = padTop + chartH - (normalizedVal * chartH * progress);
        points.add(Offset(x, y));
      }

      final areaPath = Path();
      areaPath.moveTo(points.first.dx, padTop + chartH);
      for (int i = 0; i < points.length; i++) {
        if (i == 0) {
          areaPath.lineTo(points[i].dx, points[i].dy);
        } else {
          final prev = points[i - 1];
          final curr = points[i];
          final cpX = (prev.dx + curr.dx) / 2;
          areaPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
        }
      }
      areaPath.lineTo(points.last.dx, padTop + chartH);
      areaPath.close();

      canvas.drawPath(
        areaPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [data.color.withValues(alpha: 0.15), data.color.withValues(alpha: 0.01)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );

      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cpX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }

      canvas.drawPath(
        linePath,
        Paint()..color = data.color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
      );

      final lastPoint = points.last;
      canvas.drawCircle(lastPoint, 4, Paint()..color = data.color);
      canvas.drawCircle(lastPoint, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.progress != progress;
}
