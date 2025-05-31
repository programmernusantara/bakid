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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRefresh();
    });
  }

  Future<void> _checkForRefresh() async {
    final shouldRefresh = ModalRoute.of(context)?.settings.arguments as bool?;
    if (shouldRefresh ?? false) {
      await _loadRiwayat();
    }
  }

  Future<void> _loadRiwayat() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user['profil'] == null) return;

      final supabase = ref.read(supabaseProvider);

      final data = await supabase
          .from('permohonan_izin')
          .select('''
            *, 
            jadwal:jadwal_id(
              *, 
              kelas:kelas_id(*), 
              mata_pelajaran:mata_pelajaran_id(*)
            )
          ''')
          .eq('guru_id', user['profil']['id'])
          .order('dibuat_pada', ascending: false);

      if (mounted) {
        setState(() {
          _riwayat = List<Map<String, dynamic>>.from(data);
        });
      }
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body:
          _isLoading && !_isRefreshing
              ? const Center(child: CircularProgressIndicator())
              : _riwayat.isEmpty
              ? RefreshIndicator(
                onRefresh: _loadRiwayat,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat izin',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadRiwayat,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),

                            child: const Text('Muat Ulang'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  setState(() => _isRefreshing = true);
                  await _loadRiwayat();
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _riwayat.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final izin = _riwayat[index];
                    final jadwal = izin['jadwal'] as Map<String, dynamic>?;
                    final tanggal = DateTime.parse(izin['tanggal_efektif']);

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header section with status
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      izin['status'],
                                    ).withAlpha(100),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(izin['status']),
                                    color: _getStatusColor(izin['status']),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${izin['jenis_izin']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                StatusIzinChip(status: izin['status']),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Date information
                            Text(
                              DateFormat(
                                'EEEE, dd MMM yyyy',
                                'id_ID',
                              ).format(tanggal),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Divider(height: 1, color: Colors.grey[300]),
                            const SizedBox(height: 16),

                            // Schedule details
                            if (jadwal != null) ...[
                              _buildDetailRow(
                                Icons.schedule_outlined,
                                'Jam Pelajaran',
                                '${jadwal['waktu_mulai']} - ${jadwal['waktu_selesai']}',
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.class_outlined,
                                'Kelas & Mapel',
                                '${jadwal['mata_pelajaran']?['nama'] ?? 'Mata Pelajaran'} - Kelas ${jadwal['kelas']?['nama'] ?? ''}',
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Reason section
                            _buildSectionTitle('Alasan Izin'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${izin['alasan']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),

                            // Admin notes (if exists)
                            if (izin['catatan_admin'] != null) ...[
                              const SizedBox(height: 16),
                              _buildSectionTitle('Catatan Admin'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFEF0C7),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.amber[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${izin['catatan_admin']}',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Icons.check_circle_outline;
      case 'ditolak':
        return Icons.cancel_outlined;
      case 'menunggu':
        return Icons.access_time_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return const Color(0xFF00A86B); // Green
      case 'ditolak':
        return const Color(0xFFF04438); // Red
      case 'menunggu':
        return const Color(0xFFF79009); // Orange
      default:
        return const Color(0xFF667085); // Gray
    }
  }
}
