// Update lib/features/guru/dashboard/guru_dashboard.dart
import 'package:bakid/features/guru/absen/absen_page.dart';
import 'package:bakid/features/guru/home/home_page.dart';
import 'package:bakid/features/guru/izin/perizinan_page.dart';
import 'package:bakid/features/guru/jurnal/jurnal_page.dart';
import 'package:bakid/features/guru/kehadiran/absensi_siswa_page.dart';
import 'package:flutter/material.dart';

class GuruDashboard extends StatefulWidget {
  const GuruDashboard({super.key});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AbsenTabPage(),
    AbsensiSiswaPage(),
    JurnalPage(),
    PerizinanPage(),
  ];

  final List<String> _titles = ['Home', 'Absen', 'Kehadiran', 'Jurnal', 'Izin'];

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.fingerprint,
    Icons.person,
    Icons.edit_calendar_outlined,
    Icons.assignment,
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
        elevation: 0,
        backgroundColor: Colors.white,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: List.generate(_titles.length, (i) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: _titles[i],
          );
        }),
      ),
    );
  }
}
