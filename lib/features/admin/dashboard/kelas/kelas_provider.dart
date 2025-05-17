// providers/kelas_provider.dart
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/admin/dashboard/kelas/kelas_model.dart';
import 'package:bakid/features/admin/dashboard/kelas/kelas_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final kelasRepositoryProvider = Provider<KelasRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return KelasRepository(supabase);
});

final daftarKelasProvider = FutureProvider<List<Kelas>>((ref) async {
  final repository = ref.watch(kelasRepositoryProvider);
  return repository.getDaftarKelas();
});

final selectedKelasProvider = StateProvider<Kelas?>((ref) => null);

final jurnalKelasProvider = FutureProvider.family<List<JurnalMengajar>, String>(
  (ref, kelasId) async {
    final repository = ref.watch(kelasRepositoryProvider);
    return repository.getJurnalByKelas(kelasId);
  },
);

final absensiKelasProvider = FutureProvider.family<List<RekapAbsensi>, String>((
  ref,
  kelasId,
) async {
  final repository = ref.watch(kelasRepositoryProvider);
  return repository.getAbsensiByKelas(kelasId);
});
