import 'package:animations/animations.dart';
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

  final List<String> _titles = ['Beranda', 'Absen', 'Siswa', 'Jurnal', 'Izin'];

  final List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.how_to_reg_outlined,
    Icons.group_outlined,
    Icons.menu_book_outlined,
    Icons.event_note_outlined,
  ];

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: Colors.blue.withAlpha(100),
        elevation: 1,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(_titles.length, (i) {
          return NavigationDestination(
            icon: Icon(_icons[i], color: Colors.grey[600]),
            selectedIcon: Icon(_icons[i], color: Colors.blueAccent),
            label: _titles[i],
          );
        }),
      ),
    );
  }
}
