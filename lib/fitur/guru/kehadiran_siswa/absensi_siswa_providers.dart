import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';

// Provider untuk tanggal absensi
final absensiSiswaDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// Provider untuk jadwal yang dipilih
final absensiSiswaSelectedJadwalProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

// Provider untuk data jadwal
final absensiSiswaJadwalProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user['profil'] == null) return [];

  final selectedDate = ref.watch(absensiSiswaDateProvider);
  final supabase = ref.watch(supabaseProvider);
  final hariIni = selectedDate.weekday;

  final data = await supabase
      .from('jadwal_mengajar')
      .select('*, kelas:kelas_id(*), mata_pelajaran:mata_pelajaran_id(*)')
      .eq('guru_id', user['profil']['id'])
      .eq('hari_dalam_minggu', hariIni)
      .eq('aktif', true)
      .order('waktu_mulai');

  return List<Map<String, dynamic>>.from(data);
});
