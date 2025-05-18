import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

final aktivitasGuruProvider = StreamProvider.family
    .autoDispose<List<AktivitasGuru>, String>((ref, filter) {
      final supabase = Supabase.instance.client;
      return supabase
          .from('aktivitas_harian_guru_view')
          .stream(primaryKey: ['jadwal_id'])
          .order('jam_pelajaran')
          .map((data) {
            final list = data.map((e) => AktivitasGuru.fromMap(e)).toList();
            if (filter == 'Semua') return list;
            return list
                .where((e) => e.statusKegiatan.contains(filter))
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
    'Sedang Berlangsung',
    'Akan Datang',
    'Selesai',
  ];

  @override
  Widget build(BuildContext context) {
    final aktivitasStream = ref.watch(aktivitasGuruProvider(selectedFilter));

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                selectedFilter,
                style: const TextStyle(color: Colors.black),
              ),
              selected: true,
              onSelected: (_) => _showFilterMenu(context),
              avatar: const Icon(
                Icons.filter_list,
                size: 18,
                color: Colors.black,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.grey[200],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: aktivitasStream.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
          data:
              (list) =>
                  list.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada aktivitas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            if (selectedFilter != 'Semua')
                              TextButton(
                                onPressed:
                                    () => setState(
                                      () => selectedFilter = 'Semua',
                                    ),
                                child: const Text('Tampilkan Semua'),
                              ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(aktivitasGuruProvider(selectedFilter));
                        },
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          itemCount: list.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder:
                              (_, i) => _ActivityCard(activity: list[i]),
                        ),
                      ),
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items:
          filters.map((filter) {
            return PopupMenuItem<String>(
              value: filter,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: _statusColor(filter)),
                  const SizedBox(width: 12),
                  Text(filter),
                ],
              ),
            );
          }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() => selectedFilter = value);
      }
    });
  }

  Color _statusColor(String status) {
    if (status.contains('Berlangsung')) return Colors.green;
    if (status.contains('Datang')) return Colors.orange;
    if (status.contains('Selesai')) return Colors.blue;
    return Colors.grey;
  }
}

class _ActivityCard extends StatelessWidget {
  final AktivitasGuru activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris pertama - Status di pojok kanan atas
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      _statusColor(activity.statusKegiatan),
                      Colors.white,
                      0.9,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(activity.statusKegiatan),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activity.statusKegiatan,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informasi utama
            _buildInfoRow(
              icon: Icons.class_,
              label: 'Kelas',
              value: activity.kelas,
              color: Colors.blue[700]!,
            ),
            _buildInfoRow(
              icon: Icons.menu_book,
              label: 'Mata Pelajaran',
              value: activity.mataPelajaran,
              color: Colors.purple[700]!,
            ),

            // Hari dan Jam setelah Mata Pelajaran
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Hari',
              value: activity.hari,
              color: Colors.green[700]!,
            ),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Jam',
              value: activity.jamPelajaran,
              color: Colors.amber[700]!,
            ),

            _buildInfoRow(
              icon: Icons.person,
              label: 'Guru',
              value: activity.namaGuru,
              color: Colors.teal[700]!,
            ),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Daerah',
              value: activity.daerah,
              color: Colors.deepOrange[700]!,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Absensi dengan label dan ikon
            Row(
              children: [
                Icon(Icons.assignment_ind, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Absensi:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      _absenColor(activity.statusAbsensi),
                      Colors.white,
                      0.9,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _absenColor(activity.statusAbsensi),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _absenIcon(activity.statusAbsensi),
                        size: 16,
                        color: _absenColor(activity.statusAbsensi),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activity.statusAbsensi,
                        style: TextStyle(
                          fontSize: 12,
                          color: _absenColor(activity.statusAbsensi),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Jurnal dengan ikon
            if (activity.jurnal.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.book, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Jurnal:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activity.jurnal,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color.lerp(color, Colors.white, 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status.contains('Berlangsung')) return Colors.green;
    if (status.contains('Datang')) return Colors.orange;
    if (status.contains('Selesai')) return Colors.blue;
    return Colors.grey;
  }

  Color _absenColor(String status) {
    if (status.contains('Hadir')) return Colors.green;
    if (status.contains('Terlambat')) return Colors.orange;
    if (status.contains('Alpa')) return Colors.red;
    if (status.contains('Izin')) return Colors.blue;
    return Colors.grey;
  }

  IconData _absenIcon(String status) {
    if (status.contains('Hadir')) return Icons.check_circle;
    if (status.contains('Terlambat')) return Icons.access_time;
    if (status.contains('Alpa')) return Icons.cancel;
    if (status.contains('Izin')) return Icons.assignment_ind;
    return Icons.help_outline;
  }
}
