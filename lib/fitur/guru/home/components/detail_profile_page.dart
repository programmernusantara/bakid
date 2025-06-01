import 'package:flutter/material.dart';

class DetailProfilePage extends StatelessWidget {
  final Map<String, dynamic> profile;

  const DetailProfilePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Detail Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture Card
            Card(
              color: Colors.white,
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withAlpha(100),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            profile['foto_url'] != null
                                ? NetworkImage(profile['foto_url'])
                                : null,
                        backgroundColor: Colors.grey[200],
                        child:
                            profile['foto_url'] == null
                                ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey[600],
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name and Position in same style as other info
                    _buildInfoTile(
                      icon: Icons.person_outline,
                      title: 'Nama Lengkap',
                      value: profile['nama_lengkap'] ?? 'Guru',
                    ),
                    const Divider(height: 24),
                    if (profile['jabatan'] != null)
                      _buildInfoTile(
                        icon: Icons.work_outline,
                        title: 'Jabatan',
                        value: profile['jabatan'],
                      ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Kontak',
                      value: profile['nomor_telepon'] ?? 'Tidak tersedia',
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.location_city_outlined,
                      title: 'Asal Daerah',
                      value: profile['asal_daerah'] ?? 'Tidak tersedia',
                    ),
                    const Divider(height: 1),

                    _buildInfoTile(
                      icon: Icons.home_outlined,
                      title: 'Alamat',
                      value: profile['alamat'] ?? 'Tidak tersedia',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
