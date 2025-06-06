import 'dart:io';
import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter/material.dart';
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

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          'pengumuman_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from('images-pengumuman')
          .upload(
            fileName,
            imageFile,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      return _supabase.storage.from('images-pengumuman').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> deleteOldImage(String? imageUrl) async {
    if (imageUrl == null) return;

    try {
      final oldFileName = imageUrl.split('/').last;
      await _supabase.storage.from('images-pengumuman').remove([oldFileName]);
    } catch (e) {
      debugPrint('Error deleting old image: $e');
    }
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
