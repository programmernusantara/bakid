import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/features/auth/auth_providers.dart';

final izinDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final jadwalIzinProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  final dateRange = ref.watch(izinDateRangeProvider);

  if (user == null || user['profil'] == null || dateRange == null) {
    return [];
  }

  final supabase = ref.watch(supabaseProvider);

  final daysInRange = <int>{};
  for (
    var date = dateRange.start;
    date.isBefore(dateRange.end.add(const Duration(days: 1)));
    date = date.add(const Duration(days: 1))
  ) {
    daysInRange.add(date.weekday);
  }

  final data = await supabase
      .from('jadwal_mengajar')
      .select('*, kelas:kelas_id(*), mata_pelajaran:mata_pelajaran_id(*)')
      .eq('guru_id', user['profil']['id'])
      .inFilter('hari_dalam_minggu', daysInRange.toList());

  return List<Map<String, dynamic>>.from(data);
});
