import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JurnalCard extends StatelessWidget {
  final Map<String, dynamic> jurnal;
  final VoidCallback? onTap;

  const JurnalCard({super.key, required this.jurnal, this.onTap});

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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mataPelajaran?['nama'] ?? 'Mata Pelajaran',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (kelas != null)
                          Text(
                            kelas['nama'] ?? 'Kelas',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onTap,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info Waktu dan Tanggal
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    tanggal != null
                        ? DateFormat('d MMM y', 'id_ID').format(tanggal)
                        : 'Tanggal tidak tersedia',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    hariIndex != null && jadwal?['waktu_mulai'] != null
                        ? '${hari[hariIndex - 1]}, ${jadwal!['waktu_mulai']}-${jadwal['waktu_selesai']}'
                        : 'Waktu tidak tersedia',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Materi
              _buildInfoItem('Materi', jurnal['materi_yang_dipelajari']),

              // Kendala jika ada
              if (jurnal['kendala'] != null &&
                  jurnal['kendala'].toString().isNotEmpty)
                _buildInfoItem('Kendala', jurnal['kendala']),

              // Solusi jika ada
              if (jurnal['solusi'] != null &&
                  jurnal['solusi'].toString().isNotEmpty)
                _buildInfoItem('Solusi', jurnal['solusi']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(value ?? '-', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
