import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AktivitasGuru {
  final String jadwalId;
  final String namaGuru;
  final String daerah;
  final String kelas;
  final String mataPelajaran;
  final String jamPelajaran;
  final String hari;
  final String statusAbsensi;
  final String statusKegiatan;
  final String jurnal;

  AktivitasGuru({
    required this.jadwalId,
    required this.namaGuru,
    required this.daerah,
    required this.kelas,
    required this.mataPelajaran,
    required this.jamPelajaran,
    required this.hari,
    required this.statusAbsensi,
    required this.statusKegiatan,
    required this.jurnal,
  });

  factory AktivitasGuru.fromMap(Map<String, dynamic> map) {
    return AktivitasGuru(
      jadwalId: map['jadwal_id']?.toString() ?? '',
      namaGuru: map['nama_guru']?.toString() ?? '',
      daerah: map['daerah']?.toString() ?? '',
      kelas: map['kelas']?.toString() ?? '',
      mataPelajaran: map['mata_pelajaran']?.toString() ?? '',
      jamPelajaran: map['jam_pelajaran']?.toString() ?? '',
      hari: map['hari']?.toString() ?? '',
      statusAbsensi: map['status_absensi']?.toString() ?? '',
      statusKegiatan: map['status_kegiatan']?.toString() ?? '',
      jurnal: map['jurnal']?.toString() ?? '',
    );
  }
}

final aktivitasGuruProvider = StreamProvider<List<AktivitasGuru>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('aktivitas_harian_guru_view')
      .stream(primaryKey: ['jadwal_id'])
      .order('jam_pelajaran')
      .map((data) {
        final list = data.map((e) => AktivitasGuru.fromMap(e)).toList();
        list.sort((a, b) => a.jamPelajaran.compareTo(b.jamPelajaran));
        return list;
      });
});

class AktivitasHarianGuru extends ConsumerStatefulWidget {
  const AktivitasHarianGuru({super.key});

  @override
  ConsumerState<AktivitasHarianGuru> createState() =>
      _AktivitasHarianGuruState();
}

class _AktivitasHarianGuruState extends ConsumerState<AktivitasHarianGuru> {
  String selectedFilter = 'Sedang Berlangsung';
  final List<String> filters = ['Sedang Berlangsung', 'Akan Datang', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    final aktivitasStream = ref.watch(aktivitasGuruProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onSelected: (value) {
              setState(() => selectedFilter = value);
            },
            itemBuilder: (context) {
              return filters
                  .map(
                    (filter) => PopupMenuItem<String>(
                      value: filter,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: _statusColor(filter),
                          ),
                          const SizedBox(width: 8),
                          Text(filter),
                        ],
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: aktivitasStream.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
          data: (list) {
            final filteredList =
                list.where((e) {
                  final statusText = _getNormalizedStatus(e.statusKegiatan);
                  return statusText == selectedFilter ||
                      (selectedFilter == 'Selesai' &&
                          (statusText == 'Selesai' ||
                              e.statusAbsensi.contains('Hadir')));
                }).toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada aktivitas $selectedFilter',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(aktivitasGuruProvider),
              color: Theme.of(context).primaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder:
                    (_, index) => _ActivityCard(activity: filteredList[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getNormalizedStatus(String status) {
    if (status.contains('🟢')) return 'Sedang Berlangsung';
    if (status.contains('⏳')) return 'Akan Datang';
    if (status.contains('✅')) return 'Selesai';
    return status;
  }

  Color _statusColor(String status) {
    status = _getNormalizedStatus(status);
    if (status == 'Sedang Berlangsung') return Colors.green;
    if (status == 'Akan Datang') return Colors.orange;
    if (status == 'Selesai') return Colors.blue;
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
            Row(
              children: [
                const Spacer(),
                Chip(
                  backgroundColor: _statusColor(
                    activity.statusKegiatan,
                  ).withAlpha(50),
                  label: Text(
                    _getDisplayStatus(activity.statusKegiatan),
                    style: TextStyle(
                      color: _statusColor(activity.statusKegiatan),
                      fontSize: 12,
                    ),
                  ),
                  avatar: Icon(
                    Icons.circle,
                    size: 12,
                    color: _statusColor(activity.statusKegiatan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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

            // Absensi
            Row(
              children: [
                Icon(Icons.assignment_ind, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Absensi:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Chip(
                  backgroundColor: _absenColor(
                    activity.statusAbsensi,
                  ).withAlpha(50),
                  label: Text(
                    activity.statusAbsensi,
                    style: TextStyle(
                      color: _absenColor(activity.statusAbsensi),
                      fontSize: 12,
                    ),
                  ),
                  avatar: Icon(
                    _absenIcon(activity.statusAbsensi),
                    size: 16,
                    color: _absenColor(activity.statusAbsensi),
                  ),
                ),
              ],
            ),

            // Jurnal
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.book,
                  size: 20,
                  color:
                      activity.jurnal.isEmpty ? Colors.grey : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Jurnal:',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        activity.jurnal.isEmpty
                            ? Colors.grey
                            : Colors.grey[600],
                  ),
                ),
                if (activity.jurnal.isEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Belum diisi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            if (activity.jurnal.isNotEmpty) ...[
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
              color: color.withAlpha(100),
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

  String _getDisplayStatus(String status) {
    if (status.contains('🟢')) return 'Sedang Berlangsung';
    if (status.contains('⏳')) return 'Akan Datang';
    if (status.contains('✅')) return 'Selesai';
    return status;
  }

  Color _statusColor(String status) {
    if (status.contains('🟢')) return Colors.green;
    if (status.contains('⏳')) return Colors.orange;
    if (status.contains('✅')) return Colors.blue;
    return Colors.grey;
  }

  Color _absenColor(String status) {
    if (status.contains('✅')) return Colors.green;
    if (status.contains('⚠️')) return Colors.orange;
    if (status.contains('❌')) return Colors.red;
    if (status.contains('📝')) return Colors.blue;
    if (status.contains('⏳')) return Colors.grey;
    return Colors.grey;
  }

  IconData _absenIcon(String status) {
    if (status.contains('✅')) return Icons.check_circle;
    if (status.contains('⚠️')) return Icons.access_time;
    if (status.contains('❌')) return Icons.cancel;
    if (status.contains('📝')) return Icons.assignment_ind;
    if (status.contains('⏳')) return Icons.timer;
    return Icons.help_outline;
  }
}
