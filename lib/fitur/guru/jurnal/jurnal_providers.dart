import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider untuk daftar jurnal
final jurnalProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, guruId) async {
      final supabase = ref.watch(supabaseProvider);
      final response = await supabase
          .from('jurnal_mengajar')
          .select('''
        *,
        jadwal_mengajar:jadwal_id (
          *,
          mata_pelajaran:mata_pelajaran_id (*),
          kelas:kelas_id (*)
        )
      ''')
          .eq('guru_id', guruId)
          .order('tanggal', ascending: false);
      return response;
    });

// Provider untuk jadwal guru
final jadwalGuruProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, guruId) async {
      final supabase = ref.watch(supabaseProvider);
      final response = await supabase
          .from('jadwal_mengajar')
          .select('''
        *,
        mata_pelajaran:mata_pelajaran_id(*),
        kelas:kelas_id(*)
      ''')
          .eq('guru_id', guruId)
          .eq('aktif', true)
          .order('hari_dalam_minggu', ascending: true)
          .order('waktu_mulai', ascending: true);
      return response;
    });

// Provider untuk cek jurnal yang sudah ada
final jurnalHariIniByJadwalProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, Map<String, dynamic>>((ref, params) async {
      final guruId = params['guruId'];
      final jadwalId = params['jadwalId'];
      final tanggal = params['tanggal'];
      final supabase = ref.watch(supabaseProvider);

      final response =
          await supabase
              .from('jurnal_mengajar')
              .select('''
        *,
        jadwal_mengajar:jadwal_id (
          *,
          mata_pelajaran:mata_pelajaran_id (*),
          kelas:kelas_id (*)
        )
      ''')
              .eq('guru_id', guruId)
              .eq('jadwal_id', jadwalId)
              .eq('tanggal', tanggal)
              .maybeSingle();
      return response;
    });
