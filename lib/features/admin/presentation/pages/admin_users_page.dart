import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';
import '../../../../core/themes/colors.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: 'users',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Text('Users', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            _buildComingSoon('View and manage platform users'),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoon(String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Coming Soon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
