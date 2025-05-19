import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/guru/absen/absen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RiwayatAbsenPage extends ConsumerStatefulWidget {
  const RiwayatAbsenPage({super.key});

  @override
  ConsumerState<RiwayatAbsenPage> createState() => _RiwayatAbsenPageState();
}

class _RiwayatAbsenPageState extends ConsumerState<RiwayatAbsenPage> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _riwayatAbsen = [];

  @override
  void initState() {
    super.initState();
    _loadRiwayatAbsen();
  }

  Future<void> _loadRiwayatAbsen() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final profilResponse =
          await supabase
              .from('profil_guru')
              .select()
              .eq('user_id', user['id'])
              .maybeSingle();

      if (profilResponse == null) {
        setState(() => _errorMessage = 'Profil guru tidak ditemukan');
        return;
      }

      final guruId = profilResponse['id'];
      final absenService = ref.read(absenServiceProvider);
      final riwayat = await absenService.getRiwayatAbsen(guruId);
      setState(() => _riwayatAbsen = riwayat);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat riwayat absen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'terlambat':
        return 'Terlambat';
      case 'alpa':
        return 'Alpa';
      case 'izin':
        return 'Izin';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hadir':
        return Colors.green;
      case 'terlambat':
        return Colors.orange;
      case 'alpa':
        return Colors.red;
      case 'izin':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRiwayatAbsen,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _riwayatAbsen.isEmpty
              ? const Center(child: Text('Tidak ada riwayat absensi'))
              : ListView.builder(
                itemCount: _riwayatAbsen.length,
                itemBuilder: (context, index) {
                  final absen = _riwayatAbsen[index];
                  final jadwal = absen['jadwal'] ?? {};
                  final mataPelajaran =
                      jadwal['mata_pelajaran']?['nama'] ?? '-';
                  final kelas = jadwal['kelas']?['nama'] ?? '-';
                  final tanggal = DateFormat(
                    'dd MMM yyyy',
                  ).format(DateTime.parse(absen['tanggal']));
                  final waktu = absen['waktu_absen'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(mataPelajaran),
                      subtitle: Text('$kelas • $tanggal'),
                      trailing: Chip(
                        label: Text(
                          _formatStatus(absen['status']),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(absen['status']),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(mataPelajaran),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kelas: $kelas'),
                                    Text('Tanggal: $tanggal'),
                                    Text('Waktu Absen: $waktu'),
                                    Text(
                                      'Status: ${_formatStatus(absen['status'])}',
                                    ),
                                    if (absen['latitude'] != null &&
                                        absen['longitude'] != null)
                                      Text(
                                        'Lokasi: ${absen['latitude']}, ${absen['longitude']}',
                                      ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('TUTUP'),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
