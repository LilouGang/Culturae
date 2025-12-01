import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/results_page.dart';
import 'package:intl/intl.dart';
import '../utils/responsive_helper.dart';

class QuizPage extends StatefulWidget {
  final String themeName;
  final String subThemeName;
  final List<DocumentSnapshot> questionsToPlay;
  final String quizTitle;
  final String? quizId;

  const QuizPage({
    super.key,
    required this.themeName,
    required this.subThemeName,
    required this.questionsToPlay,
    required this.quizTitle,
    this.quizId, //
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _userJokers = 0;
  int _userIndices = 0;
  bool _isLoadingCurrency = true;
  bool _fiftyFiftyUsed = false;
  bool _audiencePollUsed = false;
  List<String> _removedAnswers = [];
  List<DocumentSnapshot> allQuestions = [];
  int currentQuestionIndex = 0;
  bool isLoading = true;
  Map<String, String> _answerPercentages = {};
  
  String question = "";
  List<String> propositions = [];
  late String bonneReponse;
  String description = "";
  String? selectedProposition;
  bool questionAnswered = false;

  int _correctAnswersCount = 0;
  int _incorrectAnswersCount = 0;
  final Map<String, bool> _answerLog = {};
  final Map<String, String> _sessionAnswers = {};
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndAds();
    _loadProvidedQuestions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserDataAndAds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userJokers = userDoc.data()?['jokers'] as int? ?? 0;
          _userIndices = userDoc.data()?['indices'] as int? ?? 0;
          _isLoadingCurrency = false;
        });
      }
    } else {
      setState(() => _isLoadingCurrency = false);
    }
  }

  void _useFiftyFifty() {
    final user = FirebaseAuth.instance.currentUser;
    if (_fiftyFiftyUsed || _userJokers < 1 || user == null) return;

    setState(() {
      _userJokers--;
      _fiftyFiftyUsed = true;
      
      final wrongAnswers = List<String>.from(propositions)..remove(bonneReponse);
      wrongAnswers.shuffle();
      _removedAnswers = wrongAnswers.take(2).toList(); 
    });

    FirebaseFirestore.instance.collection('Users').doc(user.uid).update({'jokers': FieldValue.increment(-1)});
  }

  Future<void> _useAudiencePoll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_audiencePollUsed || _userIndices < 1 || user == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
      'indices': FieldValue.increment(-1),
    });

    try {
      final questionId = allQuestions[currentQuestionIndex].id;
      final questionDoc = await FirebaseFirestore.instance.collection('Questions').doc(questionId).get();
      
      if (questionDoc.exists && mounted) {
        final stats = Map<String, int>.from(questionDoc.data()?['answerStats'] ?? {});
        final totalVotes = stats.values.fold(0, (sum, count) => sum + count);
        final Map<String, String> percentages = {};

        for (var entry in stats.entries) {
          final percentage = totalVotes > 0 ? (entry.value / totalVotes * 100) : 0;
          percentages[entry.key] = '${percentage.toStringAsFixed(0)}%';
        }
        
        setState(() {
          _userIndices--;
          _answerPercentages = percentages;
          _audiencePollUsed = true;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des stats du public : $e");
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'indices': FieldValue.increment(1),
      });
    }
  }

  void _watchAdForJokers() {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      setState(() => _userJokers += 3);
      FirebaseFirestore.instance.collection('Users').doc(user.uid).update({'jokers': FieldValue.increment(3)});
  }

  void _watchAdForIndices() {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      setState(() => _userIndices += 2);
      FirebaseFirestore.instance.collection('Users').doc(user.uid).update({'indices': FieldValue.increment(2)});
  }

  void _loadProvidedQuestions() {
    allQuestions = List<DocumentSnapshot>.from(widget.questionsToPlay);
    allQuestions.shuffle();
    _displayCurrentQuestion();
  }
  
  void _displayCurrentQuestion() {
    if (currentQuestionIndex >= allQuestions.length) return;

    final currentDoc = allQuestions[currentQuestionIndex];
    final data = currentDoc.data() as Map<String, dynamic>;
    
    List<String> originalPropositions = List<String>.from(data['propositions'] ?? []);

    final String texteBonneReponse = data['reponse'] as String? ?? "";

    originalPropositions.shuffle();

    if (!originalPropositions.contains(texteBonneReponse)) {
      print("ERREUR DE DONNÉES : La bonne réponse '$texteBonneReponse' n'est pas dans la liste des propositions pour la question '${data['question']}'.");
    }

    setState(() {
      question = data['question'] ?? 'Pas de question';
      propositions = originalPropositions;
      bonneReponse = texteBonneReponse;
      description = data['explication'] ?? data['description'] ?? 'Pas d\'explication disponible.';
      selectedProposition = null;
      questionAnswered = false;
      _showExplanation = false;
      isLoading = false;
      _fiftyFiftyUsed = false;
      _audiencePollUsed = false;
      _removedAnswers = [];
    });
  }

  void _handleAnswer(String selectedAnswer) {
    if (questionAnswered) return;

    final isCorrect = selectedAnswer == bonneReponse;
    if (isCorrect) {
      _correctAnswersCount++;
    } else {
      _incorrectAnswersCount++;
    }

    final questionId = allQuestions[currentQuestionIndex].id;
    _answerLog[questionId] = isCorrect;
    _sessionAnswers[questionId] = selectedAnswer;

    setState(() {
      selectedProposition = selectedAnswer;
      questionAnswered = true; // Déclenche opacity: 0.0 sur les jokers
    });

    // 2. On attend la fin de l'animation de disparition
    Future.delayed(const Duration(milliseconds: 100), () {
      // 3. SEULEMENT APRÈS, on lance l'apparition de l'explication
      if (mounted) { // Sécurité pour s'assurer que le widget existe toujours
        setState(() {
          _showExplanation = true; // Déclenche opacity: 1.0 sur l'explication
        });
      }
    });
  }

  Future<void> _onNextButtonPressed() async {
    if (!questionAnswered) return;

    if (currentQuestionIndex < allQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _displayCurrentQuestion();
      });
    } else {
      setState(() => isLoading = true);
      await _finalizeQuiz();
      _navigateToResults();
    }
  }

  Future<void> _finalizeQuiz() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final batch = FirebaseFirestore.instance.batch();

    try {
      final userDoc = await userDocRef.get();
      
      if (!userDoc.exists) {
        userDocRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
      
      final previousAnswers = Map<String, bool>.from(userDoc.data()?['answeredQuestions'] ?? {});

      final Map<String, dynamic> newAnsweredQuestionsUpdates = {};
      int scoreChange = 0;

      _answerLog.forEach((questionId, currentAnswerIsCorrect) {
        final previousAnswerWasCorrect = previousAnswers[questionId];
        if (currentAnswerIsCorrect && previousAnswerWasCorrect != true) {
          scoreChange++;
        } else if (!currentAnswerIsCorrect && previousAnswerWasCorrect == true) {
          scoreChange--;
        }
        newAnsweredQuestionsUpdates['answeredQuestions.$questionId'] = currentAnswerIsCorrect;
      });

      final quizKey = '${widget.themeName}-${widget.subThemeName}';
      final scoreKey = 'scores.$quizKey.dynamicScore';
      
      final int answersInThisQuiz = _answerLog.length;
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dailyActivityKey = 'dailyActivityByTheme.${widget.themeName}.$today';

      batch.update(userDocRef, {
        ...newAnsweredQuestionsUpdates,
        scoreKey: FieldValue.increment(scoreChange),
        'totalAnswers': FieldValue.increment(answersInThisQuiz),
        'totalCorrectAnswers': FieldValue.increment(_correctAnswersCount),
        dailyActivityKey: FieldValue.increment(answersInThisQuiz),
      });

      _answerLog.forEach((questionId, wasCorrect) {
        final String chosenAnswer = _sessionAnswers[questionId]!; 
        final questionRef = FirebaseFirestore.instance.collection('Questions').doc(questionId);
        final answerStatKey = 'answerStats.$chosenAnswer';
        batch.update(questionRef, {
          answerStatKey: FieldValue.increment(1),
        });
        final logRef = FirebaseFirestore.instance.collection('AnswerLogs').doc();
        batch.set(logRef, {
          'userId': user.uid,
          'questionId': questionId,
          'wasCorrect': wasCorrect,
          'theme': widget.themeName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

   void _navigateToResults() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsPage(
            score: _correctAnswersCount,
            totalQuestions: allQuestions.length,
          ),
        ),
      );
    }
  }

  void _showReportDialog(String questionId, String questionText) {
    final rh = ResponsiveHelper(context);
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(5))),
          title: const Text("Signaler la question"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Un problème avec cette question ? (faute d'orthographe, réponse incorrecte, etc.)",
                style: TextStyle(fontSize: rh.w(3.8)),
              ),
              SizedBox(height: rh.h(2)),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Ajouter un commentaire (optionnel)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(rh.w(3)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final String comment = commentController.text.trim();
                
                // --- ON UTILISE LES PARAMÈTRES REÇUS ---
                await FirebaseFirestore.instance.collection('questionReports').add({
                  'questionId': questionId, // Utilise le paramètre
                  'questionText': questionText, // Utilise le paramètre
                  'comment': comment,
                  'userId': user?.uid ?? 'anonymous',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Merci ! Votre rapport a été envoyé.')),
                  );
                }
              },
              child: const Text("Envoyer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
  final rh = ResponsiveHelper(context);

  return Scaffold(
    body: Stack(
      children: [
        // 1. Le contenu principal de la page
        Column(
          children: [
            SizedBox(height: rh.h(14)), // Espace pour la barre du haut
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: rh.w(5)),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          Text(
                            question,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: rh.w(6), fontWeight: FontWeight.bold),
                          ),
                          const Spacer(flex: 1),
                          Wrap(
                            spacing: rh.w(3),
                            runSpacing: rh.w(3),
                            alignment: WrapAlignment.center,
                            children: propositions.map((prop) {
                              final bool isRemovedByFiftyFifty = _removedAnswers.contains(prop);
                              return SizedBox(
                                width: (rh.screenWidth - rh.w(10) - rh.w(3)) / 2,
                                height: rh.h(8), // Hauteur = 8% de la hauteur
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 500),
                                  opacity: isRemovedByFiftyFifty ? 0.0 : 1.0,
                                  child: ElevatedButton(
                                    onPressed: isRemovedByFiftyFifty ? null : () => _handleAnswer(prop),
                                    style: _getButtonStyle(prop).copyWith(
                                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: Stack(
                                      children: [
                                        AnimatedPositioned(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          left: rh.w(3),
                                          right: _audiencePollUsed ? rh.w(12) : rh.w(3),
                                          top: 0, bottom: 0,
                                          child: Center(
                                            child: Text(
                                              prop,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: rh.w(3.5)),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: rh.w(3),
                                          top: 0, bottom: 0,
                                          child: Center(
                                            child: AnimatedOpacity(
                                              duration: const Duration(milliseconds: 300),
                                              opacity: _audiencePollUsed ? 1.0 : 0.0,
                                              child: Text(
                                                _answerPercentages[prop] ?? '0%',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const Spacer(flex: 1,),

                          SizedBox(
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                // Élément 1 : Les Jokers
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 100),
                                  // L'opacité est maintenant contrôlée par 'questionAnswered'
                                  opacity: questionAnswered ? 0.0 : 1.0,
                                  child: _buildJokersSection(),
                                ),
                                // Élément 2 : L'Explication
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 100),
                                  // L'opacité est contrôlée par la NOUVELLE variable '_showExplanation'
                                  opacity: _showExplanation ? 1.0 : 0.0,
                                  child: _buildExplanationSection(),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),

                          // --- CORRECTION 1 : LE BOUTON "SUIVANT" STABLE ---
                          // On retire AnimatedOpacity et Visibility
                          // Le bouton est TOUJOURS dans l'arbre des widgets
                          ElevatedButton(
                            // On contrôle l'interactivité avec onPressed
                            onPressed: questionAnswered ? _onNextButtonPressed : null,
                            style: ButtonStyle(
                              minimumSize: WidgetStateProperty.all(Size(double.infinity, rh.h(6))),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              // On gère la couleur de fond et l'élévation en fonction de l'état
                              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Colors.transparent; // Couleur si désactivé
                                }
                                return Colors.blue.shade700; // Couleur si activé
                              }),
                              foregroundColor: WidgetStateProperty.all(Colors.white),
                              elevation: WidgetStateProperty.resolveWith<double>((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return 0; // Élévation si désactivé
                                }
                                return 4; // Élévation si activé
                              }),
                            ),
                            child: AnimatedOpacity(
                              // On anime seulement l'opacité du TEXTE
                              duration: const Duration(milliseconds: 100),
                              opacity: questionAnswered ? 1.0 : 0.0,
                              child: Text(
                                currentQuestionIndex < allQuestions.length - 1 ? 'Suivant' : 'Terminer le quiz',
                                style: TextStyle(fontSize: rh.w(4), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          
                          const Spacer(flex: 4),
                        ],
                      ),
                    ),
              ),
            ],
          ),
          Positioned(
          top: rh.h(1),
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: rh.w(2)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- PARTIE GAUCHE : CROIX ET DRAPEAU (avec Stack) ---
                  SizedBox(
                    // On donne à cette zone la même largeur que la zone de symétrie à droite
                    width: rh.a(48),
                    // On lui donne une hauteur suffisante pour contenir les deux barres
                    height: rh.h(9.5), 
                    child: Stack(
                      // L'alignement par défaut est top-left
                      children: [
                        // La croix pour quitter, alignée avec la première barre
                        Positioned(
                          top: 0, // Alignée en haut
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: _showExitDialog,
                          ),
                        ),
                        // L'icône pour signaler, alignée avec la deuxième barre
                        Positioned(
                          bottom: 0, // Alignée en bas
                          child: IconButton(
                            icon: const Icon(Icons.flag_outlined, color: Colors.black54),
                            onPressed: () {
                              final String questionId = allQuestions[currentQuestionIndex].id;
                              _showReportDialog(questionId, question);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- PARTIE CENTRALE : LES BARRES ---
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuizProgressBar(),
                        SizedBox(height: rh.h(1.5)),
                        _buildScoreRatioBar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildJokersSection() {
    return KeyedSubtree(
      key: const ValueKey('jokers_section'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFiftyFiftyButton(),
          _buildAudiencePollButton(),
        ],
      ),
    );
  }

  Widget _buildExplanationSection() {
    final rh = ResponsiveHelper(context);
    return KeyedSubtree(
      key: const ValueKey('explanation_section'),
      child: IgnorePointer(
        ignoring: !_showExplanation,
        child: Container(
          padding: EdgeInsets.all(rh.w(3)),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: rh.w(4)),
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le quiz ?'),
        content: const Text('Votre progression pour ce quiz ne sera pas sauvegardée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Ferme juste la dialogue
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () {
              // Ferme la dialogue ET la page du quiz
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFiftyFiftyButton() {
    final rh = ResponsiveHelper(context);
    final bool isButtonVisible = !_fiftyFiftyUsed && !_isLoadingCurrency;

    return Visibility(
      visible: isButtonVisible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: ElevatedButton(
        onPressed: isButtonVisible ? (_userJokers > 0 ? _useFiftyFifty : _watchAdForJokers) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _userJokers > 0 ? Colors.blueAccent : Colors.green,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          // Padding proportionnel
          padding: EdgeInsets.symmetric(horizontal: rh.w(4), vertical: rh.w(2)),
          elevation: isButtonVisible ? 4 : 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: _userJokers > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '50/50',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5)), // Police proportionnelle
                  ),
                  SizedBox(width: rh.w(1.5)), // Espace proportionnel
                  Icon(Icons.star_half, size: rh.w(4.5)), // Icône proportionnelle
                  SizedBox(width: rh.w(1.5)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: rh.w(2), vertical: rh.w(0.5)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(rh.w(3)), // Bords arrondis proportionnels
                    ),
                    child: Text(
                      _userJokers.toString(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '50/50',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5), color: Colors.white),
                  ),
                  SizedBox(width: rh.w(1.5)),
                  Icon(Icons.slow_motion_video_rounded, size: rh.w(4.5)),
                  SizedBox(width: rh.w(1.5)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: rh.w(2), vertical: rh.w(0.5)),
                    decoration: BoxDecoration(
                      color: Colors.green.shade300,
                      borderRadius: BorderRadius.circular(rh.w(3)),
                    ),
                    child: Text(
                      '+3',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAudiencePollButton() {
    final rh = ResponsiveHelper(context);
    final bool isButtonVisible = !_audiencePollUsed && !_isLoadingCurrency;

    return Visibility(
      visible: isButtonVisible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: ElevatedButton(
        onPressed: isButtonVisible ? (_userIndices > 0 ? _useAudiencePoll : _watchAdForIndices) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _userIndices > 0 ? Colors.purpleAccent.shade100 : Colors.green,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: rh.w(4), vertical: rh.w(2)),
          elevation: isButtonVisible ? 4 : 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: _userIndices > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Public',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
                  ),
                  SizedBox(width: rh.w(1.5)),
                  Icon(Icons.poll_outlined, size: rh.w(4.5)),
                  SizedBox(width: rh.w(1.5)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: rh.w(2), vertical: rh.w(0.5)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(rh.w(3)),
                    ),
                    child: Text(
                      _userIndices.toString(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Public',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
                  ),
                  SizedBox(width: rh.w(1.5)),
                  Icon(Icons.slow_motion_video_rounded, size: rh.w(4.5)),
                  SizedBox(width: rh.w(1.5)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: rh.w(2), vertical: rh.w(0.5)),
                    decoration: BoxDecoration(
                      color: Colors.green.shade300,
                      borderRadius: BorderRadius.circular(rh.w(3)),
                    ),
                    child: Text(
                      '+2', // Note : J'ai gardé +2 comme dans votre code, mais vous vouliez peut-être +1 pour les indices
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuizProgressBar() {
    final rh = ResponsiveHelper(context);
    final targetValue = (currentQuestionIndex + 1) / allQuestions.length;

    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: (currentQuestionIndex) / allQuestions.length,
              end: targetValue,
            ),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: rh.h(0.8), // Hauteur proportionnelle
              borderRadius: BorderRadius.circular(rh.w(1)), // Bords proportionnels
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
        SizedBox(width: rh.w(2.5)),
        SizedBox(
          width: rh.w(14), // Largeur proportionnelle
          child: Text(
            '${currentQuestionIndex + 1} / ${allQuestions.length}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: rh.w(3.5), // Police proportionnelle
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRatioBar() {
    final rh = ResponsiveHelper(context);
    final totalAnswered = _correctAnswersCount + _incorrectAnswersCount;
    final double successPercentage = totalAnswered == 0 ? 0.0 : (_correctAnswersCount / totalAnswered) * 100;

    return AnimatedOpacity(
      opacity: totalAnswered > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: rh.h(0.8), // Hauteur proportionnelle
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(rh.w(1)), // Bords proportionnels
                color: Colors.grey.shade300,
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                tween: Tween<double>(end: _correctAnswersCount / (totalAnswered == 0 ? 1 : totalAnswered)),
                builder: (context, greenPercentage, child) {
                  final greenFlex = (greenPercentage * 100).toInt();
                  final redFlex = 100 - greenFlex;
                  return Row(
                    children: [
                      Expanded(flex: greenFlex, child: Container(color: Colors.green)),
                      Expanded(flex: redFlex, child: Container(color: Colors.red)),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(width: rh.w(2.5)),
          SizedBox(
            width: rh.w(14), // Largeur proportionnelle
            child: Text(
              '${successPercentage.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontFamily: 'monospace',
                fontSize: rh.w(3.5), // Police proportionnelle
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _getButtonStyle(String prop) {
    Color buttonColor;
    final bool isRemovedByFiftyFifty = _removedAnswers.contains(prop);

    if (isRemovedByFiftyFifty) {
      buttonColor = Colors.white.withOpacity(0.2);
    } 

    else if (questionAnswered) {
      if (prop == bonneReponse) {
        buttonColor = Colors.green.shade300;
      } else if (prop == selectedProposition) {
        buttonColor = Colors.red.shade300;
      } else {
        buttonColor = Colors.grey.shade300;
      }
    } 
    else {
      buttonColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: buttonColor,
      foregroundColor: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}