import 'package:bakid/features/guru/izin/izin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final tanggalIzin = ref.watch(izinDateRangeProvider);
    final jadwalFuture = ref.watch(jadwalIzinProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tanggalIzin != null)
          Text(
            'Rentang: ${DateFormat('dd/MM/yyyy').format(tanggalIzin.start)} '
            '- ${DateFormat('dd/MM/yyyy').format(tanggalIzin.end)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        jadwalFuture.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
          data: (jadwal) {
            if (jadwal.isEmpty) {
              return const Column(
                children: [
                  Text('Tidak ada jadwal yang memerlukan izin'),
                  SizedBox(height: 4),
                  Text(
                    'Semua jadwal di rentang tanggal ini sudah memiliki izin aktif',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              );
            }

            // Kelompokkan jadwal per hari
            final jadwalPerHari = <int, List<Map<String, dynamic>>>{};
            for (final j in jadwal) {
              final hari = j['hari_dalam_minggu'];
              jadwalPerHari.putIfAbsent(hari, () => []).add(j);
            }

            return Column(
              children:
                  jadwalPerHari.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayName(entry.key),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...entry.value.map((j) {
                          final kelas = j['kelas'] as Map<String, dynamic>?;
                          final mapel =
                              j['mata_pelajaran'] as Map<String, dynamic>?;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${mapel?['nama'] ?? 'Mata Pelajaran'}',
                            ),
                            subtitle: Text(
                              'Kelas ${kelas?['nama'] ?? ''} - '
                              '${j['waktu_mulai']} s/d ${j['waktu_selesai']}',
                            ),
                            dense: true,
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}
