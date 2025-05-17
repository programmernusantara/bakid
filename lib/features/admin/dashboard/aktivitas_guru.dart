import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Model Aktivitas Guru
class AktivitasGuru {
  final String jadwalId;
  final String guru;
  final String fotoGuru;
  final String hari;
  final String jamPelajaran;
  final String kelas;
  final String mataPelajaran;
  final String statusJadwal;
  final String statusKehadiran;
  final String jurnalMengajar;
  final String daerahAsal;

  AktivitasGuru({
    required this.jadwalId,
    required this.guru,
    required this.fotoGuru,
    required this.hari,
    required this.jamPelajaran,
    required this.kelas,
    required this.mataPelajaran,
    required this.statusJadwal,
    required this.statusKehadiran,
    required this.jurnalMengajar,
    required this.daerahAsal,
  });

  factory AktivitasGuru.fromMap(Map<String, dynamic> map) {
    return AktivitasGuru(
      jadwalId: map['jadwal_id'] ?? '',
      guru: map['guru'] ?? '',
      fotoGuru: map['foto_guru'] ?? '',
      hari: map['hari'] ?? '',
      jamPelajaran: map['jam_pelajaran'] ?? '',
      kelas: map['kelas'] ?? '',
      mataPelajaran: map['mata_pelajaran'] ?? '',
      statusJadwal: map['status_jadwal'] ?? '⏳ Akan Datang',
      statusKehadiran: map['status_kehadiran'] ?? '🔵 Belum Absen',
      jurnalMengajar: map['jurnal_mengajar'] ?? 'Belum diisi',
      daerahAsal: map['daerah_asal'] ?? '',
    );
  }
}

// Stream Provider dengan filter status
final aktivitasGuruProvider = StreamProvider.family
    .autoDispose<List<AktivitasGuru>, String>((ref, statusFilter) {
      final supabase = Supabase.instance.client;
      return supabase
          .from('aktivitas_guru_harian')
          .stream(primaryKey: ['jadwal_id'])
          .order('jam_pelajaran')
          .map((data) {
            final list = data.map((e) => AktivitasGuru.fromMap(e)).toList();
            if (statusFilter == 'Semua') return list;
            return list
                .where((e) => e.statusJadwal.contains(statusFilter))
                .toList();
          });
    });

class AktivitasHarianGuru extends ConsumerStatefulWidget {
  const AktivitasHarianGuru({super.key});

  @override
  ConsumerState<AktivitasHarianGuru> createState() =>
      _AktivitasHarianGuruState();
}

class _AktivitasHarianGuruState extends ConsumerState<AktivitasHarianGuru> {
  String selectedFilter = 'Semua';
  final List<String> filters = [
    'Semua',
    '🟢 Sedang Berlangsung',
    '⏳ Akan Datang',
    '✅ Selesai',
  ];

  @override
  @override
  Widget build(BuildContext context) {
    final aktivitasStream = ref.watch(aktivitasGuruProvider(selectedFilter));

    return Scaffold(
      backgroundColor: Colors.grey[100], // Latar abu soft

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String>(
                value: selectedFilter,
                dropdownColor: Colors.white,
                items:
                    filters
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e.replaceAll(RegExp(r'[^\w\s]'), '').trim(),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedFilter = val);
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: aktivitasStream.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stack) =>
                        Center(child: Text('Terjadi kesalahan: $error')),
                data: (activities) {
                  if (activities.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada aktivitas dengan filter ini'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh:
                        () async =>
                            ref.refresh(aktivitasGuruProvider(selectedFilter)),
                    child: ListView.separated(
                      itemCount: activities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _buildActivityCard(context, activity);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AktivitasGuru activity) {
    return Card(
      color: Colors.white, // Card warna putih
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris kelas, mapel, hari, jam pelajaran
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.kelas,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.mataPelajaran,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      activity.hari,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      activity.jamPelajaran,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[300]),
            // Guru & daerah asal
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        activity.fotoGuru.isNotEmpty
                            ? NetworkImage(activity.fotoGuru)
                            : null,
                    backgroundColor: Colors.grey.shade200,
                    child:
                        activity.fotoGuru.isEmpty
                            ? const Icon(Icons.person, size: 28)
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guru',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        Text(
                          activity.guru,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    activity.daerahAsal,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[300]),
            // Status chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildStatusChip(activity.statusJadwal),
                  _buildStatusChip(activity.statusKehadiran),
                ],
              ),
            ),
            Divider(color: Colors.grey[300]),
            // Jurnal mengajar
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jurnal Mengajar',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      activity.jurnalMengajar,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    if (status.contains('🟢')) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else if (status.contains('⏳')) {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if (status.contains('✅')) {
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    } else if (status.contains('⚠️')) {
      backgroundColor = Colors.yellow.shade100;
      textColor = Colors.yellow.shade800;
    } else if (status.contains('❌')) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
    } else if (status.contains('🔵')) {
      backgroundColor = Colors.blueGrey.shade100;
      textColor = Colors.blueGrey.shade800;
    } else if (status.contains('📋')) {
      backgroundColor = Colors.purple.shade100;
      textColor = Colors.purple.shade800;
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade800;
    }

    return Chip(
      label: Text(
        status.replaceAll(RegExp(r'[^\w\s]'), '').trim(),
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}
