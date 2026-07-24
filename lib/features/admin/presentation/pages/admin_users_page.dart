import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _filter = 'All';
  final _searchController = TextEditingController();

  static const _filterOptions = ['All', 'Customers', 'Providers', 'Admins', 'Verified', 'Blocked'];

  static const _users = [
    (name: 'John Doe', email: 'john@gmail.com', role: 'Customer', status: 'Active', joined: 'Today'),
    (name: 'Mary Smith', email: 'mary@gmail.com', role: 'Provider', status: 'Pending', joined: 'Today'),
    (name: 'Peter Kamau', email: 'peter@gmail.com', role: 'Customer', status: 'Suspended', joined: 'Yesterday'),
    (name: 'Grace Wanjiku', email: 'grace@gmail.com', role: 'Provider', status: 'Active', joined: 'Yesterday'),
    (name: 'David Ochieng', email: 'david@gmail.com', role: 'Admin', status: 'Active', joined: '3 days ago'),
    (name: 'Sarah Njeri', email: 'sarah@gmail.com', role: 'Customer', status: 'Active', joined: '3 days ago'),
    (name: 'James Mwangi', email: 'james@gmail.com', role: 'Provider', status: 'Active', joined: '5 days ago'),
    (name: 'Alice Adhiambo', email: 'alice@gmail.com', role: 'Customer', status: 'Blocked', joined: '7 days ago'),
  ];

  static const _recentRegistrations = [
    (name: 'John Doe', role: 'Customer', time: '10 min ago', initials: 'JD'),
    (name: 'Mary Smith', role: 'Provider', time: '32 min ago', initials: 'MS'),
    (name: 'Peter Kamau', role: 'Customer', time: '1 hour ago', initials: 'PK'),
    (name: 'Grace Wanjiku', role: 'Provider', time: '2 hours ago', initials: 'GW'),
    (name: 'David Ochieng', role: 'Admin', time: '5 hours ago', initials: 'DO'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: 'users',
      body: SingleChildScrollView(
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
            _buildKpiCards(),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
            const SizedBox(height: 20),
            _buildMainContent(),
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
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Total Users', value: '12,847', icon: Icons.people, color: AppColors.primary, subtitle: '+124 this week')),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Active Today', value: '3,421', icon: Icons.person, color: AppColors.success)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'Suspended', value: '89', icon: Icons.block, color: AppColors.error)),
            SizedBox(width: cardWidth, child: const AdminStatCard(title: 'New Today', value: '47', icon: Icons.person_add, color: AppColors.accent)),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        AdminSearchBar(controller: _searchController, hintText: 'Search users by name or email...'),
        const SizedBox(height: 12),
        AdminFilterBar(options: _filterOptions, selected: _filter, onSelected: (v) => setState(() => _filter = v)),
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
              Expanded(flex: 3, child: _buildUserTable()),
              const SizedBox(width: 20),
              SizedBox(width: 280, child: _buildRecentPanel()),
            ],
          );
        }
        return Column(
          children: [
            _buildUserTable(),
            const SizedBox(height: 20),
            _buildRecentPanel(),
          ],
        );
      },
    );
  }

  Widget _buildUserTable() {
    return AdminSectionCard(
      title: 'User List',
      titleIcon: Icons.table_chart,
      child: Column(
        children: [
          const AdminTableHeader(
            columns: ['User', 'Role', 'Status', 'Joined'],
            flexes: [3, 2, 2, 2],
          ),
          const SizedBox(height: 8),
          ..._users.map((u) => _userRow(u)),
        ],
      ),
    );
  }

  Widget _userRow(dynamic u) {
    final statusColor = u.status == 'Active'
        ? AppColors.success
        : u.status == 'Suspended' || u.status == 'Blocked'
            ? AppColors.error
            : AppColors.warning;
    final initials = u.name.toString().split(' ').map((w) => w[0]).take(2).join();

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
                    Text(u.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                    Text(u.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(u.role, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(flex: 2, child: AdminStatusBadge(label: u.status, color: statusColor)),
          Expanded(
            flex: 2,
            child: Text(u.joined, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ),
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
        const PopupMenuItem(value: 'view_profile', child: _MenuAction(icon: Icons.person, label: 'View Profile')),
        const PopupMenuItem(value: 'view_jobs', child: _MenuAction(icon: Icons.work, label: 'View Jobs')),
        const PopupMenuItem(value: 'view_wallet', child: _MenuAction(icon: Icons.account_balance_wallet, label: 'View Wallet')),
        const PopupMenuDivider(),
        if (u.role != 'Admin')
          PopupMenuItem(
            value: 'view_as',
            child: _MenuAction(icon: Icons.remove_red_eye, label: 'View as ${u.role}', isHighlight: true),
          ),
        if (u.status == 'Active')
          const PopupMenuItem(value: 'suspend', child: _MenuAction(icon: Icons.block, label: 'Suspend', isDestructive: true)),
      ],
    );
  }

  void _handleAction(String action, dynamic u) async {
    switch (action) {
      case 'view_as':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('View as User'),
            content: Text('You will be viewing the app as ${u.name}. Your admin session will be restored when you return.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('View as ${u.name}', style: const TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          // TODO: Replace with real user ID from API
          final mockUserId = '00000000-0000-0000-0000-000000000001';
          await ref.read(authProvider.notifier).impersonateUser(mockUserId);
          if (mounted) context.go('/');
        }
        break;
      case 'suspend':
        // TODO: Implement suspend
        break;
      default:
        break;
    }
  }

  Widget _buildRecentPanel() {
    return AdminSectionCard(
      title: 'Recent Registrations',
      titleIcon: Icons.schedule,
      child: Column(
        children: [
          ..._recentRegistrations.map((r) {
            final color = r.role == 'Provider' ? AppColors.primary : AppColors.secondary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text(r.initials, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                        Text(r.role, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Text(r.time, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
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
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;
  final bool isDestructive;

  const _MenuAction({
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
