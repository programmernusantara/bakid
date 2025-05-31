import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class JurnalCard extends StatelessWidget {
  final Map<String, dynamic> jurnal;

  const JurnalCard({super.key, required this.jurnal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jadwal = jurnal['jadwal_mengajar'] as Map<String, dynamic>?;
    final mataPelajaran = jadwal?['mata_pelajaran'] as Map<String, dynamic>?;
    final kelas = jadwal?['kelas'] as Map<String, dynamic>?;
    final tanggal = DateTime.tryParse(jurnal['tanggal'] ?? '');

    // Warna natural untuk icon
    const Color primaryIconColor = Color(0xFF6B7280); // Abu-abu natural
    const Color secondaryIconColor = Color(0xFF9CA3AF); // Abu-abu lebih muda
    const Color accentIconColor = Color(0xFF4B5563); // Abu-abu lebih gelap

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan warna icon natural
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6), // Background sangat soft
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.book_1,
                    size: 20,
                    color: accentIconColor, // Warna lebih gelap untuk kontras
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mataPelajaran?['nama'] ?? 'Mata Pelajaran',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(
                            0xFF111827,
                          ), // Warna teks gelap natural
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kelas?['nama'] ?? 'Kelas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryIconColor, // Warna teks sekunder
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Divider dengan warna natural
            Divider(height: 1, color: const Color(0xFFE5E7EB)),

            const SizedBox(height: 16),

            // Info item dengan warna icon konsisten
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoItem(
                  icon: Iconsax.calendar_1,
                  text:
                      tanggal != null
                          ? DateFormat('d MMM y', 'id_ID').format(tanggal)
                          : 'Tanggal tidak tersedia',
                  iconColor: primaryIconColor,
                  theme: theme,
                ),
                if (jadwal?['waktu_mulai'] != null)
                  _buildInfoItem(
                    icon: Iconsax.clock,
                    text:
                        '${jadwal!['waktu_mulai']}-${jadwal['waktu_selesai']}',
                    iconColor: primaryIconColor,
                    theme: theme,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Content sections dengan warna icon berbeda sesuai kategori
            _buildContentSection(
              icon: Iconsax.document_text,
              title: 'Materi',
              content: jurnal['materi_yang_dipelajari'] ?? '-',
              iconColor: const Color(0xFF3B82F6), // Biru natural untuk materi
              theme: theme,
            ),

            if (jurnal['kendala']?.toString().isNotEmpty ?? false)
              _buildContentSection(
                icon: Iconsax.info_circle,
                title: 'Kendala',
                content: jurnal['kendala'],
                iconColor: const Color(
                  0xFFEF4444,
                ), // Merah natural untuk kendala
                theme: theme,
              ),

            if (jurnal['solusi']?.toString().isNotEmpty ?? false)
              _buildContentSection(
                icon: Iconsax.lamp_charge,
                title: 'Solusi',
                content: jurnal['solusi'],
                iconColor: const Color(
                  0xFF10B981,
                ), // Hijau natural untuk solusi
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7280), // Warna teks natural
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827), // Warna teks gelap natural
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), // Background sangat soft
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: const Color(0xFF374151), // Warna teks natural
              ),
            ),
          ),
        ],
      ),
    );
  }
}
