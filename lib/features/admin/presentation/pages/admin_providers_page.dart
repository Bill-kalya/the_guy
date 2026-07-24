import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminProvidersPage extends ConsumerStatefulWidget {
  const AdminProvidersPage({super.key});

  @override
  ConsumerState<AdminProvidersPage> createState() => _AdminProvidersPageState();
}

class _AdminProvidersPageState extends ConsumerState<AdminProvidersPage> {
  String _statusFilter = 'All';
  final _searchController = TextEditingController();

  static const _statusOptions = ['All', 'Active', 'Pending', 'Suspended', 'Banned'];

  static const _providers = [
    (name: 'Grace Wanjiku', category: 'Plumbing', county: 'Nairobi', status: 'Active', rating: 4.8, jobs: 142),
    (name: 'James Mwangi', category: 'Electrical', county: 'Kiambu', status: 'Active', rating: 4.6, jobs: 98),
    (name: 'Peter Kamau', category: 'Painting', county: 'Nakuru', status: 'Pending', rating: 0.0, jobs: 0),
    (name: 'Alice Adhiambo', category: 'Cleaning', county: 'Mombasa', status: 'Suspended', rating: 3.2, jobs: 24),
    (name: 'David Ochieng', category: 'Carpentry', county: 'Kisumu', status: 'Active', rating: 4.9, jobs: 203),
    (name: 'Sarah Njeri', category: 'Plumbing', county: 'Nairobi', status: 'Active', rating: 4.4, jobs: 67),
    (name: 'Daniel Kipchoge', category: 'Electrical', county: 'Uasin Gishu', status: 'Active', rating: 4.7, jobs: 112),
    (name: 'Faith Wambui', category: 'Landscaping', county: 'Nairobi', status: 'Banned', rating: 2.1, jobs: 8),
  ];

  static const _pendingVerifications = [
    (name: 'Peter Kamau', category: 'Painting', doc: 'National ID', time: '2 hours ago'),
    (name: 'Lucy Akinyi', category: 'Tailoring', doc: 'Business Permit', time: '5 hours ago'),
    (name: 'Brian Cheruiyot', category: 'Plumbing', doc: 'National ID', time: '8 hours ago'),
  ];

  static const _categories = [
    (name: 'Plumbing', count: 342, color: Colors.blue),
    (name: 'Electrical', count: 289, color: Colors.orange),
    (name: 'Painting', count: 198, color: Colors.purple),
    (name: 'Carpentry', count: 176, color: Colors.brown),
    (name: 'Cleaning', count: 154, color: Colors.teal),
    (name: 'Landscaping', count: 112, color: Colors.green),
  ];

