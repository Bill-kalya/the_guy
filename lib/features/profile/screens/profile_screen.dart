import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    _buildHeader(context, user),
                    const SizedBox(height: 20),
                    _buildProfileCompletion(user),
                    const SizedBox(height: 20),
                    _buildAboutMe(user),
                    const SizedBox(height: 20),
                    _buildContactInfo(user),
                    const SizedBox(height: 20),
                    _buildActivityCard(user),
                    const SizedBox(height: 20),
                    _buildSecuritySection(context, ref),
                    const SizedBox(height: 20),
                    _buildLogoutButton(context, ref),
                    const SizedBox(height: 24),
                  ],
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
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          const Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? Text(_initials(user.name), style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue.shade700))
                    : null,
              ),
              if (user.isVerified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.verified, color: Colors.green.shade500, size: 22),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user.name.isNotEmpty ? user.name : 'Unnamed User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.rating > 0) ...[
                Icon(Icons.star_rounded, color: Colors.amber.shade300, size: 18),
                const SizedBox(width: 4),
                Text('${user.rating.toStringAsFixed(1)} (${user.reviewsCount} reviews)',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
              ] else
                Text('New member', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Completion ──────────────────────────────────
  Widget _buildProfileCompletion(UserModel user) {
    final checks = [
      ('Profile Photo', user.avatar != null),
      ('Email Verified', user.isVerified),
      ('Phone Added', user.phone.isNotEmpty),
    ];
    final completed = checks.where((c) => c.$2).length;
    final pct = (completed / checks.length * 100).round();

    return _card(
      title: 'Profile Completion',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      pct == 100 ? Colors.green.shade500 : Colors.blue.shade600,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$pct%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: pct == 100 ? Colors.green.shade700 : Colors.blue.shade700)),
            ],
          ),
          const SizedBox(height: 16),
          ...checks.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(c.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20, color: c.$2 ? Colors.green.shade500 : Colors.grey.shade400),
                const SizedBox(width: 10),
                Text(c.$1, style: TextStyle(fontSize: 14, color: c.$2 ? const Color(0xFF1A1A2E) : Colors.grey.shade600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── About Me ────────────────────────────────────────────
  Widget _buildAboutMe(UserModel user) {
    final bio = user.metadata?['bio'] as String?;
    return _card(
      title: 'About Me',
      child: Text(
        bio ?? 'No bio added yet. Tell customers about yourself to build trust.',
        style: TextStyle(
          fontSize: 15,
          color: bio != null ? const Color(0xFF1A1A2E) : Colors.grey.shade500,
          height: 1.5,
        ),
      ),
    );
  }

  // ── Contact Info ────────────────────────────────────────
  Widget _buildContactInfo(UserModel user) {
    return _card(
      title: 'Contact Information',
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, 'Email', user.email ?? 'Not provided'),
          const Divider(height: 24),
          _infoRow(Icons.phone_outlined, 'Phone', user.phone.isNotEmpty ? user.phone : 'Not provided'),
          const Divider(height: 24),
          _infoRow(Icons.calendar_today_outlined, 'Member since', _formatDate(user.createdAt)),
        ],
      ),
    );
  }

  // ── Activity (Customer) ─────────────────────────────────
  Widget _buildActivityCard(UserModel user) {
    return _card(
      title: 'Activity',
      child: Row(
        children: [
          Expanded(child: _statTile(Icons.work_outline, Colors.blue, '0', 'Jobs Posted')),
          Container(width: 1, height: 48, color: Colors.grey.shade200),
          Expanded(child: _statTile(Icons.star_rounded, Colors.amber, user.rating > 0 ? user.rating.toStringAsFixed(1) : '\u2014', 'Rating')),
          Container(width: 1, height: 48, color: Colors.grey.shade200),
          Expanded(child: _statTile(Icons.favorite_outline, Colors.red, '0', 'Favorites')),
        ],
      ),
    );
  }

  // ── Security ────────────────────────────────────────────
  Widget _buildSecuritySection(BuildContext context, WidgetRef ref) {
    return _card(
      title: 'Account Security',
      child: Column(
        children: [
          _actionRow(Icons.lock_outline, 'Change Password', () => context.push('/forgot-password')),
          const Divider(height: 1),
          _actionRow(Icons.location_on_outlined, 'Location', () {}),
          const Divider(height: 1),
          _actionRow(Icons.language_outlined, 'Language', () {}),
        ],
      ),
    );
  }

  // ── Logout ──────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Log out?'),
                content: const Text("You'll need to sign in again to continue."),
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
          icon: Icon(Icons.logout, color: Colors.red.shade600, size: 20),
          label: Text('Log Out', style: TextStyle(color: Colors.red.shade600, fontSize: 16, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────
  Widget _card({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            child,
          ],
        ),
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

  Widget _statTile(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _actionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)))),
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

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return 'Unknown';
    }
  }
}
