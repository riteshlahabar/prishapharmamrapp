import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/custom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);

    final userName = auth.getPref('username') ?? 'MR User';
    final userId = auth.getPref('userid') ?? 'N/A';
    final role = auth.getPref('role') ?? 'Medical Representative';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.teal[800],
                        child: Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(role, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _InfoTile(label: 'User ID', value: userId),
            _InfoTile(label: 'Role', value: role),
            _InfoTile(label: 'Email', value: 'mr@prishapharma.com'),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Logout',
              icon: Icons.logout,
              textColor: Colors.red,
              bgColor: Colors.red[50]!,
              onPressed: () {
                auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}