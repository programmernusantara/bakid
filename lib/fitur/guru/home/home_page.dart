import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/auth/login_screen.dart';
import 'package:bakid/fitur/guru/home/components/announcement_card.dart';
import 'package:bakid/fitur/guru/home/components/empty_state_card.dart';
import 'package:bakid/fitur/guru/home/components/error_card.dart';
import 'package:bakid/fitur/guru/home/components/profile_header.dart';
import 'package:bakid/fitur/guru/home/components/schedule_card.dart';
import 'package:bakid/fitur/guru/home/components/section_header.dart';
import 'package:bakid/fitur/guru/jadwal/jadwal_providers.dart';
import 'package:bakid/fitur/guru/pengumuman/pengumuman_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = user?['profil'] as Map<String, dynamic>?;
    final jadwalAsync = ref.watch(jadwalHariIniProvider);
    final pengumumanAsync = ref.watch(pengumumanProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Iconsax.logout),
              onPressed: _handleLogout,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(profile: profile, user: user),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Jadwal Hari Ini',
                icon: Iconsax.calendar,
              ),
              const SizedBox(height: 12),
              _ScheduleSection(jadwalAsync: jadwalAsync),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Pengumuman Terkini',
                icon: Iconsax.notification_bing,
              ),
              const SizedBox(height: 12),
              _AnnouncementSection(pengumumanAsync: pengumumanAsync),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      // Lakukan logout
      await ref.read(authServiceProvider).logout();

      // Reset provider state
      ref.invalidate(currentUserProvider);
      ref.invalidate(authStateProvider);

      // Navigasi dengan menghapus semua halaman sebelumnya
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
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
}

class _ScheduleSection extends ConsumerWidget {
  final AsyncValue<List<dynamic>> jadwalAsync;

  const _ScheduleSection({required this.jadwalAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return jadwalAsync.when(
      data: (jadwalList) {
        if (jadwalList.isEmpty) {
          return const EmptyStateCard(
            icon: Iconsax.calendar_remove,
            message: 'Tidak ada jadwal mengajar hari ini',
          );
        }
        return Column(
          children:
              jadwalList.map((jadwal) {
                final waktuMulai = jadwal['waktu_mulai'] ?? '';
                final waktuSelesai = jadwal['waktu_selesai'] ?? '';
                final pelajaran = jadwal['mata_pelajaran']?['nama'] ?? '-';
                final kelas = jadwal['kelas']?['nama'] ?? '-';
                return ScheduleCard(
                  subject: pelajaran,
                  kelas: kelas,
                  time: '$waktuMulai - $waktuSelesai',
                );
              }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorCard(message: 'Gagal memuat jadwal: $err'),
    );
  }
}

class _AnnouncementSection extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> pengumumanAsync;

  const _AnnouncementSection({required this.pengumumanAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return pengumumanAsync.when(
      data: (pengumumanList) {
        if (pengumumanList.isEmpty) {
          return const EmptyStateCard(
            icon: Iconsax.note_remove,
            message: 'Tidak ada pengumuman saat ini',
          );
        }
        return Column(
          children:
              pengumumanList.map((pengumuman) {
                return AnnouncementCard(
                  title: pengumuman['judul'] ?? 'Tanpa Judul',
                  content: pengumuman['isi'] ?? '',
                  imageUrl: pengumuman['foto_url'],
                  date:
                      pengumuman['dibuat_pada'] != null
                          ? DateTime.parse(pengumuman['dibuat_pada'])
                          : null,
                );
              }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) =>
              ErrorCard(message: 'Gagal memuat pengumuman: $error'),
    );
  }
}
