import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/home/components/error_card.dart';
import 'package:bakid/fitur/guru/jadwal/jadwal_providers.dart';
import 'package:bakid/fitur/guru/pengumuman/pengumuman_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'components/profile_header.dart';
import 'components/section_header.dart';
import 'components/schedule_card.dart';
import 'components/announcement_card.dart';
import 'components/empty_state_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = user?['profil'] as Map<String, dynamic>?;
    final jadwalAsync = ref.watch(jadwalHariIniProvider);
    final pengumumanAsync = ref.watch(pengumumanProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Badge(
              // You can add notification count here if needed
              // label: Text('3'),
              child: const Icon(Iconsax.notification),
            ),
            onPressed: () {
              // Navigate to notification page
              Navigator.pushNamed(context, '/notifications');
            },
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
                icon: Iconsax.calendar, // Updated icon
              ),
              const SizedBox(height: 12),
              _ScheduleSection(jadwalAsync: jadwalAsync),
              const SizedBox(height: 24),

              const SectionHeader(
                title: 'Pengumuman Terkini',
                icon: Iconsax.notification_bing, // Updated icon
              ),
              const SizedBox(height: 12),
              _AnnouncementSection(pengumumanAsync: pengumumanAsync),
            ],
          ),
        ),
      ),
    );
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
            icon: Iconsax.calendar_remove, // Updated icon
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
            icon: Iconsax.note_remove, // Updated icon
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
