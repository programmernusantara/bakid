import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/admin/dashboard/motoring_kelas.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              ref.read(currentUserProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Selamat datang, ${user?['nama'] ?? 'Admin'}'),
            const SizedBox(height: 20),
            const Text('Anda login sebagai Admin'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MonitoringScreen()),
                  ),
              child: const Text('Monitoring Kelas Hari Ini'),
            ),
          ],
        ),
      ),
    );
  }
}
