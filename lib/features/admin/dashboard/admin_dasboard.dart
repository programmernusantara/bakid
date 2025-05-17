import 'package:bakid/features/admin/dashboard/aktivitas_guru.dart';
import 'package:bakid/features/admin/dashboard/pengumuman/pengumuman_list.dart';
import 'package:bakid/features/admin/dashboard/profile_guru.dart';
import 'package:bakid/features/admin/dashboard/verivikasi_izin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/auth/auth_providers.dart';

class AdminDasboard extends ConsumerStatefulWidget {
  const AdminDasboard({super.key});

  @override
  ConsumerState<AdminDasboard> createState() => _AdminDasboardState();
}

class _AdminDasboardState extends ConsumerState<AdminDasboard> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    AktivitasHarianGuru(),
    GuruManagementPage(),
    VerifikasiIzinPage(),
    PengumumanListPage(), // Tambahkan ini
  ];

  final List<String> titles = const [
    'Aktivitas Guru',
    'Profile Guru',
    'Perizinan Guru',
    'Pengumuman Guru', // Tambahkan ini
  ];

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text(
                  'BAKID',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Aktivitas'),
              selected: selectedIndex == 0,
              onTap: () => setState(() => selectedIndex = 0),
            ),
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text('Profile'),
              selected: selectedIndex == 1,
              onTap: () => setState(() => selectedIndex = 1),
            ),
            ListTile(
              leading: const Icon(Icons.payment_outlined),
              title: const Text('Perizinan'),
              selected: selectedIndex == 2,
              onTap: () => setState(() => selectedIndex = 2),
            ),
            ListTile(
              leading: const Icon(Icons.announcement_outlined),
              title: const Text('Pengumuman'),
              selected: selectedIndex == 3,
              onTap: () => setState(() => selectedIndex = 3),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await authService.logout();
                ref.read(currentUserProvider.notifier).state = null;
              },
            ),
          ],
        ),
      ),
      body: pages[selectedIndex],
    );
  }
}
