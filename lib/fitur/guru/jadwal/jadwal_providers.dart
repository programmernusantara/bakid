import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jadwalHariIniProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  try {
    // Ambil profil guru berdasarkan user.id
    final profilResponse =
        await supabase
            .from('profil_guru')
            .select()
            .eq('user_id', user['id'])
            .maybeSingle();

    if (profilResponse == null) {
      debugPrint('Profil guru tidak ditemukan');
      return [];
    }

    final guruId = profilResponse['id'];

    final response = await supabase
        .from('jadwal_mengajar')
        .select('''
          *,
          mata_pelajaran: mata_pelajaran_id(nama),
          kelas: kelas_id(nama)
        ''')
        .eq('guru_id', guruId)
        .eq('hari_dalam_minggu', DateTime.now().weekday)
        .order('waktu_mulai')
        .limit(10);

    return (response as List).cast<Map<String, dynamic>>();
  } catch (e) {
    debugPrint('Error fetching jadwal: $e');
    return [];
  }
});
