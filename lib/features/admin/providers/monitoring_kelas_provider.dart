// monitoring_kelas_provider.dart
import 'package:bakid/models/monitoring_kelas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final monitoringKelasProvider =
    StreamProvider.autoDispose<List<MonitoringKelas>>((ref) {
      final supabase = Supabase.instance.client;

      return supabase
          .from('monitoring_kelas')
          .stream(primaryKey: ['jadwal_id'])
          .order('jam_pelajaran', ascending: true)
          .map((data) => data.map((e) => MonitoringKelas.fromMap(e)).toList());
    });
