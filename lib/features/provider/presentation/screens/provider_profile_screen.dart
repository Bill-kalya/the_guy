import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/availability_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/provider_profile_provider.dart';
import '../../models/provider_profile_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/user_model.dart';
import '../../../../core/themes/colors.dart';
import '../../../../shared/constants/service_categories.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsProvider.notifier).fetchEarnings();
      ref.read(providerProfileProvider.notifier).fetchProfile();
      ref.read(providerProfileProvider.notifier).fetchCompletion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final availabilityState = ref.watch(availabilityProvider);
    final earningsState = ref.watch(earningsProvider);
    final providerProfileState = ref.watch(providerProfileProvider);
    final user = authState.user;
    final providerProfile = providerProfileState.profile;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, user),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    _buildHeader(context, ref, user, availabilityState),
                    const SizedBox(height: 20),
                    _buildProfileCompletion(user, providerProfileState.completion),
                    const SizedBox(height: 20),
                    _buildAboutMe(user),
                    const SizedBox(height: 20),
                    _buildServiceCard(providerProfile),
                    const SizedBox(height: 20),
                    if (providerProfile != null && providerProfile.portfolioImages.isNotEmpty) ...[
                      _buildPortfolioCard(providerProfile),
                      const SizedBox(height: 20),
                    ],
                    _buildContactInfo(user),
                    const SizedBox(height: 20),
                    _buildProviderMetrics(user, earningsState),
                    const SizedBox(height: 20),
                    _buildWalletCard(earningsState),
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

  Widget _buildTopBar(BuildContext context, UserModel user) {
    return Container(
      height: 64,
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          const Text('Provider Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Text('Provider', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Header with availability toggle ─────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref, UserModel user, AvailabilityState availabilityState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
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
                    ? Text(_initials(user.name), style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary))
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
          const SizedBox(height: 4),
          Text('Service Provider', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.rating > 0) ...[
                Icon(Icons.star_rounded, color: Colors.amber.shade300, size: 18),
                const SizedBox(width: 4),
                Text('${user.rating.toStringAsFixed(1)} (${user.reviewsCount} reviews)',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
              ] else
                Text('New provider', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 16),
          // Availability toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: availabilityState.isOnline ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: availabilityState.isOnline ? Colors.green.shade300 : Colors.grey, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(availabilityState.isOnline ? 'Online — Visible to customers' : 'Offline — Hidden from customers',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(width: 8),
                Switch(
                  value: availabilityState.isOnline,
                  onChanged: (_) => ref.read(availabilityProvider.notifier).toggleAvailability(),
                  activeThumbColor: Colors.green.shade300,
                  inactiveThumbColor: Colors.grey,
                ),
              ],
            ),
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
                foregroundColor: AppColors.primary,
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
  Widget _buildProfileCompletion(UserModel user, Map<String, dynamic>? completion) {
    final score = completion?['score'] as int? ?? 0;
    final label = completion?['label'] as String? ?? 'Just started';
    final checksMap = completion?['checks'] as Map<String, dynamic>?;

    final checks = <MapEntry<String, bool>>[];
    if (checksMap != null) {
      for (final entry in checksMap.entries) {
        final check = entry.value as Map<String, dynamic>;
        checks.add(MapEntry(check['label'] as String, check['completed'] as bool));
      }
    } else {
      // Fallback if completion endpoint hasn't loaded yet
      checks.addAll([
        MapEntry('Profile Photo', user.avatar != null),
        MapEntry('Email Verified', user.isVerified),
        MapEntry('Phone Added', user.phone.isNotEmpty),
      ]);
    }

    final displayPct = checksMap != null ? score : ((checks.where((c) => c.value).length / checks.length * 100).round());

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
                    value: displayPct / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(displayPct == 100 ? Colors.green.shade500 : AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$displayPct%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: displayPct == 100 ? Colors.green.shade700 : AppColors.primary)),
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...checks.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(c.value ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20, color: c.value ? Colors.green.shade500 : Colors.grey.shade400),
                const SizedBox(width: 10),
                Text(c.key, style: TextStyle(fontSize: 14, color: c.value ? const Color(0xFF1A1A2E) : Colors.grey.shade600)),
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
        bio ?? 'No bio added yet. Tell customers about your experience and specialties to build trust.',
        style: TextStyle(
          fontSize: 15,
          color: bio != null ? const Color(0xFF1A1A2E) : Colors.grey.shade500,
          height: 1.5,
        ),
      ),
    );
  }

  // ── Service Category ───────────────────────────────────
  Widget _buildServiceCard(ProviderProfileModel? profile) {
    final categoryId = profile?.categoryId;
    final cat = categoryId != null ? ServiceCategories.getByName(categoryId) : null;

    return _card(
      title: 'Service',
      child: cat != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cat.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(cat.icon, size: 24, color: cat.color.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cat.color.shade800)),
                        const SizedBox(height: 2),
                        Text('Your service category', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  if (profile?.verificationLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _verificationColor(profile!.verificationLevel).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        profile.verificationLevel.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _verificationColor(profile.verificationLevel)),
                      ),
                    ),
                ],
              ),
            )
          : Text(
              categoryId ?? 'No category set',
              style: TextStyle(fontSize: 15, color: categoryId != null ? const Color(0xFF1A1A2E) : Colors.grey.shade500),
            ),
    );
  }

  Color _verificationColor(String level) {
    switch (level) {
      case 'BUSINESS': return Colors.green.shade700;
      case 'ID_VERIFIED': return Colors.blue.shade700;
      case 'BASIC': return Colors.orange.shade700;
      default: return Colors.grey.shade600;
    }
  }

  // ── Portfolio ─────────────────────────────────────────
  Widget _buildPortfolioCard(ProviderProfileModel profile) {
    return _card(
      title: 'Work Portfolio',
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: profile.portfolioImages.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final img = profile.portfolioImages[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                img.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                ),
              ),
            );
          },
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
          _infoRow(Icons.location_on_outlined, 'Location', 'Nairobi, Kenya'),
          const Divider(height: 24),
          _infoRow(Icons.calendar_today_outlined, 'Member since', _formatDate(user.createdAt)),
        ],
      ),
    );
  }

  // ── Provider Metrics ────────────────────────────────────
  Widget _buildProviderMetrics(UserModel user, EarningsState earningsState) {
    final jobsCompleted = earningsState.earnings?.totalJobsCompleted ?? 0;
    return _card(
      title: 'Provider Activity',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _statTile(Icons.work_outline, Colors.blue, '$jobsCompleted', 'Jobs Done')),
              Container(width: 1, height: 48, color: Colors.grey.shade200),
              Expanded(child: _statTile(Icons.star_rounded, Colors.amber, user.rating > 0 ? user.rating.toStringAsFixed(1) : '\u2014', 'Rating')),
            ],
          ),
        ],
      ),
    );
  }

  // ── Wallet ──────────────────────────────────────────────
  Widget _buildWalletCard(EarningsState earningsState) {
    final earnings = earningsState.earnings;
    final available = earnings?.availableBalance ?? 0.0;
    final pending = earnings?.pendingBalance ?? 0.0;
    final currency = earnings?.currency ?? 'KES';
    return _card(
      title: 'Wallet',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Balance', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 6),
                Text('$currency ${available.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          if (pending > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending_outlined, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Balance', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                      Text('$currency ${pending.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _walletAction(Icons.arrow_downward, 'Top Up', Colors.blue, null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _walletAction(Icons.arrow_upward, 'Withdraw', Colors.green, () => context.push('/provider/wallet')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _actionRow(Icons.receipt_long_outlined, 'Transaction History', () => context.push('/provider/wallet')),
        ],
      ),
    );
  }

  Widget _walletAction(IconData icon, String label, MaterialColor color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color.shade700),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color.shade700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Security ────────────────────────────────────────────
  Widget _buildSecuritySection(BuildContext context, WidgetRef ref) {
    return _card(
      title: 'Account Security',
      child: Column(
        children: [
          _actionRow(Icons.lock_outline, 'Change Password', () => context.push('/change-password')),
          const Divider(height: 1),
          _actionRow(Icons.location_on_outlined, 'Service Area', () {}),
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
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
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
            Icon(icon, size: 20, color: AppColors.primary),
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
