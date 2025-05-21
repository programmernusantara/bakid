import 'package:bakid/features/guru/izin/ajukan_izin_page.dart';
import 'package:bakid/features/guru/izin/riwayat_izin_page.dart';
import 'package:flutter/material.dart';

class PerizinanPage extends StatelessWidget {
  const PerizinanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perizinan Guru'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AjukanIzinPage()),
              );
            },
          ),
        ],
      ),
      body: const RiwayatIzinPage(),
    );
  }
}
