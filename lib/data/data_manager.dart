import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MODÈLES ---
class ThemeInfo {
  final String name;
  ThemeInfo({required this.name});
  factory ThemeInfo.fromFirestore(Map<String, dynamic> data) => ThemeInfo(name: data['name'] ?? 'Sans nom');
}

class SubThemeInfo {
  final String name;
  final String parentTheme;
  SubThemeInfo({required this.name, required this.parentTheme});
  factory SubThemeInfo.fromFirestore(Map<String, dynamic> data) => SubThemeInfo(name: data['sousTheme'] ?? 'Sans nom', parentTheme: data['theme'] ?? 'Sans thème');
}

class UserProfile {
  String id;
  String username;
  String email;
  int totalAnswers;
  int totalCorrectAnswers;
  DateTime? createdAt;
  
  Map<String, int> scores; 
  // Structure : { 'Histoire': { '2025-12-09': 10, '2025-12-08': 5 }, 'Maths': { ... } }
  Map<String, Map<String, int>> dailyActivity; 

  UserProfile({
    this.id = "guest",
    this.username = "Invité",
    this.email = "",
    this.totalAnswers = 0,
    this.totalCorrectAnswers = 0,
    this.createdAt,
    this.scores = const {},
    this.dailyActivity = const {},
  });

  double get successRate => totalAnswers == 0 ? 0.0 : (totalCorrectAnswers / totalAnswers);
  bool get hasFakeEmail => email.endsWith("@noreply.culturek.com");

  // --- NOUVELLE FONCTION POUR LE GRAPHIQUE EMPILLÉ ---
  // Retourne : Map<Date, Map<Theme, Count>>
  // Ex: { 09/12: {'Histoire': 5, 'Sport': 2}, 08/12: {'Histoire': 3} }
  Map<DateTime, Map<String, int>> getLast7DaysStackedStats() {
    Map<DateTime, Map<String, int>> result = {};
    DateTime now = DateTime.now();

    // 1. Initialiser les 7 derniers jours avec des maps vides
    for (int i = 6; i >= 0; i--) {
      DateTime day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[day] = {};
    }

    // 2. Remplir avec les données réelles
    dailyActivity.forEach((themeName, datesMap) {
      datesMap.forEach((dateString, count) {
        try {
          // On gère les deux formats possibles (tirets ou slashs) pour éviter les bugs
          List<String> parts = dateString.contains('/') ? dateString.split('/') : dateString.split('-');
          
          if(parts.length == 3) {
            DateTime date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            
            // On cherche si cette date existe dans nos 7 jours affichés
            // (On compare year/month/day pour ignorer les heures)
            DateTime? key = result.keys.cast<DateTime?>().firstWhere(
              (k) => k != null && k.year == date.year && k.month == date.month && k.day == date.day, 
              orElse: () => null
            );

            if (key != null) {
              // Si la date est trouvée, on ajoute le score du thème
              result[key]![themeName] = (result[key]![themeName] ?? 0) + count;
            }
          }
        } catch (e) { debugPrint("Erreur parsing date stat ($dateString): $e"); }
      });
    });
    return result;
  }

