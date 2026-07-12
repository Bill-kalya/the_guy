import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/widgets/admin_shell.dart';

class TrustSafetyCenterPage extends ConsumerStatefulWidget {
  const TrustSafetyCenterPage({super.key});

  @override
  ConsumerState<TrustSafetyCenterPage> createState() => _TrustSafetyCenterPageState();
}

class _TrustSafetyCenterPageState extends ConsumerState<TrustSafetyCenterPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // TODO: wire to repository once endpoints/models are added.
    Future<void>.delayed(const Duration(milliseconds: 400)).then((_) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Trust & Safety Center',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Risk monitoring and admin actions will be implemented here.',
                  ),
                ],
              ),
      ),
    );
  }
}

