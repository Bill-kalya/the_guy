import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        _buildHeaderCard(context, ref, user),
                        const SizedBox(height: 20),
                        _buildInfoCard(user),
                        const SizedBox(height: 20),
                        _buildStatsCard(user),
                        const SizedBox(height: 20),
                        _buildActionsCard(context, ref),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const Text(
            'My Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, WidgetRef ref, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? Text(
                        _initials(user.name),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      )
                    : null,
              ),
              if (user.isVerified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified, color: Colors.green.shade500, size: 22),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name.isNotEmpty ? user.name : 'Unnamed User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            user.role.isNotEmpty ? _titleCase(user.role) : '',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
          ),
          if (!user.isVerified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 6),
                  Text(
                    'Email not verified',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return _card(
      title: 'Contact Information',
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, 'Email', user.email ?? 'Not provided'),
          const Divider(height: 24),
          _infoRow(Icons.phone_outlined, 'Phone', user.phone.isNotEmpty ? user.phone : 'Not provided'),
          const Divider(height: 24),
          _infoRow(Icons.badge_outlined, 'Role', user.role.isNotEmpty ? _titleCase(user.role) : 'Not set'),
        ],
      ),
    );
  }

  Widget _buildStatsCard(UserModel user) {
    return _card(
      title: 'Activity',
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.star_rounded,
              iconColor: Colors.amber.shade600,
              value: user.rating > 0 ? user.rating.toStringAsFixed(1) : '\u2014',
              label: 'Rating',
            ),
          ),
          Container(width: 1, height: 48, color: Colors.grey.shade200),
          Expanded(
            child: _statTile(
              icon: Icons.reviews_outlined,
              iconColor: Colors.blue.shade600,
              value: user.reviewsCount.toString(),
              label: 'Reviews',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, WidgetRef ref) {
    return _card(
      title: 'Account',
      child: Column(
        children: [
          _actionRow(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () {},
          ),
          const Divider(height: 1),
          _actionRow(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => context.push('/forgot-password'),
          ),
          const Divider(height: 1),
          _actionRow(
            icon: Icons.logout,
            label: 'Log Out',
            labelColor: Colors.red.shade600,
            iconColor: Colors.red.shade600,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('You\'ll need to sign in again to continue.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Log Out', style: TextStyle(color: Colors.red.shade600)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: labelColor ?? const Color(0xFF1A1A2E)),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
