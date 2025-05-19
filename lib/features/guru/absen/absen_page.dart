// lib/features/guru/absen/absen_page.dart
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/guru/absen/absen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AbsenPage extends ConsumerStatefulWidget {
  const AbsenPage({super.key});

  @override
  ConsumerState<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends ConsumerState<AbsenPage> {
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

    setState(() => _isLoading = true);
    try {
      final absenService = ref.read(absenServiceProvider);
      final jadwal = await absenService.getJadwalHariIni(user['id']);
      setState(() => _jadwalHariIni = jadwal);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat jadwal: $e');
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
      final absenService = ref.read(absenServiceProvider);

      // Cek izin terlebih dahulu
      final hasIzin = await absenService.cekIzinDisetujui(
        user['id'],
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
        guruId: user['id'],
        jadwalId: _selectedJadwal!['id'],
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        waktuAbsen: DateTime.now(),
      );

      setState(() {
        _successMessage = 'Absensi berhasil: ${result['status']}';
        _loadJadwalHariIni(); // Refresh data
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String time) {
    return DateFormat('HH:mm').format(DateTime.parse('1970-01-01 $time'));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Absensi Guru',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (_successMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _successMessage,
                style: const TextStyle(color: Colors.green),
              ),
            ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          if (!_isLoading && _jadwalHariIni.isEmpty)
            const Center(child: Text('Tidak ada jadwal mengajar hari ini')),

          if (_jadwalHariIni.isNotEmpty) ...[
            const Text(
              'Pilih Jadwal:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedJadwal,
              items:
                  _jadwalHariIni.map((jadwal) {
                    final mataPelajaran =
                        jadwal['mata_pelajaran']?['nama'] ?? 'Unknown';
                    final kelas = jadwal['kelas']?['nama'] ?? 'Unknown';
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: jadwal,
                      child: Text(
                        '$mataPelajaran - $kelas (${_formatTime(jadwal['waktu_mulai'])}- ${_formatTime(jadwal['waktu_selesai'])})',
                      ),
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
            const SizedBox(height: 16),

            if (_selectedJadwal != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Jadwal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mata Pelajaran: ${_selectedJadwal!['mata_pelajaran']?['nama'] ?? 'Unknown'}',
                      ),
                      Text(
                        'Kelas: ${_selectedJadwal!['kelas']?['nama'] ?? 'Unknown'}',
                      ),
                      Text(
                        'Waktu: ${_formatTime(_selectedJadwal!['waktu_mulai'])} - ${_formatTime(_selectedJadwal!['waktu_selesai'])}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lokasi Absen:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${_selectedJadwal!['lokasi_absen']?['nama'] ?? 'Unknown'}',
                      ),
                      Text(
                        'Radius: ${_selectedJadwal!['lokasi_absen']?['radius_meter'] ?? 0} meter',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lokasi Anda Sekarang:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_currentPosition != null)
                        Text(
                          '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        ),
                      if (_currentPosition == null)
                        const Text('Mendeteksi lokasi...'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleAbsen,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('ABSEN SEKARANG'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
