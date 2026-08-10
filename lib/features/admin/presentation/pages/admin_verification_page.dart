import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/admin_shell.dart';
import '../../providers/admin_verification_provider.dart';
import '../../../../core/themes/colors.dart';

class AdminVerificationPage extends ConsumerStatefulWidget {
  const AdminVerificationPage({super.key});

  @override
  ConsumerState<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends ConsumerState<AdminVerificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminVerificationProvider.notifier).loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminVerificationProvider);

    return AdminShell(
      currentRoute: 'verification',
      body: state.isLoading && state.documents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(state),
                  const SizedBox(height: 24),
                  _buildDocumentTable(state),
                ],
              ),
            ),
    );
  }

  Widget _buildPageHeader(AdminVerificationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Queue',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review provider identity documents',
          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.white.withValues(alpha: 0.9), size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identity Verification',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.total} document${state.total == 1 ? '' : 's'} awaiting review',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.read(adminVerificationProvider.notifier).loadPending(),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),
        if (state.actionError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.actionError!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(adminVerificationProvider.notifier).clearActionError(),
                    child: Icon(Icons.close, color: Colors.red.shade400, size: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentTable(AdminVerificationState state) {
    final docs = state.documents;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_open, color: Color(0xFF1A1A2E), size: 22),
              SizedBox(width: 8),
              Text('Pending Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 3, child: Text('Provider', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Submitted', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
              ],
            ),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (docs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text('No documents awaiting review', style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ...docs.map((doc) => _documentRow(doc)),
        ],
      ),
    );
  }

  Widget _documentRow(Map<String, dynamic> doc) {
    final docId = doc['id'] ?? '';
    final docType = doc['documentType'] ?? 'UNKNOWN';
    final imageUrl = doc['imageUrl'] ?? '';
    final providerName = doc['providerName'] ?? 'Unknown';
    final providerEmail = doc['providerEmail'] ?? '';
    final createdAt = doc['createdAt'] ?? '';
    final verificationLevel = doc['verificationLevel'] ?? '';

    final typeLabel = _docTypeLabel(docType);
    final submitted = _formatDate(createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _previewDocument(imageUrl, typeLabel),
                  child: Container(
                    width: 44,
                    height: 44,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(Icons.badge_outlined, color: Colors.grey.shade400),
                          )
                        : Icon(Icons.badge_outlined, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                    Text(verificationLevel,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(providerName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                Text(providerEmail,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(submitted, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _actionButton(
                  label: 'Approve',
                  icon: Icons.check,
                  color: Colors.green,
                  onTap: () => _approve(docId),
                ),
                const SizedBox(width: 8),
                _actionButton(
                  label: 'Reject',
                  icon: Icons.close,
                  color: Colors.red,
                  onTap: () => _reject(docId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.shade700, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve document'),
        content: const Text('Approve this document and verify the provider identity?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminVerificationProvider.notifier).approve(docId);
      _showResultSnack('Document approved');
    }
  }

  Future<void> _reject(String docId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject document'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'e.g. Blurry image, document expired, name mismatch',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason != null) {
      await ref.read(adminVerificationProvider.notifier).reject(docId, reason: reason.isEmpty ? 'Rejected by admin' : reason);
      _showResultSnack('Document rejected');
    }
  }

  void _previewDocument(String imageUrl, String typeLabel) {
    if (imageUrl.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(typeLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => SizedBox(
                    height: 200,
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResultSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _docTypeLabel(String type) {
    switch (type) {
      case 'NATIONAL_ID':
        return 'National ID';
      case 'PASSPORT':
        return 'Passport';
      case 'DRIVERS_LICENSE':
        return "Driver's License";
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    final dateTime = DateTime.tryParse(raw);
    if (dateTime == null) return raw;
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}
