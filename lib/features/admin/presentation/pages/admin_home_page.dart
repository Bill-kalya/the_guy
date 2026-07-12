import 'package:flutter/material.dart';

import '../widgets/admin_shell.dart';
import 'trust_safety_center_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an admin module to continue.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrustSafetyCenterPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Trust & Safety'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

