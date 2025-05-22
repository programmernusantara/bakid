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
    final hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final hariIndex = jadwal?['hari_dalam_minggu'] as int?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(100),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.book_1,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kelas?['nama'] ?? 'Kelas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Divider
            Divider(height: 1, color: theme.colorScheme.outline.withAlpha(100)),

            const SizedBox(height: 16),

            // Date and time
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
                  theme: theme,
                ),
                if (hariIndex != null && jadwal?['waktu_mulai'] != null)
                  _buildInfoItem(
                    icon: Iconsax.clock,
                    text:
                        '${hari[hariIndex - 1]}, ${jadwal!['waktu_mulai']}-${jadwal['waktu_selesai']}',
                    theme: theme,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Content sections
            _buildContentSection(
              icon: Iconsax.document_text,
              title: 'Materi',
              content: jurnal['materi_yang_dipelajari'] ?? '-',
              theme: theme,
            ),

            if (jurnal['kendala'] != null &&
                jurnal['kendala'].toString().isNotEmpty)
              _buildContentSection(
                icon: Iconsax.info_circle,
                title: 'Kendala',
                content: jurnal['kendala'],
                theme: theme,
              ),

            if (jurnal['solusi'] != null &&
                jurnal['solusi'].toString().isNotEmpty)
              _buildContentSection(
                icon: Iconsax.lamp_charge,
                title: 'Solusi',
                content: jurnal['solusi'],
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
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection({
    required IconData icon,
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
