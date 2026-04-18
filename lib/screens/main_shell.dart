import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home/home_screen.dart';
import 'package:flutter_application_1/screens/profile/profile_screen.dart';
import 'package:flutter_application_1/screens/reviews/reviews_screen.dart';
import 'package:flutter_application_1/screens/scan/scan_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<Widget> get _pages => [
    const HomeScreen(),
    const ScanScreen(),
    const ReviewsScreen(),
    const ProfileScreen(),
  ];

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.qr_code_scanner),
      label: 'Scan',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.reviews_rounded),
      label: 'Reviews',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final navItems = _navItems;
    final safeIndex = _index.clamp(0, pages.length - 1).toInt();

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (value) => setState(() => _index = value),
        selectedItemColor: const Color(0xFF0F65FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
