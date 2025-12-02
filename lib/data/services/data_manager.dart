import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/theme_info.dart';
import '../models/sub_theme_info.dart';

class DataManager with ChangeNotifier {
  DataManager._privateConstructor();
  static final DataManager instance = DataManager._privateConstructor();

  bool _isReady = false;
  bool get isReady => _isReady;

  List<ThemeInfo> themes = [];
  List<SubThemeInfo> subThemes = [];

  // Charge les Thèmes et Sous-Thèmes au démarrage
  Future<void> loadAllData() async {
    if (_isReady) return;
    try {
      final responses = await Future.wait([
        FirebaseFirestore.instance.collection('ThemesStyles').get(),
        FirebaseFirestore.instance.collection('SousThemesStyles').get(),
      ]);

      final themesSnapshot = responses[0];
      final subThemesSnapshot = responses[1];

      themes = themesSnapshot.docs
          .map((doc) => ThemeInfo.fromFirestore(doc.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
        
      subThemes = subThemesSnapshot.docs
          .map((doc) => SubThemeInfo.fromFirestore(doc.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      
      _isReady = true;
      notifyListeners();

    } catch (e) {
      debugPrint("ERREUR CRITIQUE DATA MANAGER : $e");
      rethrow; 
    }
  }

  // --- NOUVELLES MÉTHODES POUR LA NAVIGATION ---

  // 1. Récupérer les sous-thèmes d'un thème spécifique
  List<SubThemeInfo> getSubThemesFor(String themeName) {
    return subThemes.where((st) => st.parentTheme == themeName).toList();
  }

  // 2. Récupérer les questions pour un thème et sous-thème donnés
  Future<List<Map<String, dynamic>>> getQuestions(String theme, String subTheme) async {
    try {
      // ATTENTION : Vérifie bien que tes champs dans Firestore s'appellent exactement "Theme" et "Sous - thème"
      // Si ta base utilise d'autres noms (ex: "theme", "subTheme"), modifie les chaînes ci-dessous.
      final snapshot = await FirebaseFirestore.instance
          .collection('QuestionsStyles')
          .where('Theme', isEqualTo: theme)
          .where('Sous - thème', isEqualTo: subTheme) 
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Erreur lors de la récupération des questions : $e");
      return [];
    }
  }
}