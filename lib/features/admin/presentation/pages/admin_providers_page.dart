import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_providers_provider.dart';

class AdminProvidersPage extends ConsumerStatefulWidget {
  const AdminProvidersPage({super.key});

  @override
  ConsumerState<AdminProvidersPage> createState() => _AdminProvidersPageState();
}

class _AdminProvidersPageState extends ConsumerState<AdminProvidersPage> {
  String _statusFilter = 'All';
  final _searchController = TextEditingController();

  static const _statusOptions = ['All', 'ACTIVE', 'SUSPENDED', 'BANNED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvidersProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvidersProvider);

    return AdminShell(
      currentRoute: 'providers',
      body: state.isLoading && state.summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminPageHeader(title: 'Service Providers', subtitle: 'Manage provider registrations and verification'),
                  const SizedBox(height: 24),
                  _buildKpiCards(state),
                  const SizedBox(height: 24),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 20),
                  _buildMainContent(state),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCards(AdminProvidersState state) {
    final s = (state.summary is Map<String, dynamic>) ? state.summary! : <String, dynamic>{};
    final totalProviders = s['totalProviders'] ?? 0;
    final onlineNow = s['onlineNow'] ?? 0;
    final pendingVerification = s['pendingVerification'] ?? 0;
    final avgRating = s['avgRating'] ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Total Providers', value: _fmtInt(totalProviders), icon: Icons.build, color: AppColors.primary)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Online Now', value: _fmtInt(onlineNow), icon: Icons.circle, color: AppColors.success)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Pending Verification', value: _fmtInt(pendingVerification), icon: Icons.pending, color: AppColors.warning)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Avg Rating', value: '${(avgRating as num).toDouble().toStringAsFixed(1)}', icon: Icons.star, color: Colors.amber)),
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
          hintText: 'Search providers by name or category...',
          onChanged: (v) => ref.read(adminProvidersProvider.notifier).refreshWithFilters(search: v),
        ),
        const SizedBox(height: 12),
        AdminFilterBar(
          options: _statusOptions,
          selected: _statusFilter,
          onSelected: (v) {
            setState(() => _statusFilter = v);
            ref.read(adminProvidersProvider.notifier).refreshWithFilters(status: v);
          },
        ),
      ],
    );
  }

  Widget _buildMainContent(AdminProvidersState state) {
    final providersPage = state.providers ?? {};
    final content = providersPage['content'] as List<dynamic>? ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildProviderTable(content)),
              const SizedBox(width: 20),
              SizedBox(width: 300, child: _buildProviderHealth(state)),
            ],
          );
        }
        return Column(
          children: [
            _buildProviderTable(content),
            const SizedBox(height: 20),
            _buildProviderHealth(state),
          ],
        );
      },
    );
  }

  Widget _buildProviderTable(List<dynamic> providers) {
    return AdminSectionCard(
      title: 'Provider Directory',
      titleIcon: Icons.list,
      child: providers.isEmpty
          ? const AdminEmptyState(icon: Icons.people, title: 'No providers found', subtitle: 'Provider data will appear here')
          : Column(
              children: [
                const AdminTableHeader(columns: ['Provider', 'Rating', 'Jobs', 'Status'], flexes: [4, 2, 2, 2]),
                const SizedBox(height: 8),
                ...providers.map((p) => _providerRow(p)),
              ],
            ),
    );
  }

  Widget _providerRow(dynamic p) {
    final name = p['fullName'] ?? 'Unknown';
    final rating = (p['ratingAvg'] ?? 0.0) as num;
    final jobsCompleted = p['jobsCompleted'] ?? 0;
    final isOnline = p['isOnline'] ?? false;
    final status = isOnline ? 'ACTIVE' : 'OFFLINE';
    final statusColor = isOnline ? AppColors.success : Colors.grey;
    final initials = name.toString().split(' ').map((w) => w[0]).take(2).join();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
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
                    Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                    Text(p['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: rating > 0
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ])
                : Text('-', style: TextStyle(color: Colors.grey.shade400)),
          ),
          Expanded(flex: 2, child: Text('$jobsCompleted', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: AdminStatusBadge(label: status, color: statusColor)),
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
        const PopupMenuItem(value: 'view_as', child: _ProviderMenuAction(icon: Icons.remove_red_eye, label: 'View as Provider', isHighlight: true)),
      ],
    );
  }

  void _handleProviderAction(String action, dynamic p) async {
    if (action == 'view_as') {
      final name = p['fullName'] ?? 'this provider';
      final userId = p['userId'] ?? '';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('View as Provider'),
          content: Text('You will be viewing the app as $name. Your admin session will be restored when you return.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('View as $name', style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted && userId.toString().isNotEmpty) {
        await ref.read(authProvider.notifier).impersonateUser(userId.toString());
        if (mounted) context.go('/provider/home');
      }
    }
  }

  Widget _buildProviderHealth(AdminProvidersState state) {
    final s = (state.summary is Map<String, dynamic>) ? state.summary! : <String, dynamic>{};
    final avgRating = (s['avgRating'] ?? 0.0) as num;

    return AdminSectionCard(
      title: 'Provider Health',
      titleIcon: Icons.analytics,
      child: Column(
        children: [
          _statBar('Average Rating', '${avgRating.toStringAsFixed(1)} / 5', (avgRating / 5 * 100).round(), AppColors.success),
          const SizedBox(height: 14),
          _statBar('Online Now', '${s['onlineNow'] ?? 0}', 0, AppColors.primary),
          const SizedBox(height: 14),
          _statBar('Pending Verification', '${s['pendingVerification'] ?? 0}', 0, AppColors.warning),
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
        if (percent > 0) ...[
          const SizedBox(height: 6),
          AdminProgressBar(value: percent.toDouble(), color: color),
        ],
      ],
    );
  }

  String _fmtInt(dynamic v) {
    final n = v is num ? v.toInt() : 0;
    return n.toString();
  }
}

class _ProviderMenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;
  final bool isDestructive;

  const _ProviderMenuAction({required this.icon, required this.label, this.isHighlight = false, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : isHighlight ? AppColors.primary : Colors.grey.shade700;
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal)),
    ]);
  }
}
