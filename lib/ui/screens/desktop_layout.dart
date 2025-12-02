import 'package:flutter/material.dart';

class DesktopMainLayout extends StatelessWidget {
  final Widget child; // Le contenu changeant (Le Quiz, Les Stats, etc.)

  const DesktopMainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fond neutre pour le web
      body: Row(
        children: [
          // ZONE 1 : Navigation Latérale (Fixe)
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Text("QUIZ APP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(height: 50),
                _NavButton(title: "Jouer", icon: Icons.play_arrow, isActive: true),
                _NavButton(title: "Classement", icon: Icons.leaderboard, isActive: false),
                _NavButton(title: "Profil", icon: Icons.person, isActive: false),
              ],
            ),
          ),
          
          // ZONE 2 : Contenu Principal (Dynamique)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0), // Marges généreuses sur desktop
              child: Center(
                // On contraint la largeur max pour ne pas étirer le quiz sur tout l'écran
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900), 
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget utilitaire pour les boutons du menu
class _NavButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;

  const _NavButton({required this.title, required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.blue : Colors.grey[700],
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      onTap: () {}, // Navigation ici
      hoverColor: Colors.blue.withValues(alpha: 0.05),
    );
  }
}