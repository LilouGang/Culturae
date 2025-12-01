// lib/screens/game_modes_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/page_layout.dart';
import '../utils/responsive_helper.dart';
import 'infinite_quiz_page.dart';
import '../widgets/theme_card.dart';
import '../models/theme_info.dart';

class GameModesPage extends StatefulWidget {
  const GameModesPage({super.key});

  @override
  State<GameModesPage> createState() => _GameModesPageState();
}

class _GameModesPageState extends State<GameModesPage> {
  int _infiniteBestScore = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBestScore();
  }

  Future<void> _fetchBestScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _infiniteBestScore = userDoc.data()?['infiniteBestScore'] as int? ?? 0;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);

    return PageLayout(
      title: 'Modes de Jeu',
      titleTextStyle: TextStyle(
        color: Theme.of(context).textTheme.titleLarge?.color,
        fontSize: rh.w(6),
        fontWeight: FontWeight.w500,
      ),
      child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + rh.h(2),
              left: rh.w(4), right: rh.w(4), bottom: rh.h(2),
            ),
            children: [
              // --- CARTE DU MODE INFINI ---
              ThemeCard(
                themeInfo: ThemeInfo(
                  name: "Mode Infini",
                  icon: Icons.all_inclusive,
                  imagePath: 'assets/images/infinite_mode.jpg', 
                  textColor: Colors.white,
                ),
                // Le widget pour le meilleur score
                trailingWidget: RichText(
                  textAlign: TextAlign.right, // Aligne le texte à droite
                  text: TextSpan(
                    style: TextStyle(fontSize: rh.w(3.5)), // Style par défaut
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Meilleur score : ',
                        style: TextStyle(color: Colors.white70), // Texte en blanc clair
                      ),
                      TextSpan(
                        text: _infiniteBestScore.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Score en blanc normal et gras
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InfiniteQuizPage()),
                  );
                  _fetchBestScore();
                },
              ),
              
              // --- CARTE DU MODE AVENTURE ---
              ThemeCard(
                themeInfo: ThemeInfo(
                  name: "Mode Aventure",
                  icon: Icons.explore_outlined,
                  imagePath: 'assets/images/aventure_mode.jpg', 
                  textColor: Colors.white,
                ),
                // Le onTap est null pour la rendre non cliquable
                onTap: null, 
                // Le widget pour le badge "Bientôt"
                trailingWidget: Container(
                  padding: EdgeInsets.symmetric(horizontal: rh.w(3), vertical: rh.w(1.5)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(rh.w(5)),
                  ),
                  child: Text(
                    "Bientôt",
                    style: TextStyle(color: Colors.white, fontSize: rh.w(3), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}