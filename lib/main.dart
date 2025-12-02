import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart'; // Import de l'écran principal
// import 'config/firebase_options.dart'; // Décommente ça quand tu auras bougé le fichier firebase

void main() async {
  // WidgetsFlutterBinding.ensureInitialized(); // Nécessaire pour Firebase
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mon Quiz Flutter',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}