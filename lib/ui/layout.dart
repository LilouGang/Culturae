import 'package:flutter/material.dart';
import 'quiz_page.dart'; // On importe la page de quiz

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- PARTIE 1 : LA SIDEBAR FIXE ---
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Text("QUIZ APP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(height: 50),
                // Tes boutons de menu sont ici, directement.
                _MenuButton(title: "Jouer", icon: Icons.play_arrow, isActive: true),
                _MenuButton(title: "Classement", icon: Icons.leaderboard, isActive: false),
                _MenuButton(title: "Profil", icon: Icons.person, isActive: false),
              ],
            ),
          ),
          
          // --- PARTIE 2 : L'ÉCRAN CHANGEANT (QUIZ) ---
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(40.0),
              // C'est ici qu'on affiche ton QuizPage
              child: const QuizPage(), 
            ),
          ),
        ],
      ),
    );
  }
}

// Le petit bouton du menu, local au fichier layout
class _MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  const _MenuButton({required this.title, required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.blue : Colors.grey),
      title: Text(title, style: TextStyle(color: isActive ? Colors.blue : Colors.grey[700], fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      selected: isActive,
      onTap: () {},
      hoverColor: Colors.blue.withValues(alpha: 0.05),
    );
  }
}