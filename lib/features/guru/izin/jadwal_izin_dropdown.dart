import 'package:bakid/features/guru/izin/izin_providers.dart';
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
    final tanggalIzin = ref.watch(izinDateRangeProvider);
    final jadwalFuture = ref.watch(jadwalIzinProvider);

    if (tanggalIzin == null) {
      return const Text('Pilih tanggal izin terlebih dahulu');
    }

    return jadwalFuture.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
      data: (jadwal) {
        if (jadwal.isEmpty) {
          return const Text('Tidak ada jadwal di tanggal tersebut');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...jadwal.map((j) {
              final kelas = j['kelas'] as Map<String, dynamic>?;
              final mapel = j['mata_pelajaran'] as Map<String, dynamic>?;
              return ListTile(
                title: Text('${mapel?['nama'] ?? 'Mata Pelajaran'}'),
                subtitle: Text(
                  'Kelas ${kelas?['nama'] ?? ''} - '
                  '${_dayName(j['hari_dalam_minggu'])} ${j['waktu_mulai']} s/d ${j['waktu_selesai']}',
                ),
                dense: true,
              );
            }),
          ],
        );
      },
    );
  }
}
