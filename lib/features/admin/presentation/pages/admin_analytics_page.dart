import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';
import '../../../../core/themes/colors.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _counterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: 'analytics',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildLiveKPIs(),
            const SizedBox(height: 28),
            _buildRevenueSparkline(),
            const SizedBox(height: 28),
            _buildFunnelAndHeatmap(),
            const SizedBox(height: 28),
            _buildPeakHoursAndCategories(),
            const SizedBox(height: 28),
            _buildProviderResponseDistribution(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              Text(
                'Platform performance at a glance',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
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
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── ANIMATED KPI CARDS ─────────────────────────────────────────
  Widget _buildLiveKPIs() {
    return AnimatedBuilder(
      animation: _counterAnimation,
      builder: (context, _) {
        return Row(
          children: [
            _KpiCard(
              label: 'Total Users',
              value: (_counterAnimation.value * 12847).toInt(),
              suffix: '',
              icon: Icons.people_rounded,
              color: const Color(0xFF5C6BC0),
              trend: 12.3,
            ),
            const SizedBox(width: 16),
            _KpiCard(
              label: 'Active Providers',
              value: (_counterAnimation.value * 3421).toInt(),
              suffix: '',
              icon: Icons.handyman_rounded,
              color: const Color(0xFF26A69A),
              trend: 8.7,
            ),
            const SizedBox(width: 16),
            _KpiCard(
              label: 'Bookings (30d)',
              value: (_counterAnimation.value * 8942).toInt(),
              suffix: '',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFFEF6C00),
              trend: 23.1,
            ),
            const SizedBox(width: 16),
            _KpiCard(
              label: 'GMV (30d)',
              value: (_counterAnimation.value * 8.4).toStringAsFixed(1),
              suffix: 'M',
              prefix: 'KES ',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF43A047),
              trend: 15.6,
            ),
          ],
        );
      },
    );
  }

  // ─── REVENUE SPARKLINE ──────────────────────────────────────────
  Widget _buildRevenueSparkline() {
    return _SectionCard(
      title: 'Revenue Trend',
      subtitle: 'Last 30 days',
      trailing: _LegendRow(items: [
        _LegendItem('GMV', const Color(0xFF42A5F5)),
        _LegendItem('Revenue', const Color(0xFF66BB6A)),
        _LegendItem('Payouts', const Color(0xFFFFA726)),
      ]),
      height: 240,
      child: AnimatedBuilder(
        animation: _counterAnimation,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _SparklinePainter(
              progress: _counterAnimation.value,
              series: [
                _SparklineData(
                  [20, 45, 30, 60, 50, 75, 80, 65, 90, 85, 95, 70, 88, 92, 100, 85, 78, 95, 110, 105, 120, 115, 130, 125, 140, 135, 145, 150, 155, 160],
                  const Color(0xFF42A5F5),
                ),
                _SparklineData(
                  [10, 25, 20, 40, 35, 50, 55, 45, 60, 58, 65, 50, 60, 63, 68, 58, 54, 65, 75, 72, 82, 78, 88, 85, 95, 92, 98, 102, 105, 108],
                  const Color(0xFF66BB6A),
                ),
                _SparklineData(
                  [5, 15, 12, 25, 22, 32, 35, 28, 38, 36, 42, 32, 38, 40, 44, 37, 34, 42, 50, 48, 55, 52, 60, 58, 65, 63, 68, 70, 72, 75],
                  const Color(0xFFFFA726),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── FUNNEL + HEATMAP ───────────────────────────────────────────
  Widget _buildFunnelAndHeatmap() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _SectionCard(
            title: 'Booking Funnel',
            subtitle: 'Conversion from search to completion',
            height: 340,
            child: AnimatedBuilder(
              animation: _counterAnimation,
              builder: (context, _) {
                return _BookingFunnel(progress: _counterAnimation.value);
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _SectionCard(
            title: 'Demand by City',
            subtitle: 'Booking volume across Kenya',
            height: 340,
            child: AnimatedBuilder(
              animation: _counterAnimation,
              builder: (context, _) {
                return _CityHeatmap(progress: _counterAnimation.value);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── PEAK HOURS + CATEGORIES ────────────────────────────────────
  Widget _buildPeakHoursAndCategories() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SectionCard(
            title: 'Peak Hours',
            subtitle: 'Bookings by hour of day',
            height: 280,
            child: AnimatedBuilder(
              animation: _counterAnimation,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _PeakHoursPainter(progress: _counterAnimation.value),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SectionCard(
            title: 'Top Categories',
            subtitle: 'Service demand breakdown',
            height: 280,
            child: AnimatedBuilder(
              animation: _counterAnimation,
              builder: (context, _) {
                return _CategoryBreakdown(progress: _counterAnimation.value);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── PROVIDER RESPONSE DISTRIBUTION ──────────────────────────────
  Widget _buildProviderResponseDistribution() {
    return _SectionCard(
      title: 'Provider Response Time',
      subtitle: 'Distribution across all providers (minutes)',
      height: 200,
      child: AnimatedBuilder(
        animation: _counterAnimation,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _HistogramPainter(
              progress: _counterAnimation.value,
              data: [5, 18, 42, 65, 88, 72, 45, 28, 15, 8],
              labels: ['<1', '1-3', '3-5', '5-8', '8-12', '12-15', '15-20', '20-30', '30-45', '45+'],
              barColor: const Color(0xFF5C6BC0),
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
  final double trend;

  const _KpiCard({
    required this.label,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    required this.icon,
    required this.color,
    required this.trend,
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
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward, size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 2),
                      Text(
                        '${trend.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$prefix${_formatValue(value)}$suffix',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
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

  const _SectionCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
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
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: child,
          )),
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
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3)),
            ),
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
// BOOKING FUNNEL
// ═══════════════════════════════════════════════════════════════════

class _BookingFunnel extends StatelessWidget {
  final double progress;
  const _BookingFunnel({required this.progress});

  @override
  Widget build(BuildContext context) {
    final stages = [
      _FunnelStage('Search', 10000, const Color(0xFF42A5F5)),
      _FunnelStage('View Profile', 7200, const Color(0xFF5C6BC0)),
      _FunnelStage('Request Quote', 4800, const Color(0xFFAB47BC)),
      _FunnelStage('Accept Job', 3100, const Color(0xFFFF7043)),
      _FunnelStage('Completed', 2400, const Color(0xFF66BB6A)),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stages.map((stage) {
        final fraction = stage.value / stages.first.value;
        final animatedFraction = fraction * progress;
        final convRate = stage == stages.first
            ? 100.0
            : (stage.value / stages[stages.indexOf(stage) - 1].value) * 100;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  stage.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: animatedFraction,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              stage.color.withValues(alpha: 0.7),
                              stage.color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          _formatCount((stage.value * progress).toInt()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 52,
                child: Text(
                  '${convRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stage == stages.first ? Colors.grey : stage.color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _FunnelStage {
  final String label;
  final int value;
  final Color color;
  const _FunnelStage(this.label, this.value, this.color);
}

// ═══════════════════════════════════════════════════════════════════
// CITY HEATMAP
// ═══════════════════════════════════════════════════════════════════

class _CityHeatmap extends StatelessWidget {
  final double progress;
  const _CityHeatmap({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cities = [
      _CityData('Nairobi', 0.95, 4200),
      _CityData('Mombasa', 0.72, 2800),
      _CityData('Kisumu', 0.58, 1900),
      _CityData('Nakuru', 0.45, 1400),
      _CityData('Eldoret', 0.38, 1100),
      _CityData('Thika', 0.30, 850),
      _CityData('Nyeri', 0.22, 620),
      _CityData('Malindi', 0.18, 480),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cities.map((city) {
        final animatedIntensity = city.intensity * progress;
        final color = _heatColor(animatedIntensity);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                child: Text(
                  city.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedIntensity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.5),
                              color,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text(
                  _formatCount((city.count * progress).toInt()),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _heatColor(double intensity) {
    if (intensity > 0.7) return const Color(0xFFE53935);
    if (intensity > 0.5) return const Color(0xFFFF9800);
    if (intensity > 0.3) return const Color(0xFFFFC107);
    return const Color(0xFF66BB6A);
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _CityData {
  final String name;
  final double intensity;
  final int count;
  const _CityData(this.name, this.intensity, this.count);
}

// ═══════════════════════════════════════════════════════════════════
// CATEGORY BREAKDOWN
// ═══════════════════════════════════════════════════════════════════

class _CategoryBreakdown extends StatelessWidget {
  final double progress;
  const _CategoryBreakdown({required this.progress});

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CatItem('Plumbing', 0.92, const Color(0xFF42A5F5)),
      _CatItem('Electrical', 0.78, const Color(0xFFFFA726)),
      _CatItem('Cleaning', 0.65, const Color(0xFF66BB6A)),
      _CatItem('Carpentry', 0.52, const Color(0xFFAB47BC)),
      _CatItem('Moving', 0.40, const Color(0xFFEF5350)),
      _CatItem('Painting', 0.30, const Color(0xFF26A69A)),
      _CatItem('Tutoring', 0.22, const Color(0xFF5C6BC0)),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: categories.map((cat) {
        final animatedWidth = cat.ratio * progress;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  cat.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 20,
                    color: Colors.grey.shade50,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cat.color.withValues(alpha: 0.6),
                              cat.color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '${(animatedWidth * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cat.color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CatItem {
  final String name;
  final double ratio;
  final Color color;
  const _CatItem(this.name, this.ratio, this.color);
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
    final maxVal = series.expand((s) => s.values).reduce(max);
    final padTop = 16.0;
    final padBottom = 28.0;
    final padLeft = 4.0;
    final padRight = 4.0;
    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    // Grid lines
    final gridPaint = Paint()..color = Colors.grey.shade100..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padTop + (chartH / 4) * i;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    for (final data in series) {
      final points = <Offset>[];
      final len = data.values.length;
      for (int i = 0; i < len; i++) {
        final x = padLeft + (chartW / (len - 1)) * i;
        final normalizedVal = data.values[i] / maxVal;
        final y = padTop + chartH - (normalizedVal * chartH * progress);
        points.add(Offset(x, y));
      }

      if (points.length < 2) continue;

      // Fill area
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
          colors: [
            data.color.withValues(alpha: 0.15),
            data.color.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );

      // Line
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
        Paint()
          ..color = data.color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // End dot
      final lastPoint = points.last;
      canvas.drawCircle(lastPoint, 4, Paint()..color = data.color);
      canvas.drawCircle(lastPoint, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.progress != progress;
}

class _PeakHoursPainter extends CustomPainter {
  final double progress;
  _PeakHoursPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Hours 6am to 10pm
    final data = [2, 5, 12, 18, 22, 25, 28, 30, 26, 20, 15, 18, 24, 28, 25, 20, 14, 8, 4];
    final maxVal = data.reduce(max).toDouble();
    final padTop = 12.0;
    final padBottom = 32.0;
    final padLeft = 8.0;
    final padRight = 8.0;
    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;
    final barW = (chartW / data.length) * 0.65;
    final gap = (chartW / data.length) * 0.35;

    for (int i = 0; i < data.length; i++) {
      final normalizedH = (data[i] / maxVal) * chartH * progress;
      final x = padLeft + (chartW / data.length) * i + gap / 2;
      final y = padTop + chartH - normalizedH;

      final isPeak = data[i] >= 25;
      final color = isPeak ? const Color(0xFFEF6C00) : const Color(0xFF5C6BC0);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, normalizedH),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rrect,
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.6)],
        ).createShader(Rect.fromLTWH(x, y, barW, normalizedH)),
      );

      // Hour label
      final hour = 6 + i;
      final tp = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, padTop + chartH + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _PeakHoursPainter old) => old.progress != progress;
}

class _HistogramPainter extends CustomPainter {
  final double progress;
  final List<int> data;
  final List<String> labels;
  final Color barColor;

  _HistogramPainter({
    required this.progress,
    required this.data,
    required this.labels,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.reduce(max).toDouble();
    final padTop = 16.0;
    final padBottom = 32.0;
    final padLeft = 8.0;
    final padRight = 8.0;
    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;
    final barW = (chartW / data.length) * 0.7;
    final gap = (chartW / data.length) * 0.3;

    for (int i = 0; i < data.length; i++) {
      final normalizedH = (data[i] / maxVal) * chartH * progress;
      final x = padLeft + (chartW / data.length) * i + gap / 2;
      final y = padTop + chartH - normalizedH;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, normalizedH),
        const Radius.circular(3),
      );

      final intensity = data[i] / maxVal;
      final color = Color.lerp(barColor.withValues(alpha: 0.4), barColor, intensity)!;

      canvas.drawRRect(rrect, Paint()..color = color);

      // Value on top
      if (normalizedH > 10) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${(data[i] * progress).toInt()}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, y - 14));
      }

      // Label
      final lp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lp.paint(canvas, Offset(x + barW / 2 - lp.width / 2, padTop + chartH + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter old) => old.progress != progress;
}
