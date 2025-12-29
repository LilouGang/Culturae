import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeInfo {
  final String name;
  ThemeInfo({required this.name});
  factory ThemeInfo.fromFirestore(Map<String, dynamic> data) => ThemeInfo(name: data['name'] ?? 'Sans nom');
}

class SubThemeInfo {
  final String name;
  final String parentTheme;
  final int questionCount; 

  SubThemeInfo({required this.name, required this.parentTheme, this.questionCount = 80});

  factory SubThemeInfo.fromFirestore(Map<String, dynamic> data) {
    return SubThemeInfo(
      name: data['sousTheme'] ?? 'Sans nom', 
      parentTheme: data['theme'] ?? 'Sans thème',
      questionCount: 80 
    );
  }
}

class UserProfile {
  String id;
  String username;
  String email;
  DateTime? createdAt;
  int totalAnswers; 
  List<String> seenQuestionIds;
  List<String> answeredQuestions;
  Map<String, int> scores; 
  
  Map<String, Map<String, int>> dailyActivity; 

  UserProfile({
    this.id = "guest",
    this.username = "Invité",
    this.email = "",
    this.totalAnswers = 0,
    this.createdAt,
    this.seenQuestionIds = const [],
    this.answeredQuestions = const [],
    this.scores = const {},
    this.dailyActivity = const {},
  });

  int get progressionCount => seenQuestionIds.length;

  double get precision {
    if (seenQuestionIds.isEmpty) return 0.0;
    return answeredQuestions.length / seenQuestionIds.length;
  }

  double getCompletion(int totalDb) {
    if (totalDb == 0) return 0.0;
    return seenQuestionIds.length / totalDb;
  }

  bool get hasFakeEmail => email.endsWith("@noreply.culturae.com");

