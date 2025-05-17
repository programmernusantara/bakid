// models/kelas_model.dart
class Kelas {
  final String id;
  final String nama;
  final String? waliKelas;
  final int? jumlahMurid;
  final String? tahunAjaran;
  final int jumlahJurnal;
  final int jumlahAbsensi;

  Kelas({
    required this.id,
    required this.nama,
    this.waliKelas,
    this.jumlahMurid,
    this.tahunAjaran,
    this.jumlahJurnal = 0,
    this.jumlahAbsensi = 0,
  });

  factory Kelas.fromMap(Map<String, dynamic> map) {
    return Kelas(
      id: map['id'] ?? '',
      nama: map['nama'] ?? '',
      waliKelas: map['wali_kelas'],
      jumlahMurid: map['jumlah_murid'],
      tahunAjaran: map['tahun_ajaran'],
      jumlahJurnal: map['jumlah_jurnal'] ?? 0,
      jumlahAbsensi: map['jumlah_absensi'] ?? 0,
    );
  }
}

class JurnalMengajar {
  final String id;
  final DateTime tanggal;
  final String mataPelajaran;
  final String materi;
  final String? kendala;
  final String? solusi;
  final String jadwalId;
  final String guruId;

  JurnalMengajar({
    required this.id,
    required this.tanggal,
    required this.mataPelajaran,
    required this.materi,
    this.kendala,
    this.solusi,
    required this.jadwalId,
    required this.guruId,
  });

  factory JurnalMengajar.fromMap(Map<String, dynamic> map) {
    return JurnalMengajar(
      id: map['id'] ?? '',
      tanggal: DateTime.parse(map['tanggal']),
      mataPelajaran: map['mata_pelajaran'] ?? '',
      materi: map['materi_yang_dipelajari'] ?? '',
      kendala: map['kendala'],
      solusi: map['solusi'],
      jadwalId: map['jadwal_id'] ?? '',
      guruId: map['guru_id'] ?? '',
    );
  }
}

class RekapAbsensi {
  final String id;
  final DateTime tanggal;
  final int hadir;
  final int izin;
  final int alpa;
  final String? namaIzin;
  final String? namaAlpa;
  final String? keterangan;
  final String? mataPelajaran;

  RekapAbsensi({
    required this.id,
    required this.tanggal,
    required this.hadir,
    required this.izin,
    required this.alpa,
    this.namaIzin,
    this.namaAlpa,
    this.keterangan,
    this.mataPelajaran,
  });

  factory RekapAbsensi.fromMap(Map<String, dynamic> map) {
    return RekapAbsensi(
      id: map['id'] ?? '',
      tanggal: DateTime.parse(map['tanggal']),
      hadir: map['jumlah_hadir'] ?? 0,
      izin: map['jumlah_izin'] ?? 0,
      alpa: map['jumlah_alpa'] ?? 0,
      namaIzin: map['nama_izin'],
      namaAlpa: map['nama_alpa'],
      keterangan: map['keterangan'],
      mataPelajaran: map['mata_pelajaran'],
    );
  }
}
