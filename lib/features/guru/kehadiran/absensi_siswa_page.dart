import 'package:bakid/features/guru/kehadiran/isi_absensi_siswa_page.dart';
import 'package:bakid/features/guru/kehadiran/riwayat_absensi_siswa_page.dart';
import 'package:flutter/material.dart';

class AbsensiSiswaPage extends StatefulWidget {
  const AbsensiSiswaPage({super.key});

  @override
  State<AbsensiSiswaPage> createState() => _AbsensiSiswaPageState();
}

class _AbsensiSiswaPageState extends State<AbsensiSiswaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Absensi Siswa'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(icon: Icon(Icons.edit)),
            Tab(icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [IsiAbsensiSiswaPage(), RiwayatAbsensiSiswaPage()],
      ),
    );
  }
}
