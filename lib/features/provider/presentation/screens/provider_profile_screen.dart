import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/availability_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/user_model.dart';
import '../../../../shared/widgets/service_quality_score.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final availabilityState = ref.watch(availabilityProvider);
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
            _buildTopBar(context, user),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        _buildHeaderCard(user),
                        const SizedBox(height: 20),
                        _buildStatsCard(user),
                        const SizedBox(height: 20),
                        _buildAvailabilityCard(context, ref, availabilityState),
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

  Widget _buildTopBar(BuildContext context, UserModel user) {
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
            'Provider Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Provider',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(UserModel user) {
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
            user.email ?? '',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(UserModel user) {
    return _card(
      title: 'Service Quality',
      child: Column(
        children: [
          if (user.rating > 0) ...[
            ServiceQualityScore(
              score: user.rating * 20,
              size: 60,
              showLabel: true,
            ),
            const SizedBox(height: 12),
            Text(
              '${user.reviewsCount} reviews',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ] else ...[
            const Icon(Icons.fiber_new, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text('No ratings yet', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statItem('Response Time', '< 2 min', Icons.timer)),
              Expanded(child: _statItem('Completion', '98%', Icons.check_circle_outlined)),
              Expanded(child: _statItem('Cancellation', '2%', Icons.cancel_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(BuildContext context, WidgetRef ref, AvailabilityState availabilityState) {
    return _card(
      title: 'Availability',
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Available for work',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
        ),
        subtitle: Text(
          availabilityState.isOnline
              ? 'You are visible to customers'
              : 'You are offline',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        value: availabilityState.isOnline,
        activeColor: Colors.blue.shade700,
        onChanged: (value) {
          ref.read(availabilityProvider.notifier).toggleAvailability();
        },
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, WidgetRef ref) {
    return _card(
      title: 'Account',
      child: Column(
        children: [
          _actionRow(Icons.edit_outlined, 'Edit Profile', () {}),
          const Divider(height: 1),
          _actionRow(Icons.lock_outline, 'Change Password', () => context.push('/forgot-password')),
          const Divider(height: 1),
          _actionRow(
            Icons.logout,
            'Log Out',
            () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('You\'ll need to sign in again to continue.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
            Colors.red.shade600,
            Colors.red.shade600,
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

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _actionRow(IconData icon, String label, VoidCallback onTap, [Color? labelColor, Color? iconColor]) {
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
}
