import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class AdminModeBanner extends ConsumerWidget {
  const AdminModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isImpersonating || authState.originalAdminUser == null) {
      return const SizedBox.shrink();
    }

    final targetName = authState.user?.name ?? 'Unknown';
    final targetRole = authState.user?.role ?? 'user';
    final displayName = targetRole[0].toUpperCase() + targetRole.substring(1);

    return Material(
      color: const Color(0xFF1565C0),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.shield, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    children: [
                      const TextSpan(
                        text: 'ADMIN MODE',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const TextSpan(text: '  Viewing as '),
                      TextSpan(
                        text: '$targetName ($displayName)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await ref.read(authProvider.notifier).exitImpersonation();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/admin',
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Return to Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
