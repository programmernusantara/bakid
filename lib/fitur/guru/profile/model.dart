class ProfilGuru {
  final String id;
  final String namaLengkap;
  final String? fotoUrl;
  final String? nomorTelepon;
  final String? jabatan;
  final String? asalDaerah;
  final String? alamat;

  ProfilGuru({
    required this.id,
    required this.namaLengkap,
    this.fotoUrl,
    this.nomorTelepon,
    this.jabatan,
    this.asalDaerah,
    this.alamat,
  });

  factory ProfilGuru.fromMap(Map<String, dynamic> map) {
    return ProfilGuru(
      id: map['id'],
      namaLengkap: map['nama_lengkap'],
      fotoUrl: map['foto_url'],
      nomorTelepon: map['nomor_telepon'],
      jabatan: map['jabatan'],
      asalDaerah: map['asal_daerah'],
      alamat: map['alamat'],
    );
  }
}
