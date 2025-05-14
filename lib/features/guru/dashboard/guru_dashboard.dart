import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuruDashboard extends ConsumerWidget {
  const GuruDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guru Dashboard'),
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
            Text('Assalamualaikum, ${user?['nama'] ?? 'Guru'}'),
            const SizedBox(height: 20),
            const Text('Anda login sebagai Guru'),
          ],
        ),
      ),
    );
  }
}
