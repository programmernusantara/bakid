import 'package:animations/animations.dart';
import 'package:bakid/features/guru/absen/absen_page.dart';
import 'package:bakid/features/guru/home/home_page.dart';
import 'package:bakid/features/guru/izin/perizinan_page.dart';
import 'package:bakid/features/guru/jurnal/jurnal_page.dart';
import 'package:bakid/features/guru/kehadiran/absensi_siswa_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
    Iconsax.home,
    Iconsax.finger_scan,
    Iconsax.people,
    Iconsax.book,
    Iconsax.note,
  ];

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          height: 70,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorColor: Colors.blue[100],
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: List.generate(_titles.length, (i) {
            return NavigationDestination(
              icon: Badge(
                backgroundColor:
                    _selectedIndex == i
                        ? Colors.blue
                        : Colors.grey.withAlpha(100),
                smallSize: 8,
                child: Icon(_icons[i], size: 24),
              ),
              selectedIcon: Icon(_icons[i], size: 24, color: Colors.blue[800]),
              label: _titles[i],
            );
          }),
        ),
      ),
    );
  }
}
