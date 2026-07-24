import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';

class AdminJobsPage extends StatefulWidget {
  const AdminJobsPage({super.key});

  @override
  State<AdminJobsPage> createState() => _AdminJobsPageState();
}

class _AdminJobsPageState extends State<AdminJobsPage> {
  String _statusFilter = 'All';
  final _searchController = TextEditingController();

  static const _statusOptions = ['All', 'Active', 'Completed', 'Cancelled', 'Disputed'];

  static const _jobs = [
    (title: 'Plumbing Repair', customer: 'John Doe', provider: 'Grace Wanjiku', county: 'Nairobi', status: 'Active', amount: 'KES 4,500', time: '2h ago'),
    (title: 'Electrical Wiring', customer: 'Mary Smith', provider: 'James Mwangi', county: 'Kiambu', status: 'Completed', amount: 'KES 8,200', time: '5h ago'),
    (title: 'House Painting', customer: 'Sarah Njeri', provider: 'Peter Kamau', county: 'Nakuru', status: 'Disputed', amount: 'KES 12,000', time: '8h ago'),
    (title: 'Furniture Assembly', customer: 'David Ochieng', provider: 'Alice Adhiambo', county: 'Kisumu', status: 'Cancelled', amount: 'KES 3,500', time: '1d ago'),
    (title: 'Deep Cleaning', customer: 'Grace Wanjiku', provider: 'David Ochieng', county: 'Mombasa', status: 'Completed', amount: 'KES 6,000', time: '1d ago'),
    (title: 'Garden Landscaping', customer: 'Peter Kamau', provider: 'Daniel Kipchoge', county: 'Nairobi', status: 'Active', amount: 'KES 15,000', time: '2d ago'),
    (title: 'Tailoring Work', customer: 'Alice Adhiambo', provider: 'Sarah Njeri', county: 'Nairobi', status: 'Completed', amount: 'KES 2,800', time: '3d ago'),
    (title: 'Roof Repair', customer: 'James Mwangi', provider: 'Faith Wambui', county: 'Uasin Gishu', status: 'Completed', amount: 'KES 22,000', time: '3d ago'),
  ];

  static const _recentActivity = [
    (title: 'Job Completed', detail: 'Electrical Wiring in Kiambu', time: '30 min ago', color: AppColors.success, icon: Icons.check_circle),
    (title: 'Dispute Filed', detail: 'House Painting in Nakuru', time: '2 hours ago', color: AppColors.error, icon: Icons.report),
    (title: 'New Booking', detail: 'Garden Landscaping in Nairobi', time: '3 hours ago', color: AppColors.primary, icon: Icons.add_circle),
    (title: 'Payment Released', detail: 'Deep Cleaning in Mombasa', time: '5 hours ago', color: AppColors.success, icon: Icons.payments),
    (title: 'Job Cancelled', detail: 'Furniture Assembly in Kisumu', time: '8 hours ago', color: Colors.orange, icon: Icons.cancel),
  ];

  static const _topServices = [
    (name: 'Plumbing', jobs: 1247),
    (name: 'Electrical', jobs: 987),
    (name: 'Painting', jobs: 654),
    (name: 'Cleaning', jobs: 543),
    (name: 'Carpentry', jobs: 432),
  ];

