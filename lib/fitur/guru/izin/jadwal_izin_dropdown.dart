// jadwal_izin_dropdown.dart
import 'package:bakid/fitur/guru/izin/izin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JadwalIzinDropdown extends ConsumerWidget {
  const JadwalIzinDropdown({super.key});

  String _dayName(int day) {
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[day];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwalFuture = ref.watch(jadwalHariIniProvider);

    return jadwalFuture.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
      data: (jadwal) {
        if (jadwal.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.schedule, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Anda tidak mempunyai jadwal untuk izin',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Semua jadwal di rentang tanggal ini sudah memiliki izin aktif',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Group schedules by day
        final jadwalPerHari = <int, List<Map<String, dynamic>>>{};
        for (final j in jadwal) {
          final hari = j['hari_dalam_minggu'];
          jadwalPerHari.putIfAbsent(hari, () => []).add(j);
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  jadwalPerHari.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayName(entry.key),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map((j) {
                          final kelas = j['kelas'] as Map<String, dynamic>?;
                          final mapel =
                              j['mata_pelajaran'] as Map<String, dynamic>?;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${mapel?['nama'] ?? 'Mata Pelajaran'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kelas ${kelas?['nama'] ?? ''} - '
                                  '${j['waktu_mulai']} s/d ${j['waktu_selesai']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}
