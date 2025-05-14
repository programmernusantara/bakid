// monitoring_kelas_model.dart
class MonitoringKelas {
  final String jadwalId;
  final String kelas;
  final String guru;
  final String mataPelajaran;
  final String jamPelajaran;
  final String kehadiran;
  final String jurnal;
  final DateTime lastUpdate;

  MonitoringKelas({
    required this.jadwalId,
    required this.kelas,
    required this.guru,
    required this.mataPelajaran,
    required this.jamPelajaran,
    required this.kehadiran,
    required this.jurnal,
    required this.lastUpdate,
  });

  factory MonitoringKelas.fromMap(Map<String, dynamic> map) {
    return MonitoringKelas(
      jadwalId: map['jadwal_id'] ?? '',
      kelas: map['kelas'] ?? '',
      guru: map['guru'] ?? '',
      mataPelajaran: map['mata_pelajaran'] ?? '',
      jamPelajaran: map['jam_pelajaran'] ?? '',
      kehadiran: map['kehadiran'] ?? '❌ Belum Absen',
      jurnal: map['jurnal'] ?? 'Belum diisi',
      lastUpdate: DateTime.parse(map['last_update']),
    );
  }
}
