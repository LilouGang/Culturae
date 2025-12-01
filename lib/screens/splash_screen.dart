// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/data_manager.dart';
import '../auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final dataManager = Provider.of<DataManager>(context, listen: false);

    // 1. On lance le chargement des données ET un délai minimum
    final dataLoadingFuture = dataManager.loadAllData();
    final minDelayFuture = Future.delayed(const Duration(milliseconds: 1500));

    // 2. ON ATTEND QUE LES DONNÉES SOIENT CHARGÉES
    await dataLoadingFuture;

    // 3. SEULEMENT APRÈS, on lance le pré-chargement des images
    if (mounted) {
      await _precacheAppImages(context, dataManager);
    }
    
    // 4. On attend que le délai minimum soit aussi passé
    await minDelayFuture;

    // 5. On navigue
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  // NOUVELLE FONCTION DE PRÉ-CHARGEMENT
  Future<void> _precacheAppImages(BuildContext context, DataManager dataManager) async {
    final allStyles = [...dataManager.themes, ...dataManager.subThemes];
    final List<Future<void>> precacheFutures = [];

    for (var style in allStyles) {
      if (style.imagePath != null && style.imagePath!.isNotEmpty) {
        precacheFutures.add(precacheImage(AssetImage(style.imagePath!), context));
      }
    }

    await Future.wait(precacheFutures);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Chargement..."),
          ],
        ),
      ),
    );
  }
}