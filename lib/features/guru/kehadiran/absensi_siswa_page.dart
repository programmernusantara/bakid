import 'package:bakid/features/guru/kehadiran/isi_absensi_siswa_page.dart';
import 'package:bakid/features/guru/kehadiran/riwayat_absensi_siswa_page.dart';
import 'package:flutter/material.dart';

class AbsensiSiswaPage extends StatelessWidget {
  const AbsensiSiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Absensi Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IsiAbsensiSiswaPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: const RiwayatAbsensiSiswaPage(),
    );
  }
}
