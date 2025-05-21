import 'package:bakid/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';

final izinDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final jadwalIzinProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  final dateRange = ref.watch(izinDateRangeProvider);

  if (user == null || user['profil'] == null || dateRange == null) return [];

  final supabase = ref.watch(supabaseProvider);

  // Hitung hari dalam rentang tanggal
  final daysInRange = <int>{};
  final datesInRange = <DateTime>[];
  for (
    var date = dateRange.start;
    date.isBefore(dateRange.end.add(const Duration(days: 1)));
    date = date.add(const Duration(days: 1))
  ) {
    daysInRange.add(date.weekday);
    datesInRange.add(date);
  }

  // Query untuk mendapatkan jadwal yang sesuai
  final jadwal = await supabase
      .from('jadwal_mengajar')
      .select('*, kelas:kelas_id(*), mata_pelajaran:mata_pelajaran_id(*)')
      .eq('guru_id', user['profil']['id'])
      .inFilter('hari_dalam_minggu', daysInRange.toList());

  // Query untuk mendapatkan izin yang sudah ada
  final existingIzin = await supabase
      .from('permohonan_izin')
      .select('jadwal_id, tanggal_efektif')
      .eq('guru_id', user['profil']['id'])
      .inFilter(
        'tanggal_efektif',
        datesInRange.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
      )
      .inFilter('status', [
        'menunggu',
        'disetujui',
      ]); // Perubahan: tambah status disetujui

  // Filter jadwal yang belum memiliki izin aktif
  final filteredJadwal =
      jadwal.where((j) {
        return !existingIzin.any((izin) => izin['jadwal_id'] == j['id']);
      }).toList();

  return filteredJadwal;
});
