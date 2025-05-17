// repositories/kelas_repository.dart
import 'package:bakid/features/admin/dashboard/kelas/kelas_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KelasRepository {
  final SupabaseClient _supabase;

  KelasRepository(this._supabase);

  Future<List<Kelas>> getDaftarKelas() async {
    final response = await _supabase
        .from('view_kelas_detail')
        .select()
        .order('nama', ascending: true);

    return response.map<Kelas>((map) => Kelas.fromMap(map)).toList();
  }

  Future<List<JurnalMengajar>> getJurnalByKelas(String kelasId) async {
    final response = await _supabase
        .from('view_jurnal_kelas')
        .select()
        .eq('kelas_id', kelasId)
        .order('tanggal', ascending: false);

    return response
        .map<JurnalMengajar>((map) => JurnalMengajar.fromMap(map))
        .toList();
  }

  Future<List<RekapAbsensi>> getAbsensiByKelas(String kelasId) async {
    final response = await _supabase
        .from('view_absensi_kelas')
        .select()
        .eq('kelas_id', kelasId)
        .order('tanggal', ascending: false);

    return response
        .map<RekapAbsensi>((map) => RekapAbsensi.fromMap(map))
        .toList();
  }

  Future<Kelas?> getKelasById(String id) async {
    final response =
        await _supabase.from('kelas').select().eq('id', id).maybeSingle();

    return response != null ? Kelas.fromMap(response) : null;
  }
}
