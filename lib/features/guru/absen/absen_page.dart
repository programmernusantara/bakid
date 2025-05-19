import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/guru/absen/absen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AbsenTabPage extends ConsumerStatefulWidget {
  const AbsenTabPage({super.key});

  @override
  ConsumerState<AbsenTabPage> createState() => _AbsenTabPageState();
}

class _AbsenTabPageState extends ConsumerState<AbsenTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Absen', icon: Icon(Icons.fingerprint)),
            Tab(text: 'Riwayat', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AbsenContent(), RiwayatAbsenContent()],
      ),
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
        setState(() => _errorMessage = 'Profil guru tidak ditemukan');
        return;
      }

      final guruId = profilResponse['id'];
      final absenService = ref.read(absenServiceProvider);
      final jadwal = await absenService.getJadwalHariIni(guruId);

      setState(() {
        _jadwalHariIni = jadwal;
        if (_jadwalHariIni.isNotEmpty) {
          _selectedJadwal = _jadwalHariIni.first;
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat jadwal: $e');
      debugPrint('Error _loadJadwalHariIni: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorMessage = 'Lokasi GPS tidak aktif');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorMessage = 'Izin lokasi ditolak');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _errorMessage = 'Izin lokasi ditolak permanen');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mendapatkan lokasi: $e');
    }
  }

  Future<void> _handleAbsen() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _selectedJadwal == null || _currentPosition == null) {
      return;
    }

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
        setState(() => _errorMessage = 'Profil guru tidak ditemukan');
        return;
      }

      final guruId = profilResponse['id'];
      final absenService = ref.read(absenServiceProvider);

      // Cek izin terlebih dahulu
      final hasIzin = await absenService.cekIzinDisetujui(
        guruId,
        _selectedJadwal!['id'],
        DateTime.now(),
      );

      if (hasIzin) {
        setState(
          () =>
              _successMessage =
                  'Anda memiliki izin yang disetujui untuk jadwal ini',
        );
        return;
      }

      final result = await absenService.absen(
        guruId: guruId,
        jadwalId: _selectedJadwal!['id'],
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        waktuAbsen: DateTime.now(),
      );

      setState(() {
        _successMessage =
            'Absensi berhasil: ${_formatStatus(result['status'])}';
        _loadJadwalHariIni(); // Refresh data
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (_successMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _successMessage,
                style: const TextStyle(color: Colors.green),
              ),
            ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          if (!_isLoading && _jadwalHariIni.isEmpty)
            Column(
              children: [
                const Text(
                  'Tidak ada jadwal mengajar hari ini.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loadJadwalHariIni,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat Ulang'),
                ),
              ],
            ),

          if (_jadwalHariIni.isNotEmpty) ...[
            const Text(
              'Pilih Jadwal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedJadwal,
              items:
                  _jadwalHariIni.map((jadwal) {
                    final mapel = jadwal['mata_pelajaran']?['nama'] ?? '-';
                    final kelas = jadwal['kelas']?['nama'] ?? '-';
                    final mulai = _formatTime(jadwal['waktu_mulai'] ?? '');
                    final selesai = _formatTime(jadwal['waktu_selesai'] ?? '');
                    return DropdownMenuItem(
                      value: jadwal,
                      child: Text('$mapel - $kelas ($mulai - $selesai)'),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => _selectedJadwal = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedJadwal != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detail Jadwal', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _infoRow(
                        'Mata Pelajaran',
                        _selectedJadwal!['mata_pelajaran']?['nama'],
                      ),
                      _infoRow('Kelas', _selectedJadwal!['kelas']?['nama']),
                      _infoRow(
                        'Waktu',
                        '${_formatTime(_selectedJadwal!['waktu_mulai'])} - ${_formatTime(_selectedJadwal!['waktu_selesai'])}',
                      ),
                      _infoRow(
                        'Lokasi Absen',
                        _selectedJadwal!['lokasi_absen']?['nama'],
                      ),
                      _infoRow(
                        'Radius',
                        '${_selectedJadwal!['lokasi_absen']?['radius'] ?? '-'} meter',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleAbsen,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Absen Sekarang'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value?.toString() ?? '-',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
        ? Center(child: Text(_errorMessage))
        : _riwayatAbsen.isEmpty
        ? const Center(child: Text('Tidak ada riwayat absensi'))
        : RefreshIndicator(
          onRefresh: _loadRiwayatAbsen,
          child: ListView.builder(
            itemCount: _riwayatAbsen.length,
            itemBuilder: (context, index) {
              final absen = _riwayatAbsen[index];
              final jadwal = absen['jadwal'] ?? {};
              final mataPelajaran = jadwal['mata_pelajaran']?['nama'] ?? '-';
              final kelas = jadwal['kelas']?['nama'] ?? '-';
              final tanggal = DateFormat(
                'dd MMM yyyy',
              ).format(DateTime.parse(absen['tanggal']));
              final waktu = absen['waktu_absen'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
