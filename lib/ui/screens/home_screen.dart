import 'package:flutter/material.dart';
import '../widgets/common/side_menu.dart'; // On va le créer juste après

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. Menu Latéral (Taille fixe)
          const SizedBox(
            width: 250,
            child: SideMenu(), 
          ),
          
          // 2. Zone de Contenu (Prend le reste de la place)
          Expanded(
            child: Container(
              color: Colors.grey[100], // Fond gris léger
              padding: const EdgeInsets.all(32),
              child: const Center(
                child: Text("Sélectionne un quiz pour commencer"),
                // Ici, tu mettras plus tard ton QuizScreen ou ta liste de thèmes
              ),
            ),
          ),
        ],
      ),
    );
  }
}