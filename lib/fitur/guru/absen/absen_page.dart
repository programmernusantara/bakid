import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/absen/absen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        title: const Text("Guru"),
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
  final DateTime _currentDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadJadwalHariIni();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController.dispose();
    super.dispose();
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
          if (jadwal.isNotEmpty) {
            _selectedJadwal = jadwal.first;
            if (_isMapReady) {
              _updateMapView();
            }
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
        setState(() {
          _currentPosition = position;
          if (_isMapReady) {
            _updateMapView();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal mendapatkan lokasi: $e');
      }
    }
  }

  void _updateMapView() {
    if (!_isMapReady || _selectedJadwal == null || _currentPosition == null) {
      return;
    }

    final lokasiAbsen = _selectedJadwal!['lokasi_absen'];
    if (lokasiAbsen == null) return;

    final latLngAbsen = LatLng(
      lokasiAbsen['latitude'] as double,
      lokasiAbsen['longitude'] as double,
    );
    final latLngSaya = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    // Calculate center point between the two locations
    final center = LatLng(
      (latLngAbsen.latitude + latLngSaya.latitude) / 2,
      (latLngAbsen.longitude + latLngSaya.longitude) / 2,
    );

    // Calculate zoom level based on distance between points
    final distance = const Distance().distance(latLngAbsen, latLngSaya);
    final zoom = (15 - (distance / 1000).clamp(0, 10)).toDouble();

    _mapController.move(center, zoom);
  }

  Future<void> _handleAbsen() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _selectedJadwal == null || _currentPosition == null) {
      setState(() {
        _errorMessage = 'Silakan lengkapi data terlebih dahulu';
        _successMessage = '';
      });
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

      // Cek izin disetujui
      final hasIzin = await absenService.cekIzinDisetujui(
        guruId,
        _selectedJadwal!['id'],
        DateTime.now(),
      );

      if (hasIzin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Anda memiliki izin yang disetujui'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      // Proses absensi
      final result = await absenService.absen(
        guruId: guruId,
        jadwalId: _selectedJadwal!['id'],
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        waktuAbsen: DateTime.now(),
      );

      // Tampilkan pesan sukses berdasarkan status
      final status = result['status'];
      String statusMessage = '';
      Color snackBarColor = Colors.green;

      switch (status) {
        case 'hadir':
          statusMessage = '✅ Absensi berhasil - Status: Hadir';
          snackBarColor = Colors.green;
          break;
        case 'terlambat':
          statusMessage = '⚠️ Absensi berhasil - Status: Terlambat';
          snackBarColor = Colors.orange;
          break;
        case 'alpa':
          statusMessage = '❌ Absensi gagal - Status: Alpa';
          snackBarColor = Colors.red;
          break;
        case 'izin':
          statusMessage = 'ℹ️ Absensi dicatat - Status: Izin';
          snackBarColor = Colors.blue;
          break;
        default:
          statusMessage = 'Absensi berhasil';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMessage),
            backgroundColor: snackBarColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      // Refresh data setelah absen berhasil
      await _loadJadwalHariIni();
    } catch (e) {
      // Tangani error khusus untuk tampilan pesan
      String errorMessage = '❌ Gagal melakukan absen';
      Color snackBarColor = Colors.red;

      if (e.toString().contains('Belum waktunya absen')) {
        errorMessage = '⏱️ $e';
        snackBarColor = Colors.orange;
      } else if (e.toString().contains('sudah melakukan absensi')) {
        errorMessage = 'ℹ️ $e';
        snackBarColor = Colors.blue;
      } else if (e.toString().contains('Absensi ditutup')) {
        errorMessage = '⏱️ $e';
        snackBarColor = Colors.orange;
      } else if (e.toString().contains('di luar jangkauan')) {
        errorMessage = '📍 $e';
        snackBarColor = Colors.red;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: snackBarColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
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

  Widget _buildMap() {
    if (_selectedJadwal == null || _currentPosition == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Memuat peta...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final lokasiAbsen = _selectedJadwal!['lokasi_absen'] ?? {};
    final latLngAbsen =
        lokasiAbsen['latitude'] != null && lokasiAbsen['longitude'] != null
            ? LatLng(lokasiAbsen['latitude'], lokasiAbsen['longitude'])
            : null;
    final latLngSaya = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    return SizedBox(
      height: 200,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: latLngAbsen ?? latLngSaya,
          initialZoom: 15,
          onMapReady: () {
            setState(() {
              _isMapReady = true;
            });
            _updateMapView();
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          if (latLngAbsen != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: latLngAbsen,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.school, color: Colors.red, size: 30),
                ),
                Marker(
                  point: latLngSaya,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
          if (latLngAbsen != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: latLngAbsen,
                  color: Colors.blue.withAlpha(100),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                  radius: (lokasiAbsen['radius_meter'] ?? 100).toDouble(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Absen Sekarang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _getCurrentLocation();
              _updateMapView();
            },
          ),
        ],
      ),
      body: SafeArea(child: _buildMainContent(theme)),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jadwalHariIni.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal mengajar hari ini',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Status messages at the top
        if (_errorMessage.isNotEmpty || _successMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child:
                _errorMessage.isNotEmpty
                    ? _buildStatusMessage(
                      _errorMessage,
                      Icons.error_outline_rounded,
                      Colors.red,
                    )
                    : _buildStatusMessage(
                      _successMessage,
                      Icons.check_circle_outline_rounded,
                      Colors.green,
                    ),
          ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Date Header Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hari Ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                  'id_ID',
                                ).format(_currentDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Map Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOKASI ABSEN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildMap(),
                              const SizedBox(height: 12),
                              if (_selectedJadwal?['lokasi_absen'] != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedJadwal!['lokasi_absen']['nama'] ??
                                            'Lokasi absen',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_currentPosition != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_pin_circle,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Lokasi Anda saat ini',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Jadwal List
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PILIH JADWAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._jadwalHariIni.map((j) {
                        final isSelected = _selectedJadwal?['id'] == j['id'];
                        final kelas = j['kelas'] as Map<String, dynamic>?;
                        final mapel =
                            j['mata_pelajaran'] as Map<String, dynamic>?;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedJadwal = j;
                                _updateMapView();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Theme.of(
                                                context,
                                              ).primaryColor.withAlpha(100)
                                              : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.schedule_outlined,
                                      color:
                                          isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${mapel?['nama'] ?? 'Mata Pelajaran'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color:
                                                isSelected
                                                    ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                    : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kelas ${kelas?['nama'] ?? ''} • ${_formatTime(j['waktu_mulai'])} - ${_formatTime(j['waktu_selesai'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Schedule Details
                if (_selectedJadwal != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSectionTitle('Detail Jadwal', theme),
                        const SizedBox(height: 12),
                        _buildDetailCard(),
                      ],
                    ),
                  ),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildAbsenButton(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(String message, IconData icon, Color color) {
    final bgColor = color.withAlpha(20);
    final borderColor = color.withAlpha(38);
    final textColor = Colors.grey[800];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor?.withAlpha(204)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    final lokasiAbsen = _selectedJadwal!['lokasi_absen'] ?? {};
    final radius =
        lokasiAbsen['radius_meter'] != null
            ? '${lokasiAbsen['radius_meter']} meter'
            : '100 meter (default)';
    final koordinat =
        lokasiAbsen['latitude'] != null && lokasiAbsen['longitude'] != null
            ? '(${lokasiAbsen['latitude']}, ${lokasiAbsen['longitude']})'
            : '-';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.purple[600],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Detail Jadwal',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Mata Pelajaran',
              _selectedJadwal!['mata_pelajaran']?['nama'] ?? '-',
            ),
            _buildDetailRow('Kelas', _selectedJadwal!['kelas']?['nama'] ?? '-'),
            _buildDetailRow(
              'Waktu',
              '${_formatTime(_selectedJadwal!['waktu_mulai'])} - ${_formatTime(_selectedJadwal!['waktu_selesai'])}',
            ),
            _buildDetailRow('Lokasi Absen', lokasiAbsen['nama'] ?? '-'),
            _buildDetailRow('Koordinat', koordinat),
            _buildDetailRow('Radius Diperbolehkan', radius),
            if (_currentPosition != null) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Lokasi Anda Saat Ini',
                '(${_currentPosition!.latitude.toStringAsFixed(6)}, '
                    '${_currentPosition!.longitude.toStringAsFixed(6)})',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'ABSEN SEKARANG',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
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
      return RefreshIndicator(
        onRefresh: _loadRiwayatAbsen,
        color: Colors.blue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
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
            ),
          ),
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
