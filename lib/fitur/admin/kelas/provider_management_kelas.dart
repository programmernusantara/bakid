import 'package:bakid/fitur/admin/kelas/kelas_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final kelasServiceProvider = Provider<KelasService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return KelasService(supabase);
});

final kelasListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final service = ref.watch(kelasServiceProvider);
      return service.getKelasList();
    });

final kelasDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) {
      final service = ref.watch(kelasServiceProvider);
      return service.getKelasDetail(id);
    });

final mataPelajaranByKelasProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, kelasId) {
      final service = ref.watch(kelasServiceProvider);
      return service.getMataPelajaranByKelas(kelasId);
    });

final jadwalByKelasProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, kelasId) {
      final service = ref.watch(kelasServiceProvider);
      return service.getJadwalByKelas(kelasId);
    });

final jurnalByKelasProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, kelasId) {
      final service = ref.watch(kelasServiceProvider);
      return service.getJurnalByKelas(kelasId);
    });

final rekapAbsensiByKelasProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, kelasId) {
      final service = ref.watch(kelasServiceProvider);
      return service.getRekapAbsensiByKelas(kelasId);
    });

final lokasiAbsenListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final service = ref.watch(kelasServiceProvider);
      return service.getLokasiAbsenList();
    });

final mataPelajaranServiceProvider = Provider<MataPelajaranService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MataPelajaranService(supabase);
});

final jadwalMengajarServiceProvider = Provider<JadwalMengajarService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JadwalMengajarService(supabase);
});

final guruListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) {
    final supabase = ref.watch(supabaseClientProvider);
    return supabase
        .from('profil_guru')
        .select('id, nama_lengkap')
        .order('nama_lengkap', ascending: true);
  },
);
