import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Extension method untuk capitalize string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class VerifikasiIzinPage extends ConsumerStatefulWidget {
  const VerifikasiIzinPage({super.key});

  @override
  ConsumerState<VerifikasiIzinPage> createState() => _VerifikasiIzinPageState();
}

class _VerifikasiIzinPageState extends ConsumerState<VerifikasiIzinPage> {
  final supabase = Supabase.instance.client;
  String selectedStatus = 'menunggu'; // Default filter status

  Future<List<Map<String, dynamic>>> fetchIzin() async {
    final response = await supabase
        .from('permohonan_izin')
        .select('''
          *, 
          profil_guru(nama_lengkap, asal_daerah),
          jadwal_mengajar(
            waktu_mulai, 
            waktu_selesai, 
            hari_dalam_minggu,
            kelas(nama),
            mata_pelajaran(nama)
          )
        ''')
        .eq('status', selectedStatus)
        .order('dibuat_pada', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateStatus(
    String id,
    String status,
    String? catatanAdmin,
  ) async {
    await supabase
        .from('permohonan_izin')
        .update({
          'status': status,
          'catatan_admin': catatanAdmin,
          'diperbarui_pada': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    if (mounted) setState(() {});
  }

  String _convertHari(int hari) {
    switch (hari) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Tidak Diketahui';
    }
  }

  Widget buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'disetujui':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Disetujui ✅';
        break;
      case 'ditolak':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'Ditolak ❌';
        break;
      default:
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'Menunggu ⏳';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onSelected: (value) {
              setState(() {
                selectedStatus = value;
              });
            },
            itemBuilder: (context) {
              return ['menunggu', 'disetujui', 'ditolak']
                  .map(
                    (status) => PopupMenuItem<String>(
                      value: status,
                      child: Text(status.capitalize()),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchIzin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final izinList = snapshot.data!;
          if (izinList.isEmpty) {
            return const Center(
              child: Text('Tidak ada permohonan izin dengan status ini'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: izinList.length,
              itemBuilder: (context, index) {
                final izin = izinList[index];
                final guru = izin['profil_guru'] as Map<String, dynamic>? ?? {};
                final jadwal =
                    izin['jadwal_mengajar'] as Map<String, dynamic>? ?? {};
                final kelas = jadwal['kelas'] as Map<String, dynamic>? ?? {};
                final mataPelajaran =
                    jadwal['mata_pelajaran'] as Map<String, dynamic>? ?? {};

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    guru['nama_lengkap'] ?? 'Tanpa Nama',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Daerah: ${guru['asal_daerah'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            buildStatusBadge(izin['status']),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Informasi Jadwal
                        if (jadwal.isNotEmpty) ...[
                          const Text(
                            'Jadwal yang Diizin:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.school,
                            'Kelas',
                            kelas['nama'] ?? '-',
                          ),
                          _buildInfoRow(
                            Icons.menu_book,
                            'Mata Pelajaran',
                            mataPelajaran['nama'] ?? '-',
                          ),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Hari',
                            _convertHari(jadwal['hari_dalam_minggu'] ?? 0),
                          ),
                          _buildInfoRow(
                            Icons.access_time,
                            'Jam',
                            '${jadwal['waktu_mulai']} - ${jadwal['waktu_selesai']}',
                          ),
                          const Divider(),
                        ],

                        // Informasi Izin
                        _buildInfoRow(
                          Icons.description,
                          'Jenis Izin',
                          izin['jenis_izin'],
                        ),
                        _buildInfoRow(Icons.note, 'Alasan', izin['alasan']),
                        _buildInfoRow(
                          Icons.date_range,
                          'Tanggal Efektif',
                          izin['tanggal_efektif']?.toString() ?? '-',
                        ),

                        // Catatan Admin jika ada
                        if (izin['catatan_admin'] != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            Icons.admin_panel_settings,
                            'Catatan Admin',
                            izin['catatan_admin'],
                          ),
                        ],

                        // Tombol Aksi untuk permohonan yang menunggu
                        if (izin['status'] == 'menunggu') ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Tolak'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    () => _showCatatanDialog(
                                      izin['id'],
                                      'ditolak',
                                      currentCatatan: izin['catatan_admin'],
                                    ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Setujui'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    () => _showCatatanDialog(
                                      izin['id'],
                                      'disetujui',
                                      currentCatatan: izin['catatan_admin'],
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCatatanDialog(String id, String status, {String? currentCatatan}) {
    final catatanController = TextEditingController(text: currentCatatan);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            status == 'disetujui' ? 'Setujui Permohonan' : 'Tolak Permohonan',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status == 'disetujui'
                    ? 'Berikan catatan untuk guru (opsional):'
                    : 'Berikan alasan penolakan:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catatanController,
                decoration: InputDecoration(
                  hintText: 'Masukkan catatan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                updateStatus(
                  id,
                  status,
                  catatanController.text.isNotEmpty
                      ? catatanController.text
                      : null,
                );
                Navigator.pop(context);
              },
              child: Text(status == 'disetujui' ? 'Setujui' : 'Tolak'),
            ),
          ],
        );
      },
    );
  }
}
