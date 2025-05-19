import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JurnalCard extends StatelessWidget {
  final Map<String, dynamic> jurnal;
  final VoidCallback? onEdit;

  const JurnalCard({super.key, required this.jurnal, this.onEdit});

  @override
  Widget build(BuildContext context) {
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan mata pelajaran dan kelas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mataPelajaran?['nama'] ?? 'Mata Pelajaran',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kelas?['nama'] ?? 'Kelas',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                  ),
              ],
            ),

            const Divider(height: 24, thickness: 1),

            // Informasi waktu
            Row(
              children: [
                _buildInfoIconText(
                  icon: Icons.calendar_today,
                  text:
                      tanggal != null
                          ? DateFormat(
                            'EEEE, d MMMM y',
                            'id_ID',
                          ).format(tanggal)
                          : 'Tanggal tidak tersedia',
                ),
                const SizedBox(width: 16),
                _buildInfoIconText(
                  icon: Icons.schedule,
                  text:
                      hariIndex != null && jadwal?['waktu_mulai'] != null
                          ? '${hari[hariIndex - 1]}, ${jadwal!['waktu_mulai']}-${jadwal['waktu_selesai']}'
                          : 'Waktu tidak tersedia',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Konten jurnal
            _buildJournalSection(
              title: 'Materi yang Diajarkan',
              content: jurnal['materi_yang_dipelajari'] ?? '-',
              icon: Icons.book,
            ),

            if (jurnal['kendala'] != null &&
                jurnal['kendala'].toString().isNotEmpty)
              _buildJournalSection(
                title: 'Kendala',
                content: jurnal['kendala'],
                icon: Icons.warning_amber,
              ),

            if (jurnal['solusi'] != null &&
                jurnal['solusi'].toString().isNotEmpty)
              _buildJournalSection(
                title: 'Solusi',
                content: jurnal['solusi'],
                icon: Icons.lightbulb,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIconText({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildJournalSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(content, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
