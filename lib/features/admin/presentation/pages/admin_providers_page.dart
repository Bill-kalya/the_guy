import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../../core/themes/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_providers_provider.dart';
import '../../providers/admin_safety_provider.dart';

class AdminProvidersPage extends ConsumerStatefulWidget {
  const AdminProvidersPage({super.key});

  @override
  ConsumerState<AdminProvidersPage> createState() => _AdminProvidersPageState();
}

class _AdminProvidersPageState extends ConsumerState<AdminProvidersPage> {
  String _statusFilter = 'All';
  final _searchController = TextEditingController();

  static const _statusOptions = ['All', 'ACTIVE', 'SUSPENDED', 'BANNED', 'INACTIVE'];

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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final header = AdminPageHeader(
                        title: 'Service Providers',
                        subtitle: 'Manage provider registrations and verification',
                      );
                      final importButton = OutlinedButton.icon(
                        onPressed: _showImportDialog,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Import CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                      );
                      final refreshButton = IconButton(
                        tooltip: 'Refresh',
                        onPressed: state.isLoading
                            ? null
                            : () => ref.read(adminProvidersProvider.notifier).loadAll(),
                        icon: state.isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh),
                      );
                      final actions = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          importButton,
                          refreshButton,
                        ],
                      );
                      if (constraints.maxWidth < 760) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            header,
                            const SizedBox(height: 12),
                            actions,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: header),
                          const SizedBox(width: 12),
                          actions,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildKpiCards(state),
                  const SizedBox(height: 24),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE05C5C)),
            ),
            child: Text(
              'Failed to load: ${state.error}',
              style: const TextStyle(color: Color(0xFFB03A3A), fontSize: 13),
            ),
          ),
        _buildSearchAndFilters(),
        const SizedBox(height: 20),
        LayoutBuilder(
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
      ),
      ],
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
                const AdminTableHeader(columns: ['Provider', 'Rating', 'Jobs', 'Status', 'Claim'], flexes: [4, 2, 2, 2, 3]),
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
    final providerStatus = (p['providerStatus'] ?? 'ACTIVE').toString().toUpperCase();
    final (statusLabel, statusColor) = switch (providerStatus) {
      'SUSPENDED' => ('Suspended', AppColors.error),
      'BANNED' => ('Banned', Colors.grey),
      'INACTIVE' => ('Demoted', Colors.orange),
      _ => ('Active', AppColors.success),
    };
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(name.toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1A1A2E))),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: isOnline ? 'Online — visible to customers' : 'Offline — hidden from customers',
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? AppColors.success : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
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
          Expanded(flex: 2, child: AdminStatusBadge(label: statusLabel, color: statusColor)),
          Expanded(flex: 3, child: _buildClaimCell(p)),
          _buildProviderActionMenu(p),
        ],
      ),
    );
  }

  Widget _buildClaimCell(dynamic p) {
    final claimed = p['accountClaimed'] == true;
    final code = (p['claimCode'] ?? '').toString();
    final expiresAt = p['claimCodeExpiresAt'];

    if (claimed) {
      return AdminStatusBadge(label: 'Claimed', color: AppColors.success);
    }

    if (code.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: AppColors.primary,
            ),
          ),
          if (expiresAt != null)
            Text('expires ${expiresAt.toString().replaceAll('T', ' ').split('.').first}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallAction(icon: Icons.copy, tooltip: 'Copy claim code', onTap: () => _copyClaimCode(code)),
              const SizedBox(width: 4),
              _SmallAction(icon: Icons.refresh, tooltip: 'Regenerate claim code', onTap: () => _regenerateClaimCode(p)),
            ],
          ),
        ],
      );
    }

    return _SmallAction(icon: Icons.add_link, label: 'Generate', tooltip: 'Generate claim code', onTap: () => _regenerateClaimCode(p));
  }

  Future<void> _copyClaimCode(String code) async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Claim code $code copied to clipboard'), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _regenerateClaimCode(dynamic p) async {
    final providerId = (p['id'] ?? '').toString();
    final name = p['fullName'] ?? 'provider';
    if (providerId.isEmpty) return;

    try {
      final data = await ref.read(adminProvidersProvider.notifier).regenerateClaimCode(providerId);
      final code = (data['claimCode'] ?? '').toString();
      if (!mounted) return;
      await _copyClaimCode(code);
      await ref.read(adminProvidersProvider.notifier).loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate code for $name: $e')),
      );
    }
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    final csv = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Providers (CSV)'),
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Columns: name, phone, category, county, lat, lng. Only name and phone are required; county is used to estimate location.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 12,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'name,phone,category,county,lat,lng\nJohn Kamau,0712345678,Plumbing,Nairobi\nAnn Wanjiku,0722000111,Electrician,Kisumu',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (csv == null || csv.trim().isEmpty) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ref.read(adminProvidersProvider.notifier).importProviders(csv);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final imported = result['imported'] ?? 0;
      final total = result['totalRows'] ?? csv.trim().split('\n').length;
      final skipped = result['skippedDuplicatePhone'] ?? 0;
      final invalid = (result['invalidRows'] as List<dynamic>? ?? []).cast<String>();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultLine('Total rows', '$total'),
              const SizedBox(height: 6),
              _resultLine('Imported', '$imported', color: AppColors.success),
              const SizedBox(height: 6),
              _resultLine('Skipped (duplicate phone)', '$skipped', color: AppColors.warning),
              if (invalid.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Issues:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: invalid
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(e, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) await ref.read(adminProvidersProvider.notifier).loadAll();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Widget _resultLine(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? const Color(0xFF1A1A2E))),
      ],
    );
  }

  Widget _buildProviderActionMenu(dynamic p) {
    final providerStatus = (p['providerStatus'] ?? 'ACTIVE').toString().toUpperCase();
    final canDemote = providerStatus == 'ACTIVE' || providerStatus == 'SUSPENDED';

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
      onSelected: (value) => _handleProviderAction(value, p),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'view_as', child: _ProviderMenuAction(icon: Icons.remove_red_eye, label: 'View as Provider', isHighlight: true)),
        if (canDemote)
          const PopupMenuItem(value: 'demote', child: _ProviderMenuAction(icon: Icons.person_remove, label: 'Demote to User', isDestructive: true)),
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
    } else if (action == 'demote') {
      final name = p['fullName'] ?? 'this provider';
      final providerId = (p['id'] ?? '').toString();
      if (providerId.isEmpty) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Demote Provider'),
          content: Text(
            'Remove $name from being a provider and convert them back to a normal user?\n\n'
            'They will no longer be able to receive jobs or appear in provider search results.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Demote $name', style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        final success = await ref.read(adminSafetyProvider.notifier).demoteProvider(providerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '$name has been demoted to a customer' : 'Failed to demote $name'),
              backgroundColor: success ? AppColors.success : AppColors.error,
            ),
          );
          if (success) {
            await ref.read(adminProvidersProvider.notifier).loadAll();
          }
        }
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

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback onTap;

  const _SmallAction({required this.icon, required this.tooltip, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: label != null ? 8 : 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
