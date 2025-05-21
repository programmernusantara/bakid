import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/absen/absen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AbsenTabPage extends ConsumerStatefulWidget {
  const AbsenTabPage({super.key});

  @override
  ConsumerState<AbsenTabPage> createState() => _AbsenTabPageState();
}

class _AbsenTabPageState extends ConsumerState<AbsenTabPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Absensi"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fingerprint),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AbsenContent()),
              );
            },
          ),
        ],
      ),
      body: const RiwayatAbsenContent(),
    );
  }
}

class AbsenContent extends ConsumerStatefulWidget {
  const AbsenContent({super.key});

  @override
  ConsumerState<AbsenContent> createState() => _AbsenContentState();
}

class _AbsenContentState extends ConsumerState<AbsenContent> {
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  List<Map<String, dynamic>> _jadwalHariIni = [];
  Map<String, dynamic>? _selectedJadwal;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadJadwalHariIni();
    _getCurrentLocation();
  }

  Future<void> _loadJadwalHariIni() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
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
        if (mounted) {
          setState(() => _errorMessage = 'Profil guru tidak ditemukan');
        }
        return;
      }

      final guruId = profilResponse['id'];
      final absenService = ref.read(absenServiceProvider);
      final jadwal = await absenService.getJadwalHariIni(guruId);

      if (mounted) {
        setState(() {
          _jadwalHariIni = jadwal;
          if (_jadwalHariIni.isNotEmpty) {
            _selectedJadwal = _jadwalHariIni.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal memuat jadwal: $e');
      }
      debugPrint('Error _loadJadwalHariIni: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _errorMessage = 'Lokasi GPS tidak aktif');
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _errorMessage = 'Izin lokasi ditolak');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _errorMessage = 'Izin lokasi ditolak permanen');
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal mendapatkan lokasi: $e');
      }
    }
  }

  Future<void> _handleAbsen() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _selectedJadwal == null || _currentPosition == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
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
        if (mounted) {
          setState(() => _errorMessage = 'Profil guru tidak ditemukan');
        }
        return;
      }

      final guruId = profilResponse['id'];
      final absenService = ref.read(absenServiceProvider);

      final hasIzin = await absenService.cekIzinDisetujui(
        guruId,
        _selectedJadwal!['id'],
        DateTime.now(),
      );

      if (hasIzin) {
        if (mounted) {
          setState(() {
            _successMessage =
                'Anda memiliki izin yang disetujui untuk jadwal ini';
          });
        }
        return;
      }

      final result = await absenService.absen(
        guruId: guruId,
        jadwalId: _selectedJadwal!['id'],
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        waktuAbsen: DateTime.now(),
      );

      if (mounted) {
        // Show success notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Absensi berhasil: ${_formatStatus(result['status'])}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        setState(() {
          _successMessage =
              'Absensi berhasil: ${_formatStatus(result['status'])}';
        });
        _loadJadwalHariIni();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(String time) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse('1970-01-01 $time'));
    } catch (e) {
      return time;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Absen Sekarang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              _buildStatusCard(_errorMessage, Colors.red[50]!, Colors.red),

            if (_successMessage.isNotEmpty)
              _buildStatusCard(
                _successMessage,
                Colors.green[50]!,
                Colors.green,
              ),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),

            if (!_isLoading && _jadwalHariIni.isEmpty) _buildEmptyScheduleUI(),

            if (_jadwalHariIni.isNotEmpty) ...[
              _buildScheduleSelection(theme),
              const SizedBox(height: 24),

              if (_selectedJadwal != null) _buildScheduleDetailsCard(theme),

              const SizedBox(height: 24),
              _buildAbsenButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String message, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha(100)),
      ),
      child: Text(
        message,
        style: TextStyle(color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyScheduleUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada jadwal mengajar hari ini',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadJadwalHariIni,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Jadwal',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedJadwal,
              isExpanded: true,
              items:
                  _jadwalHariIni.map((jadwal) {
                    final mapel = jadwal['mata_pelajaran']?['nama'] ?? '-';
                    final kelas = jadwal['kelas']?['nama'] ?? '-';
                    final mulai = _formatTime(jadwal['waktu_mulai'] ?? '');
                    final selesai = _formatTime(jadwal['waktu_selesai'] ?? '');
                    return DropdownMenuItem(
                      value: jadwal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$mapel - $kelas ($mulai - $selesai)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => _selectedJadwal = value),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleDetailsCard(ThemeData theme) {
    final lokasiAbsen = _selectedJadwal!['lokasi_absen'] ?? {};
    final radius =
        lokasiAbsen['radius'] != null ? '${lokasiAbsen['radius']} meter' : '-';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Detail Jadwal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Mata Pelajaran',
              _selectedJadwal!['mata_pelajaran']?['nama'],
            ),
            _buildDetailRow('Kelas', _selectedJadwal!['kelas']?['nama']),
            _buildDetailRow(
              'Waktu',
              '${_formatTime(_selectedJadwal!['waktu_mulai'])} - ${_formatTime(_selectedJadwal!['waktu_selesai'])}',
            ),
            _buildDetailRow('Lokasi Absen', lokasiAbsen['nama']),
            _buildDetailRow('Radius', radius),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleAbsen,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        child: const Text('ABSEN SEKARANG'),
      ),
    );
  }
}

class RiwayatAbsenContent extends ConsumerStatefulWidget {
  const RiwayatAbsenContent({super.key});

  @override
  ConsumerState<RiwayatAbsenContent> createState() =>
      _RiwayatAbsenContentState();
}

class _RiwayatAbsenContentState extends ConsumerState<RiwayatAbsenContent> {
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
        if (mounted) {
          setState(() => _errorMessage = 'Profil guru tidak ditemukan');
        }
        return;
      }

      final guruId = profilResponse['id'];
      final absenService = ref.read(absenServiceProvider);
      final riwayat = await absenService.getRiwayatAbsen(guruId);
      if (mounted) {
        setState(() => _riwayatAbsen = riwayat);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal memuat riwayat absen: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_riwayatAbsen.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat absensi',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadRiwayatAbsen,
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRiwayatAbsen,
      color: Colors.blue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _riwayatAbsen.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final absen = _riwayatAbsen[index];
          final jadwal = absen['jadwal'] ?? {};
          final mataPelajaran = jadwal['mata_pelajaran']?['nama'] ?? '-';
          final kelas = jadwal['kelas']?['nama'] ?? '-';
          final tanggal = DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.parse(absen['tanggal']));
          final waktu = absen['waktu_absen'] ?? '';
          final status = _formatStatus(absen['status']);

          return Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap:
                  () => _showAbsenDetails(
                    context,
                    absen,
                    mataPelajaran,
                    kelas,
                    tanggal,
                    waktu,
                    status,
                  ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mataPelajaran,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$kelas • $tanggal',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(absen['status']).withAlpha(100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(
                            absen['status'],
                          ).withAlpha(100),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(absen['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAbsenDetails(
    BuildContext context,
    Map<String, dynamic> absen,
    String mataPelajaran,
    String kelas,
    String tanggal,
    String waktu,
    String status,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detail Absensi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Mata Pelajaran', mataPelajaran),
                  _buildDetailItem('Kelas', kelas),
                  _buildDetailItem('Tanggal', tanggal),
                  _buildDetailItem('Waktu Absen', waktu),
                  _buildDetailItem(
                    'Status',
                    status,
                    valueColor: _getStatusColor(absen['status']),
                  ),
                  if (absen['latitude'] != null && absen['longitude'] != null)
                    _buildDetailItem(
                      'Lokasi',
                      '${absen['latitude']}, ${absen['longitude']}',
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
