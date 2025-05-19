import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/guru/kehadiran/status_absensi_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/features/auth/auth_providers.dart';

class RiwayatAbsensiSiswaPage extends ConsumerStatefulWidget {
  const RiwayatAbsensiSiswaPage({super.key});

  @override
  ConsumerState<RiwayatAbsensiSiswaPage> createState() =>
      _RiwayatAbsensiSiswaPageState();
}

class _RiwayatAbsensiSiswaPageState
    extends ConsumerState<RiwayatAbsensiSiswaPage> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  bool _isLoading = false;
  List<Map<String, dynamic>> _riwayat = [];

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
          .from('rekap_absensi_siswa')
          .select(
            '*, jadwal:jadwal_id(*, kelas:kelas_id(*), mata_pelajaran:mata_pelajaran_id(*))',
          )
          .eq('guru_id', user['profil']['id'])
          .gte('tanggal', DateFormat('yyyy-MM-dd').format(_dateRange.start))
          .lte('tanggal', DateFormat('yyyy-MM-dd').format(_dateRange.end))
          .order('tanggal', ascending: false);

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

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
        _loadRiwayat();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormat('dd MMM yyyy').format(_dateRange.start)} '
                  '- ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDateRange(context),
              ),
            ],
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _riwayat.isEmpty
            ? const Center(child: Text('Tidak ada data absensi'))
            : Expanded(
              child: ListView.builder(
                itemCount: _riwayat.length,
                itemBuilder: (context, index) {
                  final absensi = _riwayat[index];
                  final jadwal = absensi['jadwal'] as Map<String, dynamic>?;
                  final kelas = jadwal?['kelas'] as Map<String, dynamic>?;
                  final mapel =
                      jadwal?['mata_pelajaran'] as Map<String, dynamic>?;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${kelas?['nama'] ?? 'Kelas'} - ${mapel?['nama'] ?? 'Mapel'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'EEEE, dd MMMM yyyy',
                              'id_ID',
                            ).format(DateTime.parse(absensi['tanggal'])),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StatusAbsensiChip(
                                label: 'Hadir',
                                count: absensi['jumlah_hadir'],
                              ),
                              StatusAbsensiChip(
                                label: 'Izin',
                                count: absensi['jumlah_izin'],
                              ),
                              StatusAbsensiChip(
                                label: 'Alpa',
                                count: absensi['jumlah_alpa'],
                              ),
                            ],
                          ),
                          if (absensi['nama_izin'] != null &&
                              absensi['nama_izin'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Izin: ${absensi['nama_izin']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          if (absensi['nama_alpa'] != null &&
                              absensi['nama_alpa'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Alpa: ${absensi['nama_alpa']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }
}
