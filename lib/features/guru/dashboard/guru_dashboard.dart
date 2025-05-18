import 'package:bakid/features/guru/home/home_page.dart';
import 'package:bakid/features/guru/jurnal/jurnal_page.dart';
import 'package:flutter/material.dart';

class GuruDashboard extends StatefulWidget {
  const GuruDashboard({super.key});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomePage(), JurnalPage()];

  final List<String> _titles = [
    'Home',
    'Jurnal',
    'Absen',
    'Kehadiran',
    'Perizinan',
  ];

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.edit_calendar_outlined,
    Icons.fingerprint,
    Icons.checklist_rtl,
    Icons.assignment_turned_in_outlined,
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {
              // Implementasi halaman notifikasi
            },
          ),
        ],
      ),
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
