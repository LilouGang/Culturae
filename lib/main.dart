import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'system/firebase_options.dart';
import 'ui/layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CORRECTION ICI : On vérifie si Firebase est déjà actif avant de l'initialiser
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CultureK Web',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MainLayout(),
    );
  }
}