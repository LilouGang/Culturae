// lib/data/data_manager.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/theme_info.dart';
import '../models/sub_theme_info.dart';

class DataManager with ChangeNotifier {
  DataManager._privateConstructor();
  static final DataManager instance = DataManager._privateConstructor();

  bool _isReady = false;
  bool get isReady => _isReady;

  // Les listes sont à nouveau vides au début
  List<ThemeInfo> themes = [];
  List<SubThemeInfo> subThemes = [];
  List<DocumentSnapshot> allQuestions = [];

  Future<void> loadAllData() async {
    if (_isReady) return;
    try {
      final responses = await Future.wait([
        FirebaseFirestore.instance.collection('ThemesStyles').get(),
        FirebaseFirestore.instance.collection('SousThemesStyles').get(),
      ]);

      final themesSnapshot = responses[0];
      final subThemesSnapshot = responses[1];

      // On traite et stocke les données depuis Firestore
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

    } catch (e, s) {
      print("ERREUR lors du chargement depuis Firestore : $e\n$s");
    }
  }
}