  static const _counties = [
    (name: 'Nairobi', count: 2847),
    (name: 'Kiambu', count: 1203),
    (name: 'Mombasa', count: 987),
    (name: 'Nakuru', count: 876),
    (name: 'Kisumu', count: 654),
    (name: 'Uasin Gishu', count: 543),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: 'providers',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title: 'Service Providers',
              subtitle: 'Manage provider registrations and verification',
            ),
            const SizedBox(height: 24),
            _buildKpiCards(),
            const SizedBox(height: 24),
            _buildCategoryCards(),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
            const SizedBox(height: 20),
            _buildMainContent(),
            const SizedBox(height: 24),
            _buildCountyDistribution(),
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
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Total Providers', value: '4,321', icon: Icons.build, color: AppColors.primary, subtitle: '+56 this week')),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Verified', value: '3,847', icon: Icons.verified, color: AppColors.success)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Pending Verification', value: '127', icon: Icons.pending, color: AppColors.warning)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Suspended/Banned', value: '38', icon: Icons.block, color: AppColors.error)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cardWidth = isWide ? (constraints.maxWidth - 60) / 6 : (constraints.maxWidth - 36) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((cat) {
            return SizedBox(
              width: cardWidth,
              child: AdminSectionCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 40,
                      decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                          Text('${cat.count} providers', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        AdminSearchBar(controller: _searchController, hintText: 'Search providers by name, category or county...'),
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
              Expanded(flex: 3, child: _buildProviderTable()),
              const SizedBox(width: 20),
              SizedBox(width: 300, child: Column(
                children: [
                  _buildPendingVerifications(),
                  const SizedBox(height: 20),
                  _buildQuickStats(),
                ],
              )),
            ],
          );
        }
        return Column(
          children: [
            _buildProviderTable(),
            const SizedBox(height: 20),
            _buildPendingVerifications(),
            const SizedBox(height: 20),
            _buildQuickStats(),
          ],
        );
      },
    );
  }

  Widget _buildProviderTable() {
    return AdminSectionCard(
      title: 'Provider Directory',
      titleIcon: Icons.list,
      child: Column(
        children: [
          const AdminTableHeader(
            columns: ['Provider', 'Category', 'County', 'Rating', 'Status'],
            flexes: [3, 2, 2, 1, 2],
          ),
          const SizedBox(height: 8),
          ..._providers.map((p) => _providerRow(p)),
        ],
      ),
    );
  }

  Widget _providerRow(dynamic p) {
    final statusColor = p.status == 'Active'
        ? AppColors.success
        : p.status == 'Suspended' || p.status == 'Banned'
            ? AppColors.error
            : AppColors.warning;
    final initials = p.name.toString().split(' ').map((w) => w[0]).take(2).join();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                    Text('${p.jobs} jobs completed', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
              child: Text(p.category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
            ),
          ),
          Expanded(flex: 2, child: Text(p.county, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
            flex: 1,
            child: p.rating > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(p.rating.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  )
                : Text('-', style: TextStyle(color: Colors.grey.shade400)),
          ),
          Expanded(flex: 2, child: AdminStatusBadge(label: p.status, color: statusColor)),
          _buildProviderActionMenu(p),
        ],
      ),
    );
  }

  Widget _buildProviderActionMenu(dynamic p) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
      onSelected: (value) => _handleProviderAction(value, p),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'view_profile', child: _ProviderMenuAction(icon: Icons.person, label: 'View Profile')),
        const PopupMenuItem(value: 'view_portfolio', child: _ProviderMenuAction(icon: Icons.photo_library, label: 'View Portfolio')),
        const PopupMenuItem(value: 'view_reviews', child: _ProviderMenuAction(icon: Icons.star, label: 'View Reviews')),
        const PopupMenuItem(value: 'view_analytics', child: _ProviderMenuAction(icon: Icons.analytics, label: 'View Analytics')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'view_as',
          child: _ProviderMenuAction(icon: Icons.remove_red_eye, label: 'View as Provider', isHighlight: true),
        ),
        if (p.status == 'Active')
          const PopupMenuItem(value: 'suspend', child: _ProviderMenuAction(icon: Icons.block, label: 'Suspend', isDestructive: true)),
      ],
    );
  }

  void _handleProviderAction(String action, dynamic p) async {
    switch (action) {
      case 'view_as':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('View as Provider'),
            content: Text('You will be viewing the app as ${p.name}. Your admin session will be restored when you return.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('View as ${p.name}', style: const TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          // TODO: Replace with real user ID from API
          final mockUserId = '00000000-0000-0000-0000-000000000002';
          await ref.read(authProvider.notifier).impersonateUser(mockUserId);
          if (mounted) context.go('/provider/home');
        }
        break;
      case 'suspend':
        // TODO: Implement suspend
        break;
      default:
        break;
    }
  }

  Widget _buildPendingVerifications() {
    return AdminSectionCard(
      title: 'Pending Verifications',
      titleIcon: Icons.how_to_reg,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Text('${_pendingVerifications.length} waiting', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning)),
      ),
      child: Column(
        children: _pendingVerifications.map((v) {
          final initials = v.name.toString().split(' ').map((w) => w[0]).take(2).join();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  child: Text(initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                      Text('${v.category} \u00b7 ${v.doc}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Text(v.time, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStats() {
    return AdminSectionCard(
      title: 'Provider Health',
      titleIcon: Icons.analytics,
      child: Column(
        children: [
          _statBar('Average Rating', '4.6 / 5', 92, AppColors.success),
          const SizedBox(height: 14),
          _statBar('Completion Rate', '87%', 87, AppColors.primary),
          const SizedBox(height: 14),
          _statBar('Repeat Customers', '64%', 64, Colors.purple),
          const SizedBox(height: 14),
          _statBar('Avg Response Time', '18 min', 78, Colors.teal),
        ],
      ),
    );
  }

  Widget _statBar(String label, String value, int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
          ],
        ),
        const SizedBox(height: 6),
        AdminProgressBar(value: percent.toDouble(), color: color),
      ],
    );
  }

  Widget _buildCountyDistribution() {
    final maxCount = _counties.first.count;
    return AdminSectionCard(
      title: 'Provider Distribution by County',
      titleIcon: Icons.location_on,
      child: Column(
        children: _counties.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(width: 110, child: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.count / maxCount,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary.withValues(alpha: 0.7)),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 50, child: Text('${c.count}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.right)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProviderMenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;
  final bool isDestructive;

  const _ProviderMenuAction({
    required this.icon,
    required this.label,
    this.isHighlight = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : isHighlight
            ? AppColors.primary
            : Colors.grey.shade700;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}
