import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:intl/intl.dart';

// Provider untuk tanggal jurnal (konsisten dengan absensi)
final jurnalDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider untuk jadwal yang dipilih di jurnal (konsisten dengan absensi)
final jurnalSelectedJadwalProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

// Provider untuk data jadwal jurnal (disesuaikan dengan pola absensi)
final jurnalJadwalProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user['profil'] == null) return [];

  final selectedDate = ref.watch(jurnalDateProvider);
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

// Provider untuk daftar jurnal (dioptimalkan)
final jurnalListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null || user['profil'] == null) return [];

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
          .eq('guru_id', user['profil']['id'])
          .order('tanggal', ascending: false);

      return response;
    });

// Provider untuk cek jurnal yang sudah ada (disederhanakan)
final existingJurnalProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, jadwalId) async {
      final user = ref.watch(currentUserProvider);
      if (user == null || user['profil'] == null) return null;

      final tanggal = ref.watch(jurnalDateProvider);
      final supabase = ref.watch(supabaseProvider);

      final response =
          await supabase
              .from('jurnal_mengajar')
              .select('''
        *,
        jadwal_mengajar:jadwal_id (*)
      ''')
              .eq('guru_id', user['profil']['id'])
              .eq('jadwal_id', jadwalId)
              .eq('tanggal', DateFormat('yyyy-MM-dd').format(tanggal))
              .maybeSingle();

      return response;
    });
