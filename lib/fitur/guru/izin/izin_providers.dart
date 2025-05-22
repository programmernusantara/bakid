// izin_providers.dart
import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';

final jadwalHariIniProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user['profil'] == null) return [];

  final supabase = ref.watch(supabaseProvider);
  final today = DateTime.now();
  final weekday = today.weekday;

  // Dapatkan jadwal hari ini
  final jadwal = await supabase
      .from('jadwal_mengajar')
      .select('''
        *, 
        kelas:kelas_id(*), 
        mata_pelajaran:mata_pelajaran_id(*)
      ''')
      .eq('guru_id', user['profil']['id'])
      .eq('hari_dalam_minggu', weekday);

  // Cek izin yang sudah ada untuk hari ini
  final existingIzin = await supabase
      .from('permohonan_izin')
      .select('jadwal_id')
      .eq('guru_id', user['profil']['id'])
      .eq('tanggal_efektif', today.toIso8601String())
      .inFilter('status', ['menunggu', 'disetujui']);

  // Filter jadwal yang belum memiliki izin aktif
  final filteredJadwal =
      jadwal.where((j) {
        return !existingIzin.any((izin) => izin['jadwal_id'] == j['id']);
      }).toList();

  return filteredJadwal;
});
