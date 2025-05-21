import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final pengumumanServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return PengumumanService(supabase);
});

class PengumumanService {
  final SupabaseClient _supabase;

  PengumumanService(this._supabase);

  Future<List<Map<String, dynamic>>> getPengumuman() async {
    final response = await _supabase
        .from('pengumuman')
        .select('*, admin_id(nama)')
        .order('dibuat_pada', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createPengumuman({
    required String judul,
    required String isi,
    String? fotoUrl,
    required String adminId,
  }) async {
    final response =
        await _supabase
            .from('pengumuman')
            .insert({
              'judul': judul,
              'isi': isi,
              'foto_url': fotoUrl,
              'admin_id': adminId,
              'aktif': true,
            })
            .select()
            .single();
    return response;
  }

  Future<Map<String, dynamic>> updatePengumuman({
    required String id,
    required String judul,
    required String isi,
    String? fotoUrl,
    bool? aktif,
  }) async {
    final response =
        await _supabase
            .from('pengumuman')
            .update({
              'judul': judul,
              'isi': isi,
              'foto_url': fotoUrl,
              'aktif': aktif,
              'diperbarui_pada': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();
    return response;
  }

  Future<void> deletePengumuman(String id) async {
    await _supabase.from('pengumuman').delete().eq('id', id);
  }
}
