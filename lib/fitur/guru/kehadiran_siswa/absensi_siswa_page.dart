import 'package:bakid/fitur/guru/kehadiran_siswa/isi_absensi_siswa_page.dart';
import 'package:bakid/fitur/guru/kehadiran_siswa/riwayat_absensi_siswa_page.dart';
import 'package:flutter/material.dart';

class AbsensiSiswaPage extends StatelessWidget {
  const AbsensiSiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Siswa'),
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
