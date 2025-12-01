import 'package:flutter/material.dart';

// Une classe simple pour nous aider à calculer les tailles
class ResponsiveHelper {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;

  ResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  // Fonctions pour obtenir des tailles proportionnelles
  double a(double size) => size; // Taille absolue (pour les icônes par ex.)
  double w(double percent) => screenWidth * (percent / 100); // Pourcentage de la largeur
  double h(double percent) => screenHeight * (percent / 100); // Pourcentage de la hauteur
}