  static const _jobsByCounty = [
    (name: 'Nairobi', jobs: 2847),
    (name: 'Kiambu', jobs: 1543),
    (name: 'Mombasa', jobs: 1123),
    (name: 'Nakuru', jobs: 876),
    (name: 'Kisumu', jobs: 654),
    (name: 'Uasin Gishu', jobs: 432),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: 'jobs',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title: 'Jobs',
              subtitle: 'Track all jobs and activity on the platform',
            ),
            const SizedBox(height: 24),
            _buildKpiCards(),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
            const SizedBox(height: 20),
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
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Active Jobs', value: '892', icon: Icons.work, color: AppColors.primary, subtitle: '+34 today')),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Completed Today', value: '156', icon: Icons.check_circle, color: AppColors.success)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Cancelled', value: '23', icon: Icons.cancel, color: Colors.orange)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Disputes', value: '7', icon: Icons.gavel, color: AppColors.error)),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        AdminSearchBar(controller: _searchController, hintText: 'Search jobs by service, customer or provider...'),
        const SizedBox(height: 12),
        AdminFilterBar(options: _statusOptions, selected: _statusFilter, onSelected: (v) => setState(() => _statusFilter = v)),
      ],
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildJobTable()),
              const SizedBox(width: 20),
              SizedBox(width: 280, child: Column(
                children: [
                  _buildRecentActivityPanel(),
                  const SizedBox(height: 20),
                  _buildMostRequestedServices(),
                ],
              )),
            ],
          );
        }
        return Column(
          children: [
            _buildJobTable(),
            const SizedBox(height: 20),
            _buildRecentActivityPanel(),
            const SizedBox(height: 20),
            _buildMostRequestedServices(),
          ],
        );
      },
    );
  }

  Widget _buildJobTable() {
    return AdminSectionCard(
      title: 'Job Feed',
      titleIcon: Icons.feed,
      child: Column(
        children: [
          const AdminTableHeader(
            columns: ['Job', 'Customer', 'Provider', 'Amount', 'Status'],
            flexes: [3, 2, 2, 2, 2],
          ),
          const SizedBox(height: 8),
          ..._jobs.map((j) => _jobRow(j)),
        ],
      ),
    );
  }

  Widget _jobRow(dynamic j) {
    final statusWidget = j.status == 'Active'
        ? AdminStatusBadge.active()
        : j.status == 'Completed'
            ? AdminStatusBadge.completed()
            : j.status == 'Cancelled'
                ? AdminStatusBadge.cancelled()
                : AdminStatusBadge.disputed();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(j.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                Text('${j.county} \u00b7 ${j.time}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(j.customer, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: Text(j.provider, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
            flex: 2,
            child: Text(j.amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          ),
          Expanded(flex: 2, child: statusWidget),
        ],
      ),
    );
  }

  Widget _buildRecentActivityPanel() {
    return AdminSectionCard(
      title: 'Recent Activity',
      titleIcon: Icons.timeline,
      child: Column(
        children: _recentActivity.map((a) => AdminActivityTile(
          icon: a.icon,
          color: a.color,
          title: a.title,
          subtitle: a.detail,
          time: a.time,
        )).toList(),
      ),
    );
  }

  Widget _buildMostRequestedServices() {
    final maxJobs = _topServices.first.jobs;
    return AdminSectionCard(
      title: 'Most Requested Services',
      titleIcon: Icons.trending_up,
      child: Column(
        children: _topServices.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.primary : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: i == 0 ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: s.jobs / maxJobs,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary.withValues(alpha: 0.6)),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('${s.jobs}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildJobsByCounty()),
              const SizedBox(width: 20),
              Expanded(child: _buildJobFunnel()),
            ],
          );
        }
        return Column(
          children: [
            _buildJobsByCounty(),
            const SizedBox(height: 20),
            _buildJobFunnel(),
          ],
        );
      },
    );
  }

  Widget _buildJobsByCounty() {
    return AdminSectionCard(
      title: 'Jobs by County',
      titleIcon: Icons.location_on,
      child: AdminMiniBarChart(
        data: _jobsByCounty.map((c) => MapEntry(c.name, c.jobs.toDouble())).toList(),
        barColor: AppColors.primary,
      ),
    );
  }

  Widget _buildJobFunnel() {
    return AdminSectionCard(
      title: 'Job Funnel',
      titleIcon: Icons.filter_alt,
      child: Column(
        children: [
          _funnelBar('Created', 2847, 2847, AppColors.primary),
          _funnelBar('Matched', 2654, 2847, AppColors.secondary),
          _funnelBar('In Progress', 1876, 2847, Colors.orange),
          _funnelBar('Completed', 1654, 2847, AppColors.success),
          _funnelBar('Disputed', 76, 2847, AppColors.error),
        ],
      ),
    );
  }

  Widget _funnelBar(String label, int value, int max, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / max,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
