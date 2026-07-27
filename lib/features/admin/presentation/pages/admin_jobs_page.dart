import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../providers/admin_jobs_provider.dart';

class AdminJobsPage extends ConsumerStatefulWidget {
  const AdminJobsPage({super.key});

  @override
  ConsumerState<AdminJobsPage> createState() => _AdminJobsPageState();
}

class _AdminJobsPageState extends ConsumerState<AdminJobsPage> {
  String _statusFilter = 'All';
  final _searchController = TextEditingController();

  static const _statusOptions = ['All', 'REQUESTED', 'MATCHING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminJobsProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminJobsProvider);

    return AdminShell(
      currentRoute: 'jobs',
      body: state.isLoading && state.summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminPageHeader(title: 'Jobs', subtitle: 'Track all jobs and activity on the platform'),
                  const SizedBox(height: 24),
                  _buildKpiCards(state),
                  const SizedBox(height: 24),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 20),
                  _buildJobTable(state),
                  const SizedBox(height: 24),
                  _buildJobFunnel(state),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCards(AdminJobsState state) {
    final s = (state.summary is Map<String, dynamic>) ? state.summary! : <String, dynamic>{};
    final activeJobs = s['activeJobs'] ?? 0;
    final completedJobs = s['completedJobs'] ?? 0;
    final cancelledJobs = s['cancelledJobs'] ?? 0;
    final totalJobs = s['totalJobs'] ?? 0;
    final jobsToday = s['jobsToday'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Total Jobs', value: _fmtInt(totalJobs), icon: Icons.work, color: AppColors.primary, subtitle: '$jobsToday today')),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Active', value: _fmtInt(activeJobs), icon: Icons.play_circle, color: AppColors.success)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Completed', value: _fmtInt(completedJobs), icon: Icons.check_circle, color: Colors.blue)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Cancelled', value: _fmtInt(cancelledJobs), icon: Icons.cancel, color: AppColors.error)),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        AdminSearchBar(
          controller: _searchController,
          hintText: 'Search jobs by service, customer or provider...',
          onChanged: (v) => ref.read(adminJobsProvider.notifier).refreshWithFilters(search: v),
        ),
        const SizedBox(height: 12),
        AdminFilterBar(
          options: _statusOptions,
          selected: _statusFilter,
          onSelected: (v) {
            setState(() => _statusFilter = v);
            ref.read(adminJobsProvider.notifier).refreshWithFilters(status: v);
          },
        ),
      ],
    );
  }

  Widget _buildJobTable(AdminJobsState state) {
    final jobsPage = state.jobs ?? {};
    final content = jobsPage['content'] as List<dynamic>? ?? [];

    return AdminSectionCard(
      title: 'Job Feed',
      titleIcon: Icons.feed,
      child: content.isEmpty
          ? const AdminEmptyState(icon: Icons.work, title: 'No jobs found', subtitle: 'Job data will appear here')
          : Column(
              children: [
                const AdminTableHeader(columns: ['Job', 'Customer', 'Provider', 'Amount', 'Status'], flexes: [3, 2, 2, 2, 2]),
                const SizedBox(height: 8),
                ...content.where((j) => j != null).take(10).map((j) => _jobRow(j)),
              ],
            ),
    );
  }

  Widget _jobRow(dynamic j) {
    final category = j['serviceCategory'] ?? 'Unknown';
    final customer = j['customerName'] ?? 'Unknown';
    final provider = j['providerName'] ?? 'Unassigned';
    final finalPrice = j['finalPrice'];
    final status = j['status'] ?? 'UNKNOWN';
    final createdAt = j['createdAt'] ?? '';

    final statusWidget = _statusBadge(status.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                Text(_timeAgo(createdAt.toString()), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(customer.toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: Text(provider.toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
            flex: 2,
            child: finalPrice != null
                ? Text(_fmtMoney(finalPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))
                : Text('-', style: TextStyle(color: Colors.grey.shade400)),
          ),
          Expanded(flex: 2, child: statusWidget),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case 'COMPLETED': return AdminStatusBadge.completed();
      case 'CANCELLED': return AdminStatusBadge.cancelled();
      case 'IN_PROGRESS': return AdminStatusBadge.custom('In Progress', Colors.blue);
      case 'ASSIGNED': return AdminStatusBadge.custom('Assigned', Colors.teal);
      case 'MATCHING': return AdminStatusBadge.custom('Matching', Colors.orange);
      case 'REQUESTED': return AdminStatusBadge.custom('Requested', AppColors.warning);
      default: return AdminStatusBadge.custom(status, Colors.grey);
    }
  }

  Widget _buildJobFunnel(AdminJobsState state) {
    final s = (state.summary is Map<String, dynamic>) ? state.summary! : <String, dynamic>{};
    final total = (s['totalJobs'] ?? 0) as num;
    final completed = (s['completedJobs'] ?? 0) as num;
    final active = (s['activeJobs'] ?? 0) as num;
    final cancelled = (s['cancelledJobs'] ?? 0) as num;
    final maxVal = total.toDouble().clamp(1, double.infinity);

    return AdminSectionCard(
      title: 'Job Funnel',
      titleIcon: Icons.filter_alt,
      child: Column(
        children: [
          _funnelBar('Total', total.toInt(), maxVal.toInt(), AppColors.primary),
          _funnelBar('Active', active.toInt(), maxVal.toInt(), Colors.orange),
          _funnelBar('Completed', completed.toInt(), maxVal.toInt(), AppColors.success),
          _funnelBar('Cancelled', cancelled.toInt(), maxVal.toInt(), AppColors.error),
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
                value: max > 0 ? (value / max).clamp(0.0, 1.0) : 0,
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

  String _fmtInt(dynamic v) {
    final n = v is num ? v.toInt() : 0;
    return n.toString();
  }

  String _fmtMoney(dynamic v) {
    final n = v is num ? v.toDouble() : 0.0;
    if (n >= 1000) return 'KES ${(n / 1000).toStringAsFixed(1)}K';
    return 'KES ${n.toStringAsFixed(0)}';
  }

  String _timeAgo(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 30) return '${diff.inDays}d ago';
      return '${(diff.inDays / 30).floor()}mo ago';
    } catch (_) {
      return '';
    }
  }
}
