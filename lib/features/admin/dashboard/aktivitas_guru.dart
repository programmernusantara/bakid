import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Model Aktivitas Guru TANPA fotoGuru
class AktivitasGuru {
  final String jadwalId;
  final String namaGuru;
  final String hari;
  final String jamPelajaran;
  final String kelas;
  final String mataPelajaran;
  final String statusKegiatan;
  final String statusAbsensi;
  final String jurnal;
  final String daerah;

  AktivitasGuru({
    required this.jadwalId,
    required this.namaGuru,
    required this.hari,
    required this.jamPelajaran,
    required this.kelas,
    required this.mataPelajaran,
    required this.statusKegiatan,
    required this.statusAbsensi,
    required this.jurnal,
    required this.daerah,
  });

  factory AktivitasGuru.fromMap(Map<String, dynamic> map) {
    return AktivitasGuru(
      jadwalId: map['jadwal_id'] ?? '',
      namaGuru: map['nama_guru'] ?? '',
      hari: map['hari'] ?? '',
      jamPelajaran: map['jam_pelajaran'] ?? '',
      kelas: map['kelas'] ?? '',
      mataPelajaran: map['mata_pelajaran'] ?? '',
      statusKegiatan: map['status_kegiatan'] ?? '',
      statusAbsensi: map['status_absensi'] ?? '',
      jurnal: map['jurnal'] ?? '',
      daerah: map['daerah'] ?? '',
    );
  }
}

// Provider data Supabase
final aktivitasGuruProvider = StreamProvider.family
    .autoDispose<List<AktivitasGuru>, String>((ref, statusFilter) {
      final supabase = Supabase.instance.client;
      return supabase
          .from('aktivitas_harian_guru_view')
          .stream(primaryKey: ['jadwal_id'])
          .order('jam_pelajaran')
          .map((data) {
            final list = data.map((e) => AktivitasGuru.fromMap(e)).toList();
            if (statusFilter == 'Semua') return list;
            return list
                .where((e) => e.statusKegiatan.contains(statusFilter))
                .toList();
          });
    });

// Halaman Aktivitas Harian
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
  Widget build(BuildContext context) {
    final aktivitasStream = ref.watch(aktivitasGuruProvider(selectedFilter));

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Padding(
        padding: const EdgeInsets.all(10),
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
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final boldStyle = textStyle?.copyWith(fontWeight: FontWeight.bold);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.class_, 'Kelas', activity.kelas, bold: true),
            const SizedBox(height: 8),
            _infoRow(Icons.book, 'Mata Pelajaran', activity.mataPelajaran),
            const Divider(thickness: 1.2, height: 24),
            _infoRow(Icons.calendar_today, 'Hari', activity.hari),
            _infoRow(Icons.access_time, 'Jam', activity.jamPelajaran),
            const Divider(thickness: 1.2, height: 24),
            _infoRow(Icons.person, 'Guru', activity.namaGuru),
            _infoRow(Icons.location_on, 'Daerah', activity.daerah),
            const Divider(thickness: 1.2, height: 24),
            _infoRow(
              Icons.event_available,
              'Status Kegiatan',
              activity.statusKegiatan,
            ),
            _infoRow(
              Icons.check_circle_outline,
              'Status Absensi',
              activity.statusAbsensi,
            ),
            const Divider(thickness: 1.2, height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jurnal Mengajar', style: boldStyle),
                      const SizedBox(height: 4),
                      Text(activity.jurnal, style: textStyle),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
