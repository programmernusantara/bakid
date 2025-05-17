import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifikasiIzinPage extends ConsumerStatefulWidget {
  const VerifikasiIzinPage({super.key});

  @override
  ConsumerState<VerifikasiIzinPage> createState() => _VerifikasiIzinPageState();
}

class _VerifikasiIzinPageState extends ConsumerState<VerifikasiIzinPage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchIzin() async {
    final response = await supabase
        .from('permohonan_izin')
        .select('*, profil_guru(nama_lengkap)')
        .order('dibuat_pada', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateStatus(String id, String status) async {
    await supabase
        .from('permohonan_izin')
        .update({
          'status': status,
          'diperbarui_pada': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    if (mounted) setState(() {});
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
      backgroundColor:
          Colors.grey[200], // Warna abu-abu muda untuk latar belakang
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchIzin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final izinList = snapshot.data!;
          if (izinList.isEmpty) {
            return const Center(child: Text('Tidak ada permohonan izin'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Refresh data
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: izinList.length,
              itemBuilder: (context, index) {
                final izin = izinList[index];
                final guru = izin['profil_guru'];

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
                        // Header nama guru dan status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                guru?['nama_lengkap'] ?? 'Tanpa Nama',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            buildStatusBadge(izin['status']),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Detail info izin
                        _buildInfoRow(
                          Icons.description_outlined,
                          'Jenis Izin',
                          izin['jenis_izin'],
                        ),
                        const Divider(thickness: 1.2),
                        _buildInfoRow(
                          Icons.notes_outlined,
                          'Alasan',
                          izin['alasan'],
                        ),
                        const Divider(thickness: 1.2),
                        _buildInfoRow(
                          Icons.date_range_outlined,
                          'Tanggal Mulai',
                          izin['tanggal_mulai'],
                        ),
                        const Divider(thickness: 1.2),
                        _buildInfoRow(
                          Icons.date_range_outlined,
                          'Tanggal Selesai',
                          izin['tanggal_selesai'],
                        ),
                        const SizedBox(height: 12),
                        // Tombol aksi jika status menunggu
                        if (izin['status'] == 'menunggu')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: const Text('Setujui'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    () => updateStatus(izin['id'], 'disetujui'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                label: const Text('Tolak'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    () => updateStatus(izin['id'], 'ditolak'),
                              ),
                            ],
                          ),
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

  Widget _buildInfoRow(IconData icon, String label, String? value) {
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
                    text: value ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
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
