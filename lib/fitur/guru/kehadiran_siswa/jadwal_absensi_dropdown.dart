import 'package:bakid/fitur/guru/kehadiran_siswa/absensi_siswa_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class JadwalAbsensiDropdown extends ConsumerWidget {
  const JadwalAbsensiDropdown({super.key});

  String _formatTime(String time) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse('1970-01-01 $time'));
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jadwal = ref.watch(absensiSiswaJadwalProvider);

    return jadwal.when(
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
      error:
          (error, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Text(
              'Error: $error',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          ),
      data: (data) {
        if (data.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_today, size: 36, color: Colors.grey[500]),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada jadwal mengajar hari ini',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }

        final selectedJadwal =
            ref.watch(absensiSiswaSelectedJadwalProvider) ?? data.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Jadwal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  value: selectedJadwal,
                  isExpanded: true,
                  items:
                      data.map((jadwal) {
                        final mapel = jadwal['mata_pelajaran']?['nama'] ?? '-';
                        final kelas = jadwal['kelas']?['nama'] ?? '-';
                        final mulai = _formatTime(jadwal['waktu_mulai'] ?? '');
                        final selesai = _formatTime(
                          jadwal['waktu_selesai'] ?? '',
                        );
                        return DropdownMenuItem(
                          value: jadwal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$mapel - $kelas ($mulai - $selesai)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(absensiSiswaSelectedJadwalProvider.notifier)
                          .state = value;
                    }
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
