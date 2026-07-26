import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_users_provider.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _filter = 'All';
  final _searchController = TextEditingController();

  static const _filterOptions = ['All', 'CUSTOMER', 'PROVIDER', 'ADMIN'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUsersProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    return AdminShell(
      currentRoute: 'users',
      body: state.isLoading && state.summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'Users',
                    subtitle: 'Manage everyone using the platform',
                    trailing: Row(
                      children: [
                        _actionChip(Icons.person_add, 'Add Admin', AppColors.primary),
                        const SizedBox(width: 8),
                        _actionChip(Icons.download, 'Export CSV', Colors.grey),
                      ],
                    ),
                  ),
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

  Widget _buildKpiCards(AdminUsersState state) {
    final s = state.summary ?? {};
    final totalUsers = s['totalUsers'] ?? 0;
    final totalCustomers = s['totalCustomers'] ?? 0;
    final totalProviders = s['totalProviders'] ?? 0;
    final totalAdmins = s['totalAdmins'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Total Users', value: _fmtInt(totalUsers), icon: Icons.people, color: AppColors.primary)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Customers', value: _fmtInt(totalCustomers), icon: Icons.person, color: AppColors.success)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Providers', value: _fmtInt(totalProviders), icon: Icons.build, color: Colors.blue)),
            SizedBox(width: cardWidth, child: AdminStatCard(title: 'Admins', value: _fmtInt(totalAdmins), icon: Icons.admin_panel_settings, color: Colors.purple)),
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
          hintText: 'Search users by name or email...',
          onChanged: (v) => ref.read(adminUsersProvider.notifier).refreshWithFilters(search: v),
        ),
        const SizedBox(height: 12),
        AdminFilterBar(
          options: _filterOptions,
          selected: _filter,
          onSelected: (v) {
            setState(() => _filter = v);
            ref.read(adminUsersProvider.notifier).refreshWithFilters(role: v);
          },
        ),
      ],
    );
  }

  Widget _buildMainContent(AdminUsersState state) {
    final usersPage = state.users ?? {};
    final content = usersPage['content'] as List<dynamic>? ?? [];
    final riskOverview = state.riskOverview ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildUserTable(content)),
              const SizedBox(width: 20),
              SizedBox(width: 280, child: Column(
                children: [
                  _buildRiskOverview(riskOverview),
                  const SizedBox(height: 20),
                  _buildRecentRegistrations(content),
                ],
              )),
            ],
          );
        }
        return Column(
          children: [
            _buildUserTable(content),
            const SizedBox(height: 20),
            _buildRiskOverview(riskOverview),
            const SizedBox(height: 20),
            _buildRecentRegistrations(content),
          ],
        );
      },
    );
  }

  Widget _buildUserTable(List<dynamic> users) {
    return AdminSectionCard(
      title: 'User List',
      titleIcon: Icons.table_chart,
      child: users.isEmpty
          ? const AdminEmptyState(icon: Icons.people, title: 'No users found', subtitle: 'User data will appear here')
          : Column(
              children: [
                const AdminTableHeader(columns: ['User', 'Role', 'Joined'], flexes: [4, 3, 3]),
                const SizedBox(height: 8),
                ...users.take(10).map((u) => _userRow(u)),
              ],
            ),
    );
  }

  Widget _userRow(dynamic u) {
    final name = u['fullName'] ?? 'Unknown';
    final email = u['email'] ?? '';
    final role = u['role'] ?? 'UNKNOWN';
    final createdAt = u['createdAt'] ?? '';
    final initials = name.toString().split(' ').map((w) => w[0]).take(2).join();

    final roleColor = role.toString() == 'ADMIN'
        ? Colors.purple
        : role.toString() == 'PROVIDER'
            ? AppColors.primary
            : AppColors.secondary;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                      Text(email.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(role.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: roleColor)),
            ),
          ),
          Expanded(flex: 3, child: Text(_timeAgo(createdAt.toString()), style: TextStyle(fontSize: 13, color: Colors.grey.shade500))),
          _buildActionMenu(u),
        ],
      ),
    );
  }

  Widget _buildActionMenu(dynamic u) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
      onSelected: (value) => _handleAction(value, u),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'view_as', child: _MenuAction(icon: Icons.remove_red_eye, label: 'View as User', isHighlight: true)),
      ],
    );
  }

  void _handleAction(String action, dynamic u) async {
    if (action == 'view_as') {
      final name = u['fullName'] ?? 'this user';
      final userId = u['id'] ?? '';
      final role = u['role'] ?? 'CUSTOMER';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('View as User'),
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
        if (mounted) {
          if (role.toString() == 'PROVIDER') {
            context.go('/provider/home');
          } else {
            context.go('/');
          }
        }
      }
    }
  }

  Widget _buildRiskOverview(Map<String, dynamic> riskOverview) {
    final low = riskOverview['low'] ?? 0;
    final medium = riskOverview['medium'] ?? 0;
    final high = riskOverview['high'] ?? 0;
    final critical = riskOverview['critical'] ?? 0;

    return AdminSectionCard(
      title: 'Risk Overview',
      titleIcon: Icons.shield,
      child: Column(
        children: [
          _riskRow('Critical', '$critical', Colors.red),
          const SizedBox(height: 12),
          _riskRow('High', '$high', Colors.orange),
          const SizedBox(height: 12),
          _riskRow('Medium', '$medium', Colors.amber),
          const SizedBox(height: 12),
          _riskRow('Low', '$low', AppColors.success),
        ],
      ),
    );
  }

  Widget _riskRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildRecentRegistrations(List<dynamic> users) {
    final recent = users.take(5).toList();

    return AdminSectionCard(
      title: 'Recent Users',
      titleIcon: Icons.schedule,
      child: recent.isEmpty
          ? const AdminEmptyState(icon: Icons.person_add, title: 'No recent registrations', subtitle: 'New users will appear here')
          : Column(
              children: recent.map((u) {
                final name = u['fullName'] ?? 'Unknown';
                final role = u['role'] ?? 'CUSTOMER';
                final createdAt = u['createdAt'] ?? '';
                final color = role.toString() == 'PROVIDER' ? AppColors.primary : AppColors.secondary;
                final initials = name.toString().split(' ').map((w) => w[0]).take(2).join();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: color.withValues(alpha: 0.1),
                        child: Text(initials, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                            Text(role.toString(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Text(_timeAgo(createdAt.toString()), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  String _fmtInt(dynamic v) {
    final n = v is num ? v.toInt() : 0;
    return n.toString();
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

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;
  final bool isDestructive;

  const _MenuAction({required this.icon, required this.label, this.isHighlight = false, this.isDestructive = false});

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
