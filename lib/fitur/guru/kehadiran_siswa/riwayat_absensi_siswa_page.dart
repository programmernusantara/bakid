import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RiwayatAbsensiSiswaPage extends ConsumerStatefulWidget {
  const RiwayatAbsensiSiswaPage({super.key});

  @override
  ConsumerState<RiwayatAbsensiSiswaPage> createState() =>
      _RiwayatAbsensiSiswaPageState();
}

class _RiwayatAbsensiSiswaPageState
    extends ConsumerState<RiwayatAbsensiSiswaPage> {
  final DateTimeRange _dateRange = DateTimeRange(
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

      setState(() => _riwayat = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: RefreshIndicator(
        onRefresh: _loadRiwayat,
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_riwayat.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat absensi',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadRiwayat,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _riwayat.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final absensi = _riwayat[index];
        final jadwal = absensi['jadwal'] as Map<String, dynamic>?;
        final kelas = jadwal?['kelas'] as Map<String, dynamic>?;
        final mapel = jadwal?['mata_pelajaran'] as Map<String, dynamic>?;

        return _buildAbsensiCard(theme, absensi, kelas, mapel);
      },
    );
  }

  Widget _buildAbsensiCard(
    ThemeData theme,
    Map<String, dynamic> absensi,
    Map<String, dynamic>? kelas,
    Map<String, dynamic>? mapel,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${kelas?['nama'] ?? 'Kelas'} • ${mapel?['nama'] ?? 'Mapel'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                DateFormat(
                  'dd/MM/yy',
                ).format(DateTime.parse(absensi['tanggal'])),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat(
              'EEEE',
              'id_ID',
            ).format(DateTime.parse(absensi['tanggal'])),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(absensi),
          if (absensi['nama_izin']?.toString().isNotEmpty ?? false)
            _buildAdditionalInfo('Izin', absensi['nama_izin']),
          if (absensi['nama_alpa']?.toString().isNotEmpty ?? false)
            _buildAdditionalInfo('Alpa', absensi['nama_alpa']),
        ],
      ),
    );
  }

  Widget _buildStatusRow(Map<String, dynamic> absensi) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusPill('Hadir', absensi['jumlah_hadir'], Colors.green),
        _buildStatusPill('Izin', absensi['jumlah_izin'], Colors.orange),
        _buildStatusPill('Alpa', absensi['jumlah_alpa'], Colors.red),
      ],
    );
  }

  Widget _buildStatusPill(String label, dynamic count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
