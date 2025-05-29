import 'package:supabase_flutter/supabase_flutter.dart';

class KelasService {
  final SupabaseClient _supabase;

  KelasService(this._supabase);

  Future<List<Map<String, dynamic>>> getKelasList() async {
    final response = await _supabase
        .from('kelas')
        .select('*')
        .order('nama', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Update the getKelasDetail method in KelasService
  Future<Map<String, dynamic>> getKelasDetail(String id) async {
    final response =
        await _supabase.from('kelas').select().eq('id', id).single();
    return response;
  }

  Future<void> addKelas(Map<String, dynamic> data) async {
    await _supabase.from('kelas').insert(data);
  }

  Future<void> updateKelas(String id, Map<String, dynamic> data) async {
    await _supabase.from('kelas').update(data).eq('id', id);
  }

  Future<void> deleteKelas(String id) async {
    await _supabase.from('kelas').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getMataPelajaranByKelas(
    String kelasId,
  ) async {
    final response = await _supabase
        .from('mata_pelajaran')
        .select('*')
        .eq('kelas_id', kelasId)
        .order('nama', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Update the getJadwalByKelas method in KelasService
  Future<List<Map<String, dynamic>>> getJadwalByKelas(String kelasId) async {
    final response = await _supabase
        .from('jadwal_mengajar')
        .select('''
        *,
        mata_pelajaran:mata_pelajaran(*),
        guru:profil_guru(*),
        lokasi_absen:lokasi_absen(*)
      ''')
        .eq('kelas_id', kelasId)
        .order('hari_dalam_minggu')
        .order('waktu_mulai');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getJurnalByKelas(String kelasId) async {
    // Pertama dapatkan semua jadwal untuk kelas ini
    final jadwalResponse = await _supabase
        .from('jadwal_mengajar')
        .select('id')
        .eq('kelas_id', kelasId);

    if (jadwalResponse.isEmpty) return [];

    // Ekstrak semua id jadwal
    final jadwalIds = jadwalResponse.map((j) => j['id'] as String).toList();

    // Kemudian dapatkan jurnal untuk jadwal-jadwal tersebut
    final response = await _supabase
        .from('jurnal_mengajar')
        .select('''
        *,
        guru:profil_guru(*),
        jadwal:jadwal_mengajar(*, mata_pelajaran:mata_pelajaran(*))
      ''')
        .inFilter('jadwal_id', jadwalIds)
        .order('tanggal', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getRekapAbsensiByKelas(
    String kelasId,
  ) async {
    final response = await _supabase
        .from('rekap_absensi_siswa')
        .select('''
          *,
          guru:profil_guru(*),
          jadwal:jadwal_mengajar(mata_pelajaran:mata_pelajaran(*))
        ''')
        .eq('kelas_id', kelasId)
        .order('tanggal', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getLokasiAbsenList() async {
    final response = await _supabase
        .from('lokasi_absen')
        .select('id, nama')
        .order('nama', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }
}

class MataPelajaranService {
  final SupabaseClient _supabase;

  MataPelajaranService(this._supabase);

  Future<void> addMataPelajaran(Map<String, dynamic> data) async {
    await _supabase.from('mata_pelajaran').insert(data);
  }

  Future<void> updateMataPelajaran(String id, Map<String, dynamic> data) async {
    await _supabase.from('mata_pelajaran').update(data).eq('id', id);
  }

  Future<void> deleteMataPelajaran(String id) async {
    await _supabase.from('mata_pelajaran').delete().eq('id', id);
  }
}

class JadwalMengajarService {
  final SupabaseClient _supabase;

  JadwalMengajarService(this._supabase);

  Future<void> addJadwal(Map<String, dynamic> data) async {
    await _supabase.from('jadwal_mengajar').insert(data);
  }

  Future<void> updateJadwal(String id, Map<String, dynamic> data) async {
    await _supabase.from('jadwal_mengajar').update(data).eq('id', id);
  }

  Future<void> deleteJadwal(String id) async {
    await _supabase.from('jadwal_mengajar').delete().eq('id', id);
  }
}
