import 'package:bakid/features/guru/kehadiran/absensi_siswa_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JadwalAbsensiDropdown extends ConsumerWidget {
  const JadwalAbsensiDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwal = ref.watch(absensiSiswaJadwalProvider);

    return jadwal.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
      data: (data) {
        if (data.isEmpty) {
          return const Text('Tidak ada jadwal mengajar hari ini');
        }

        return DropdownButtonFormField<Map<String, dynamic>>(
          value: ref.watch(absensiSiswaSelectedJadwalProvider) ?? data.first,
          decoration: const InputDecoration(
            labelText: 'Pilih Jadwal Mengajar',
            border: OutlineInputBorder(),
          ),
          items:
              data.map((jadwal) {
                final kelas = jadwal['kelas'] as Map<String, dynamic>?;
                final mapel = jadwal['mata_pelajaran'] as Map<String, dynamic>?;
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: jadwal,
                  child: Text(
                    '${kelas?['nama'] ?? 'Kelas'} - ${mapel?['nama'] ?? 'Mapel'} '
                    '(${jadwal['waktu_mulai']} - ${jadwal['waktu_selesai']})',
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(absensiSiswaSelectedJadwalProvider.notifier).state =
                  value;
            }
          },
        );
      },
    );
  }
}