  Map<DateTime, Map<String, int>> getLast7DaysStackedStats() {
    Map<DateTime, Map<String, int>> result = {};
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[day] = {};
    }
    dailyActivity.forEach((themeName, datesMap) {
      datesMap.forEach((dateString, count) {
        try {
          List<String> parts = dateString.contains('/') ? dateString.split('/') : dateString.split('-');
          if(parts.length == 3) {
            DateTime date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            DateTime? key = result.keys.cast<DateTime?>().firstWhere(
              (k) => k != null && k.year == date.year && k.month == date.month && k.day == date.day, 
              orElse: () => null
            );
            if (key != null) {
              result[key]![themeName] = (result[key]![themeName] ?? 0) + count;
            }
          }
        } catch (e) { }
      });
    });
    return result;
  }
}


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
      ]);

      themes = (responses[0] as QuerySnapshot).docs
          .map((doc) => ThemeInfo.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList()..sort((a, b) => a.name.compareTo(b.name));
          
      subThemes = (responses[1] as QuerySnapshot).docs
          .map((doc) => SubThemeInfo.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList()..sort((a, b) => a.name.compareTo(b.name));
      
      totalQuestionsInDb = subThemes.length * 80;

      if (FirebaseAuth.instance.currentUser != null) {
        await _loadUserProfile(FirebaseAuth.instance.currentUser!.uid);
      }

      _isReady = true;
      notifyListeners();
    } catch (e) {
      rethrow; 
    }
  }

  int countTotalQuestionsForTheme(String themeName) {
    int nbSubThemes = subThemes.where((st) => st.parentTheme == themeName).length;
    int total = nbSubThemes * 80;
    return total > 0 ? total : 1; 
  }

  int countTotalQuestionsForSubTheme(String themeName, String subThemeName) {
    return 80;
  }

  Future<List<Map<String, dynamic>>> getQuestions(String theme, String subTheme) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Questions')
          .where('theme', isEqualTo: theme)
          .where('sousTheme', isEqualTo: subTheme)
          .get();
          
      return snapshot.docs.map((doc) {
        final d = doc.data();
        d['id'] = doc.id;
        return d;
      }).toList();
    } catch (e) { 
      return []; 
    }
  }

  Future<void> signIn(String identifier, String password) async {
    try {
      String emailToUse = identifier.trim();
      if (!emailToUse.contains('@')) {
        final query = await FirebaseFirestore.instance.collection('Users')
            .where('username', isEqualTo: identifier.trim())
            .limit(1)
            .get();
        if (query.docs.isEmpty) throw FirebaseAuthException(code: 'user-not-found', message: "Pseudo introuvable.");
        emailToUse = query.docs.first.get('email');
      }
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailToUse, password: password);
      await _loadUserProfile(cred.user!.uid);
    } catch (e) { rethrow; }
  }

  Future<void> signUp(String username, String email, String password) async {
    try {
      final String cleanUsername = username.trim();
      final usernameCheck = await FirebaseFirestore.instance.collection('Users').where('username', isEqualTo: cleanUsername).limit(1).get();
      if (usernameCheck.docs.isNotEmpty) throw FirebaseAuthException(code: 'username-already-in-use', message: "Ce pseudo est déjà pris.");

      String finalEmail = email.trim();
      if (finalEmail.isEmpty) {
        final cleanUsernameForEmail = cleanUsername.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        finalEmail = "$cleanUsernameForEmail${DateTime.now().millisecondsSinceEpoch}@noreply.culturae.com";
      }

      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: finalEmail, password: password);
      
      final newUser = UserProfile(id: cred.user!.uid, username: cleanUsername, email: finalEmail, createdAt: DateTime.now());
      
      await FirebaseFirestore.instance.collection('Users').doc(cred.user!.uid).set({
        'username': newUser.username, 
        'email': newUser.email, 
        'totalAnswers': 0, 
        'createdAt': FieldValue.serverTimestamp(),
        'answeredQuestions': [],
        'seenQuestionIds': [],
        'scores': {}, 
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
      if (emailToUse.endsWith("@noreply.culturae.com")) throw FirebaseAuthException(code: 'no-email-linked', message: "Ce compte n'a pas d'email valide.");
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
      final String cleanNewUsername = newUsername.trim();
      final usernameCheck = await FirebaseFirestore.instance.collection('Users').where('username', isEqualTo: cleanNewUsername).limit(1).get();
      if (usernameCheck.docs.isNotEmpty) throw FirebaseAuthException(code: 'username-already-in-use', message: "Ce pseudo est déjà pris.");
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({'username': cleanNewUsername});
      currentUser.username = cleanNewUsername;
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
          if (v is num) {
            parsedScores[k.toString()] = v.toInt();
          } else if (v is Map && v['dynamicScore'] != null) {
            parsedScores[k.toString()] = (v['dynamicScore'] as num).toInt();
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

      List<String> loadedAnsweredIds = [];
      if (data['answeredQuestions'] != null) {
        try { loadedAnsweredIds = List<String>.from(data['answeredQuestions']); } catch (e) { debugPrint("Err answeredQuestions: $e"); }
      }

      List<String> loadedSeenIds = [];
      if (data['seenQuestionIds'] != null) {
        try { loadedSeenIds = List<String>.from(data['seenQuestionIds']); } catch (e) { debugPrint("Err seenQuestionIds: $e"); }
      }

      currentUser = UserProfile(
        id: uid,
        username: data['username'] ?? 'Utilisateur',
        email: data['email'] ?? '',
        totalAnswers: data['totalAnswers'] ?? 0,
        createdAt: createdDate,
        scores: parsedScores,
        dailyActivity: parsedDaily,
        answeredQuestions: loadedAnsweredIds,
        seenQuestionIds: loadedSeenIds,
      );
    }
    notifyListeners();
  }

  List<SubThemeInfo> getSubThemesFor(String themeName) => subThemes.where((st) => st.parentTheme == themeName).toList();
  
  Future<void> addAnswer(bool isCorrect, String questionId, String answerText, String themeName, [String? subThemeName]) async {
    currentUser.totalAnswers++;
    
    bool isNewDiscovery = false;
    if (!currentUser.seenQuestionIds.contains(questionId)) {
      currentUser.seenQuestionIds.add(questionId);
      isNewDiscovery = true;
    }

    bool masteryStatusChanged = false;
    int scoreModifier = 0; // +1 ou -1

    if (isCorrect) {
      if (!currentUser.answeredQuestions.contains(questionId)) {
        currentUser.answeredQuestions.add(questionId);
        masteryStatusChanged = true;
        scoreModifier = 1;
      }
    } else {
      if (currentUser.answeredQuestions.contains(questionId)) {
        currentUser.answeredQuestions.remove(questionId);
        masteryStatusChanged = true;
        scoreModifier = -1;
      }
    }

    if (masteryStatusChanged && scoreModifier != 0) {
      currentUser.scores[themeName] = (currentUser.scores[themeName] ?? 0) + scoreModifier;
      if (currentUser.scores[themeName]! < 0) currentUser.scores[themeName] = 0;

      if (subThemeName != null) {
        currentUser.scores[subThemeName] = (currentUser.scores[subThemeName] ?? 0) + scoreModifier;
        if (currentUser.scores[subThemeName]! < 0) currentUser.scores[subThemeName] = 0;
      }
    }

    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
    Map<String, int> themeMap = currentUser.dailyActivity[themeName] ?? {};
    themeMap[dateKey] = (themeMap[dateKey] ?? 0) + 1;
    currentUser.dailyActivity[themeName] = themeMap;

    notifyListeners();

    if (currentUser.id == "guest") return;

    try {
      final userRef = FirebaseFirestore.instance.collection('Users').doc(currentUser.id);
      
      Map<String, dynamic> updates = {
        'totalAnswers': FieldValue.increment(1),
      };

      if (isNewDiscovery) {
        updates['seenQuestionIds'] = FieldValue.arrayUnion([questionId]);
      }

      if (masteryStatusChanged) {
        if (isCorrect) {
          updates['answeredQuestions'] = FieldValue.arrayUnion([questionId]);
        } else {
          updates['answeredQuestions'] = FieldValue.arrayRemove([questionId]);
        }
        
        if (scoreModifier != 0) {
          updates['scores.$themeName'] = FieldValue.increment(scoreModifier);
          if (subThemeName != null) {
             updates['scores.$subThemeName'] = FieldValue.increment(scoreModifier);
          }
        }
      }

      try {
        updates["dailyActivityByTheme.$themeName.$dateKey"] = FieldValue.increment(1);
      } catch(e) {
        await userRef.set({ 
          "dailyActivityByTheme": { themeName: { dateKey: FieldValue.increment(1) } } 
        }, SetOptions(merge: true));
      }

      await userRef.update(updates);

    } catch (e) {
      debugPrint("Erreur update User stats: $e");
    }

    if (questionId.isNotEmpty) {
      try {
        final qRef = FirebaseFirestore.instance.collection('Questions').doc(questionId);
        await qRef.update({
          'timesAnswered': FieldValue.increment(1),
          'timesCorrect': FieldValue.increment(isCorrect ? 1 : 0),
          'answerStats.$answerText': FieldValue.increment(1),
        });
      } catch (e) { 
        debugPrint("Erreur update Question stats: $e");
      }
    }
  }

  Future<void> reportQuestionDetailed({
    required String questionId,
    required String question,
    required String propositions,
    required String explanation,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('QuestionReports').add({
        'userId': currentUser.id,
        'username': currentUser.username,
        'questionId': questionId,
        'suggestedQuestion': question,
        'suggestedPropositions': propositions,
        'suggestedExplanation': explanation,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint("Erreur signalement détaillé : $e");
      rethrow;
    }
  }
}