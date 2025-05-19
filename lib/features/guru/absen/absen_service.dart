// lib/core/services/absen_service.dart
import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

final absenServiceProvider = Provider<AbsenService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AbsenService(supabase);
});

class AbsenService {
  final SupabaseClient _supabase;

  AbsenService(this._supabase);

  // Fungsi untuk menghitung jarak antara dua titik koordinat
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Fungsi untuk mendapatkan jadwal mengajar hari ini untuk guru tertentu
  Future<List<Map<String, dynamic>>> getJadwalHariIni(String guruId) async {
    final now = DateTime.now();
    final hariIni = now.weekday; // 1-7 (Senin-Minggu)

    final response = await _supabase
        .from('jadwal_mengajar')
        .select('''
          *, 
          lokasi_absen:lokasi_absen_id(*),
          mata_pelajaran:mata_pelajaran_id(*),
          kelas:kelas_id(*)
        ''')
        .eq('guru_id', guruId)
        .eq('hari_dalam_minggu', hariIni)
        .eq('aktif', true)
        .order('waktu_mulai');

    return response;
  }

  // Fungsi untuk memeriksa apakah guru sudah memiliki izin yang disetujui
  Future<bool> cekIzinDisetujui(
    String guruId,
    String jadwalId,
    DateTime tanggal,
  ) async {
    final response = await _supabase
        .from('permohonan_izin')
        .select()
        .eq('guru_id', guruId)
        .eq('status', 'disetujui')
        .lte('tanggal_mulai', tanggal)
        .gte('tanggal_selesai', tanggal);

    return response.isNotEmpty;
  }

  // Fungsi untuk melakukan absensi
  Future<Map<String, dynamic>> absen({
    required String guruId,
    required String jadwalId,
    required double latitude,
    required double longitude,
    required DateTime waktuAbsen,
  }) async {
    // 1. Ambil data jadwal
    final jadwal =
        await _supabase
            .from('jadwal_mengajar')
            .select('*, lokasi_absen:lokasi_absen_id(*)')
            .eq('id', jadwalId)
            .single();

    final lokasiAbsen = jadwal['lokasi_absen'];
    if (lokasiAbsen == null) {
      throw 'Lokasi absen belum ditentukan untuk jadwal ini';
    }

    // 2. Validasi lokasi
    final jarak = _calculateDistance(
      latitude,
      longitude,
      lokasiAbsen['latitude'],
      lokasiAbsen['longitude'],
    );

    if (jarak > lokasiAbsen['radius_meter']) {
      throw 'Anda berada di luar jangkauan lokasi absen. Jarak: ${jarak.toStringAsFixed(0)} meter dari lokasi yang ditentukan';
    }

    // 3. Validasi waktu
    final waktuMulai = DateTime.parse('1970-01-01 ${jadwal['waktu_mulai']}');
    final waktuSelesai = DateTime.parse(
      '1970-01-01 ${jadwal['waktu_selesai']}',
    );
    final waktuAbsenTime = DateTime.parse(
      '1970-01-01 ${waktuAbsen.toIso8601String().split('T')[1]}',
    );

    String status;
    final waktuMulaiMinus10 = waktuMulai.subtract(const Duration(minutes: 10));

    if (waktuAbsenTime.isBefore(waktuMulaiMinus10)) {
      throw 'Belum waktunya absen. Absensi dibuka 10 menit sebelum kelas dimulai';
    } else if (waktuAbsenTime.isAfter(waktuMulaiMinus10) &&
        waktuAbsenTime.isBefore(waktuMulai)) {
      status = 'hadir';
    } else if (waktuAbsenTime.isAfter(waktuMulai) &&
        waktuAbsenTime.isBefore(waktuSelesai)) {
      status = 'terlambat';
    } else {
      throw 'Absensi ditutup. Waktu absensi sudah melebihi waktu selesai kelas';
    }

    // 4. Cek apakah sudah ada absensi untuk jadwal ini hari ini
    final tanggal = DateTime.now();
    final existingAbsen =
        await _supabase
            .from('kehadiran_guru')
            .select()
            .eq('guru_id', guruId)
            .eq('jadwal_id', jadwalId)
            .eq('tanggal', tanggal.toIso8601String().split('T')[0])
            .maybeSingle();

    if (existingAbsen != null) {
      throw 'Anda sudah melakukan absensi untuk jadwal ini hari ini';
    }

    // 5. Simpan data absensi
    final data = {
      'guru_id': guruId,
      'jadwal_id': jadwalId,
      'tanggal': tanggal.toIso8601String().split('T')[0],
      'status': status,
      'waktu_absen': waktuAbsen.toIso8601String().split('T')[1],
      'latitude': latitude,
      'longitude': longitude,
    };

    final response =
        await _supabase.from('kehadiran_guru').insert(data).select().single();

    return response;
  }

  // Fungsi untuk mendapatkan riwayat absensi
  Future<List<Map<String, dynamic>>> getRiwayatAbsen(
    String guruId, {
    int limit = 30,
  }) async {
    final response = await _supabase
        .from('kehadiran_guru')
        .select('''
          *, 
          jadwal:jadwal_id(*, mata_pelajaran:mata_pelajaran_id(*), kelas:kelas_id(*))
        ''')
        .eq('guru_id', guruId)
        .order('tanggal', ascending: false)
        .order('waktu_absen', ascending: false)
        .limit(limit);

    return response;
  }
}
