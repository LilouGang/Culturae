import 'theme_info.dart';

class SubThemeInfo extends ThemeInfo {
  final String parentTheme;

  // Le constructeur principal
  SubThemeInfo({
    required super.name,
    required this.parentTheme,
    super.imagePath,
  });

  // Le constructeur factory pour créer depuis Firestore
  factory SubThemeInfo.fromFirestore(Map<String, dynamic> data) {
    return SubThemeInfo(
      name: data['sousTheme'] ?? 'Sans nom',
      parentTheme: data['theme'] ?? 'Sans thème',
      imagePath: data['imagePath'],
    );
  }
}