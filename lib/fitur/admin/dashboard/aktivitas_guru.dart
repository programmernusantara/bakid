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
      jurnal: map['jurnal']?.toString() ?? 'Belum diisi',
    );
  }
}

final aktivitasGuruProvider = StreamProvider<List<AktivitasGuru>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('aktivitas_harian_guru_view')
      .stream(primaryKey: ['jadwal_id'])
      .order('jam_pelajaran') // Menggunakan jam_pelajaran yang tersedia
      .map((data) {
        // Konversi ke model
        final list = data.map((e) => AktivitasGuru.fromMap(e)).toList();

        // Urutkan secara manual jika diperlukan
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
  String selectedFilter = '🟢 Sedang Berlangsung';
  final List<String> filters = [
    '🟢 Sedang Berlangsung',
    '⏳ Akan Datang',
    '✅ Selesai',
  ];

  String _cleanFilterText(String filter) {
    return filter.replaceAll(RegExp(r'[^a-zA-Z ]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final aktivitasStream = ref.watch(aktivitasGuruProvider);

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
                _cleanFilterText(selectedFilter),
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
          error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
          data: (list) {
            final filteredList =
                list.where((e) => e.statusKegiatan == selectedFilter).toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada aktivitas ${_cleanFilterText(selectedFilter)}',
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
                  Text(_cleanFilterText(filter)),
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
    if (status.contains('🟢')) return Colors.green;
    if (status.contains('⏳')) return Colors.orange;
    if (status.contains('✅')) return Colors.blue;
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(activity.statusKegiatan).withAlpha(100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(activity.statusKegiatan),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    activity.statusKegiatan,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusColor(activity.statusKegiatan),
                      fontWeight: FontWeight.bold,
                    ),
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
                    color: _absenColor(activity.statusAbsensi).withAlpha(100),
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

            if (activity.jurnal.isNotEmpty &&
                activity.jurnal != 'Belum diisi') ...[
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
