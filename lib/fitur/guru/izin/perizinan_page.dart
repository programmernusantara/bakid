// perizinan_page.dart
import 'package:bakid/fitur/guru/izin/ajukan_izin_page.dart';
import 'package:bakid/fitur/guru/izin/riwayat_izin_page.dart';
import 'package:flutter/material.dart';

class PerizinanPage extends StatelessWidget {
  const PerizinanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Perizinan Guru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AjukanIzinPage()),
              );
            },
            tooltip: 'Ajukan Izin',
          ),
        ],
      ),
      body: const RiwayatIzinPage(),
    );
  }
}
