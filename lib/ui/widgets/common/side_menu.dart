import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Logo ou Titre
          const Text("MY QUIZ APP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          
          // Items du menu
          _MenuItem(title: "Accueil", icon: Icons.home, isActive: true),
          _MenuItem(title: "Statistiques", icon: Icons.bar_chart, isActive: false),
          _MenuItem(title: "Paramètres", icon: Icons.settings, isActive: false),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;

  const _MenuItem({required this.title, required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.blue : Colors.grey),
      title: Text(title, style: TextStyle(color: isActive ? Colors.blue : Colors.grey)),
      onTap: () {}, // Navigation à implémenter
    );
  }
}