import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- MODÈLES (Simplifiés et intégrés ici) ---

class ThemeInfo {
  final String name;
  ThemeInfo({required this.name});
  factory ThemeInfo.fromFirestore(Map<String, dynamic> data) {
    return ThemeInfo(name: data['name'] ?? 'Sans nom');
  }
}

class SubThemeInfo {
  final String name;
  final String parentTheme;
  SubThemeInfo({required this.name, required this.parentTheme});
  factory SubThemeInfo.fromFirestore(Map<String, dynamic> data) {
    return SubThemeInfo(
      name: data['sousTheme'] ?? 'Sans nom',
      parentTheme: data['theme'] ?? 'Sans thème',
    );
  }
}

// --- GESTIONNAIRE DE DONNÉES ---

class DataManager with ChangeNotifier {
  DataManager._privateConstructor();
  static final DataManager instance = DataManager._privateConstructor();

  bool _isReady = false;
  bool get isReady => _isReady;

  List<ThemeInfo> themes = [];
  List<SubThemeInfo> subThemes = [];

  Future<void> loadAllData() async {
    if (_isReady) return;
    try {
      final responses = await Future.wait([
        FirebaseFirestore.instance.collection('ThemesStyles').get(),
        FirebaseFirestore.instance.collection('SousThemesStyles').get(),
      ]);

      themes = responses[0].docs
          .map((doc) => ThemeInfo.fromFirestore(doc.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
        
      subThemes = responses[1].docs
          .map((doc) => SubThemeInfo.fromFirestore(doc.data()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      
      _isReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint("ERREUR DATA : $e");
      rethrow; 
    }
  }

  List<SubThemeInfo> getSubThemesFor(String themeName) {
    return subThemes.where((st) => st.parentTheme == themeName).toList();
  }

  Future<List<Map<String, dynamic>>> getQuestions(String theme, String subTheme) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Questions')
          .where('Theme', isEqualTo: theme)
          .where('sousTheme', isEqualTo: subTheme) 
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Erreur questions : $e");
      return [];
    }
  }
}