  Map<String, String> getBestAndWorstThemes() {
    if (scores.isEmpty) return {'best': '-', 'worst': '-'};
    var sortedEntries = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value)); 
    return {'best': sortedEntries.first.key, 'worst': sortedEntries.last.key};
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
  UserProfile currentUser = UserProfile();
  int totalQuestionsInDb = 0; 

  Future<void> loadAllData() async {
    if (_isReady) return;
    try {
      final responses = await Future.wait([
        FirebaseFirestore.instance.collection('ThemesStyles').get(),
        FirebaseFirestore.instance.collection('SousThemesStyles').get(),
        FirebaseFirestore.instance.collection('Questions').get(), 
      ]);

      themes = (responses[0] as QuerySnapshot).docs
          .map((doc) => ThemeInfo.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList()..sort((a, b) => a.name.compareTo(b.name));
          
      subThemes = (responses[1] as QuerySnapshot).docs
          .map((doc) => SubThemeInfo.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList()..sort((a, b) => a.name.compareTo(b.name));
      
      totalQuestionsInDb = (responses[2] as QuerySnapshot).size;

      if (FirebaseAuth.instance.currentUser != null) {
        await _loadUserProfile(FirebaseAuth.instance.currentUser!.uid);
      }

      _isReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint("ERREUR DATA : $e");
      rethrow; 
    }
  }

  // --- AUTHENTIFICATION ---
  Future<void> signIn(String identifier, String password) async {
    try {
      String emailToUse = identifier.trim();
      if (!emailToUse.contains('@')) {
        final query = await FirebaseFirestore.instance.collection('Users').where('username', isEqualTo: identifier.trim()).limit(1).get();
        if (query.docs.isEmpty) throw FirebaseAuthException(code: 'user-not-found', message: "Pseudo introuvable.");
        emailToUse = query.docs.first.get('email');
      }
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailToUse, password: password);
      await _loadUserProfile(cred.user!.uid);
    } catch (e) { rethrow; }
  }

  Future<void> signUp(String username, String email, String password) async {
    try {
      String finalEmail = email.trim();
      if (finalEmail.isEmpty) {
        final cleanUsername = username.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        finalEmail = "$cleanUsername${DateTime.now().millisecondsSinceEpoch}@noreply.culturek.com";
      }
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: finalEmail, password: password);
      final newUser = UserProfile(id: cred.user!.uid, username: username.trim(), email: finalEmail, createdAt: DateTime.now());
      await FirebaseFirestore.instance.collection('Users').doc(cred.user!.uid).set({
        'username': newUser.username, 'email': newUser.email, 'totalAnswers': 0, 'totalCorrectAnswers': 0, 'createdAt': FieldValue.serverTimestamp(),
      });
      currentUser = newUser;
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<void> resetPassword(String identifier) async {
    try {
      String emailToUse = identifier.trim();
      if (!emailToUse.contains('@')) {
        final query = await FirebaseFirestore.instance.collection('Users').where('username', isEqualTo: identifier.trim()).limit(1).get();
        if (query.docs.isEmpty) throw FirebaseAuthException(code: 'user-not-found', message: "Pseudo introuvable.");
        emailToUse = query.docs.first.get('email');
      }
      if (emailToUse.endsWith("@noreply.culturek.com")) throw FirebaseAuthException(code: 'no-email-linked', message: "Ce compte n'a pas d'email valide.");
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailToUse);
    } catch (e) { rethrow; }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser.id == "guest") return;
      await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
    } catch (e) { rethrow; }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    currentUser = UserProfile();
    notifyListeners();
  }

  Future<void> updateProfile({String? newUsername, String? newEmail}) async {
    final uid = currentUser.id;
    if (uid == "guest") return;
    if (newEmail != null && newEmail.isNotEmpty && newEmail != currentUser.email) {
      await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(newEmail);
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({'email': newEmail});
      currentUser.email = newEmail;
    }
    if (newUsername != null && newUsername != currentUser.username) {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({'username': newUsername});
      currentUser.username = newUsername;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      DateTime? createdDate;
      if (data['createdAt'] != null && data['createdAt'] is Timestamp) createdDate = (data['createdAt'] as Timestamp).toDate();
      
      Map<String, int> parsedScores = {};
      if (data['scores'] != null && data['scores'] is Map) {
        (data['scores'] as Map).forEach((k, v) {
          if (v is Map && v['dynamicScore'] != null) {
            parsedScores[k.toString()] = (v['dynamicScore'] as num).toInt();
          } else if (v is num) {
            parsedScores[k.toString()] = v.toInt();
          }
        });
      }

      Map<String, Map<String, int>> parsedDaily = {};
      if (data['dailyActivityByTheme'] != null && data['dailyActivityByTheme'] is Map) {
        (data['dailyActivityByTheme'] as Map).forEach((theme, dateMap) {
          Map<String, int> dates = {};
          if (dateMap is Map) {
            dateMap.forEach((date, count) {
              dates[date.toString()] = (count as num).toInt();
            });
          }
          parsedDaily[theme.toString()] = dates;
        });
      }

      currentUser = UserProfile(
        id: uid,
        username: data['username'] ?? 'Utilisateur',
        email: data['email'] ?? '',
        totalAnswers: data['totalAnswers'] ?? 0,
        totalCorrectAnswers: data['totalCorrectAnswers'] ?? 0,
        createdAt: createdDate,
        scores: parsedScores,
        dailyActivity: parsedDaily,
      );
    }
    notifyListeners();
  }

  List<SubThemeInfo> getSubThemesFor(String themeName) => subThemes.where((st) => st.parentTheme == themeName).toList();
  
  Future<List<Map<String, dynamic>>> getQuestions(String theme, String subTheme) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Questions').where('theme', isEqualTo: theme).where('sousTheme', isEqualTo: subTheme).get();
      return snapshot.docs.map((doc) {
        final d = doc.data();
        d['id'] = doc.id;
        return d;
      }).toList();
    } catch (e) { return []; }
  }

  // --- SAUVEGARDE DES RÉPONSES ---
  // J'ai ajouté le paramètre required 'themeName'
  Future<void> addAnswer(bool isCorrect, String questionId, String answerText, String themeName) async {
    if (currentUser.id == "guest") {
      currentUser.totalAnswers++;
      if (isCorrect) currentUser.totalCorrectAnswers++;
      notifyListeners();
    } else {
      try {
        final userRef = FirebaseFirestore.instance.collection('Users').doc(currentUser.id);
        
        // 1. Mise à jour des totaux
        await userRef.update({
          'totalAnswers': FieldValue.increment(1),
          'totalCorrectAnswers': FieldValue.increment(isCorrect ? 1 : 0),
        });

        // 2. Mise à jour de l'activité quotidienne PAR THÈME
        final now = DateTime.now();
        // Formatage strict yyyy-MM-dd pour éviter les soucis de tri
        final dateKey = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
        
        // Utilisation de la notation par points pour cibler spécifiquement ce thème et cette date
        try {
          await userRef.update({
             "dailyActivityByTheme.$themeName.$dateKey": FieldValue.increment(1) 
          });
        } catch(e) {
          // Fallback si la structure n'existe pas : merge
          await userRef.set({
            "dailyActivityByTheme": {
              themeName: { dateKey: FieldValue.increment(1) }
            }
          }, SetOptions(merge: true));
        }

        // 3. Mise à jour locale pour affichage instantané sans recharger
        currentUser.totalAnswers++;
        if (isCorrect) currentUser.totalCorrectAnswers++;
        
        // Update local du dailyActivity
        Map<String, int> themeMap = currentUser.dailyActivity[themeName] ?? {};
        themeMap[dateKey] = (themeMap[dateKey] ?? 0) + 1;
        currentUser.dailyActivity[themeName] = themeMap;

        notifyListeners();
      } catch (e) {
        debugPrint("Erreur update User stats: $e");
      }
    }

    if (questionId.isNotEmpty) {
      try {
        final qRef = FirebaseFirestore.instance.collection('Questions').doc(questionId);
        await qRef.update({
          'timesAnswered': FieldValue.increment(1),
          'timesCorrect': FieldValue.increment(isCorrect ? 1 : 0),
          'answerStats.$answerText': FieldValue.increment(1),
        });
      } catch (e) { debugPrint("Erreur update Question stats: $e"); }
    }
  }
}