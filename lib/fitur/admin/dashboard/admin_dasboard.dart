import 'package:bakid/fitur/admin/dashboard/aktivitas_guru.dart';
import 'package:bakid/fitur/admin/kelas/kelas_list_page.dart';
import 'package:bakid/fitur/admin/pengumuman/pengumuman_list.dart';
import 'package:bakid/fitur/admin/dashboard/profile_guru.dart';
import 'package:bakid/fitur/admin/dashboard/verivikasi_izin.dart';
import 'package:bakid/fitur/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int selectedIndex = 0;
  bool _isLoggingOut = false;

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
    'Jadwal Mengajar',
  ];

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sedang keluar...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Perform logout
      await ref.read(authServiceProvider).logout();

      // Invalidate providers
      ref.invalidate(currentUserProvider);
      ref.invalidate(authStateProvider);

      // Ensure all cleanup is done
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal logout: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
        actions: [
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  colors.primary.withAlpha(25),
                  colors.surface,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primaryContainer,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Admin Bakid',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
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
              onTap: _handleLogout, // Directly call _handleLogout
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
