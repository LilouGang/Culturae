import 'package:flutter/material.dart';

class ThemeInfo {
  final String name;
  final IconData? icon;
  final Gradient? gradient;
  final String? imagePath;
  final Color? color;
  final Color textColor;

  const ThemeInfo({
    required this.name,
    this.icon,
    this.gradient,
    this.imagePath,
    this.color,
    this.textColor = Colors.white,
  });

  factory ThemeInfo.fromFirestore(Map<String, dynamic> data) {
    return ThemeInfo(
      name: data['name'] ?? 'Sans nom',
      imagePath: data['imagePath'],
      textColor: data['textColor'] == 'black' ? Colors.black87 : Colors.white,
    );
  }
}