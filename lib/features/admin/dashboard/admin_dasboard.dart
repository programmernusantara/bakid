import 'package:bakid/features/admin/dashboard/aktivitas_guru.dart';
import 'package:bakid/features/admin/dashboard/kelas/kelas_list_page.dart';
import 'package:bakid/features/admin/dashboard/pengumuman/pengumuman_list.dart';
import 'package:bakid/features/admin/dashboard/profile_guru.dart';
import 'package:bakid/features/admin/dashboard/verivikasi_izin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/auth/auth_providers.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    AktivitasHarianGuru(),
    GuruManagementPage(),
    VerifikasiIzinPage(),
    PengumumanListPage(),
    KelasListPage(),
  ];

  final List<String> titles = const [
    'Aktivitas Guru',
    'Manajemen Guru',
    'Verifikasi Izin',
    'Pengumuman',
    'Manajemen Kelas',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.surface,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(25), // ~10% opacity
                  Theme.of(context).colorScheme.surface,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Admin Bakid',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.assessment_outlined,
              label: 'Aktivitas Guru',
              selected: selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            _DrawerItem(
              icon: Icons.people_outline,
              label: 'Manajemen Guru',
              selected: selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            _DrawerItem(
              icon: Icons.verified_outlined,
              label: 'Verifikasi Izin',
              selected: selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            _DrawerItem(
              icon: Icons.announcement_outlined,
              label: 'Pengumuman',
              selected: selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
            _DrawerItem(
              icon: Icons.school_outlined,
              label: 'Manajemen Kelas',
              selected: selectedIndex == 4,
              onTap: () => _onItemTapped(4),
            ),
            const Spacer(),
            const Divider(),

            _DrawerItem(
              icon: Icons.logout,
              label: 'Keluar',
              color: colors.error,
              onTap: () async {
                await authService.logout();
                ref.read(currentUserProvider.notifier).state = null;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: pages[selectedIndex],
    );
  }

  void _onItemTapped(int index) {
    setState(() => selectedIndex = index);
    Navigator.pop(context); // Close the drawer
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: color ?? (selected ? colors.primary : colors.onSurfaceVariant),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color ?? (selected ? colors.primary : colors.onSurface),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}
