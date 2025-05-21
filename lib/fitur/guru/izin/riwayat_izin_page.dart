import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/guru/izin/status_izin_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';

class RiwayatIzinPage extends ConsumerStatefulWidget {
  const RiwayatIzinPage({super.key});

  @override
  ConsumerState<RiwayatIzinPage> createState() => _RiwayatIzinPageState();
}

class _RiwayatIzinPageState extends ConsumerState<RiwayatIzinPage> {
  List<Map<String, dynamic>> _riwayat = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user['profil'] == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);

      final data = await supabase
          .from('permohonan_izin')
          .select()
          .eq('guru_id', user['profil']['id'])
          .order('dibuat_pada', ascending: false);

      setState(() {
        _riwayat = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _riwayat.isEmpty
        ? const Center(child: Text('Belum ada riwayat izin'))
        : ListView.builder(
          itemCount: _riwayat.length,
          itemBuilder: (context, index) {
            final izin = _riwayat[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          izin['jenis_izin'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        StatusIzinChip(status: izin['status']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(DateTime.parse(izin['tanggal_mulai']))} '
                      '- ${DateFormat('dd MMM yyyy').format(DateTime.parse(izin['tanggal_selesai']))}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alasan: ${izin['alasan']}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (izin['catatan_admin'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Catatan Admin: ${izin['catatan_admin']}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
  }
}
