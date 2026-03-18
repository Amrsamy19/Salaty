import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../features/quran/screens/quran_screen.dart';
import '../l10n/app_localizations.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QuranScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF061026),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: const Color(0xFF061026),
          selectedItemColor: const Color(0xFFC5A35E),
          unselectedItemColor: Colors.white30,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l.isAr ? "الرئيسية" : "Home",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book_rounded),
              label: l.isAr ? "القرآن" : "Quran",
            ),
          ],
        ),
      ),
    );
  }
}
