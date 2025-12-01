// lib/app_shell.dart

import 'package:flutter/material.dart';
import '../screens/theme_page.dart';
import '../screens/game_modes_page.dart';
import '../screens/stats_page.dart';
import '../screens/account_page.dart';
import '../utils/responsive_helper.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  
  // La liste des pages est définie ici.
  // Elles seront construites une seule fois et gardées en mémoire.
  final List<Widget> _pages = [
    const ThemePage(),
    const GameModesPage(),
    const StatsPage(),
    const AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);
    final double labelFontSize = rh.w(2.8).clamp(10.0, 14.0);
    final double iconSize = rh.w(6);

    return Scaffold(
      // On utilise IndexedStack. Il garde toutes les pages en vie
      // et n'affiche que celle correspondant à l'index.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.grey.shade600,
        selectedItemColor: Theme.of(context).primaryColor,
        iconSize: iconSize,
        selectedFontSize: labelFontSize,
        unselectedFontSize: labelFontSize * 0.9,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Culture'),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad_outlined), activeIcon: Icon(Icons.gamepad), label: 'Modes de jeu'),
          BottomNavigationBarItem(icon: Icon(Icons.query_stats_outlined), activeIcon: Icon(Icons.query_stats), label: 'Statistiques'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), activeIcon: Icon(Icons.account_circle), label: 'Compte'),
        ],
      ),
    );
  }
}