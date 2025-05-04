import 'package:bakid/app/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bakid/core/services/supabase_service.dart';
import 'package:logger/logger.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final logger = Logger();

    Future<void> logout() async {
      try {
        await SupabaseService().signOut();
        logger.i("User has logged out");
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        logger.e("Logout failed: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout gagal: ${e.toString()}')),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) return const SizedBox();

          final supabase = ref.read(supabaseClientProvider);
          return FutureBuilder<Map<String, dynamic>?>(
            future: supabase.fetchStudentProfile(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return const Center(child: Text('Gagal memuat profil'));
              }

              final profile = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildAvatar(profile),
                    const SizedBox(height: 16),
                    const SizedBox(height: 30),
                    _buildProfileInfo(profile),
                    const SizedBox(height: 20),
                    _buildLogoutButton(context, logout),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> profile) {
    return CircleAvatar(
      radius: 80,
      backgroundImage:
          profile['foto_url'] != null
              ? CachedNetworkImageProvider(profile['foto_url'])
              : null,
      child:
          profile['foto_url'] == null
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> profile) {
    final data = [
      {
        'icon': Icons.person,
        'label': 'Nama Lengkap',
        'value': profile['nama_lengkap'],
      },
      {
        'icon': Icons.transgender,
        'label': 'Jenis Kelamin',
        'value': profile['jenis_kelamin'],
      },
      {
        'icon': Icons.place,
        'label': 'Tempat Lahir',
        'value': profile['tempat_lahir'],
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Tanggal Lahir',
        'value': profile['tanggal_lahir'],
      },
      {'icon': Icons.male, 'label': 'Nama Ayah', 'value': profile['nama_ayah']},
      {'icon': Icons.female, 'label': 'Nama Ibu', 'value': profile['nama_ibu']},
      {'icon': Icons.phone, 'label': 'Nomor HP', 'value': profile['nomor_hp']},
      {
        'icon': Icons.location_on,
        'label': 'Alamat',
        'value': profile['alamat'],
      },
      {'icon': Icons.verified, 'label': 'Status', 'value': profile['status']},
      {'icon': Icons.home, 'label': 'Asrama', 'value': profile['asrama']},
      {
        'icon': Icons.leaderboard,
        'label': 'Ketua Asrama',
        'value': profile['ketua_asrama'],
      },
      {
        'icon': Icons.date_range,
        'label': 'Tahun Masuk',
        'value': profile['tahun_masuk'],
      },
      {'icon': Icons.class_, 'label': 'Kelas', 'value': profile['kelas']},
      {
        'icon': Icons.supervisor_account,
        'label': 'Wali Kelas',
        'value': profile['wali_kelas'],
      },
    ];

    return Column(
      children:
          data.map((item) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: Colors.blueGrey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['value']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildLogoutButton(BuildContext context, VoidCallback onLogout) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Keluar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onLogout,
      ),
    );
  }
}
