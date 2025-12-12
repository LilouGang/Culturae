import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // <--- N'oublie pas cet import !
import 'system/firebase_options.dart';
import 'data/data_manager.dart'; // Importe ton DataManager
import 'ui/layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    // ON AJOUTE LE PROVIDER ICI
    // Cela rend le DataManager accessible PARTOUT dans l'application
    ChangeNotifierProvider(
      create: (context) => DataManager.instance,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CultureK',
      scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MainLayout(),
    );
  }
}

class NoThumbScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics();
  
  // C'est cette ligne qui cache la barre partout
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}