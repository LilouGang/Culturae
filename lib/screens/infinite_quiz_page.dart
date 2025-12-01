import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/data_manager.dart';
import '../utils/responsive_helper.dart';

class InfiniteQuizPage extends StatefulWidget {
  const InfiniteQuizPage({super.key});
  @override
  State<InfiniteQuizPage> createState() => _InfiniteQuizPageState();
}

class _InfiniteQuizPageState extends State<InfiniteQuizPage> {
  // --- État du jeu ---
  int _score = 0;
  int _currentLevel = 1;
  int _questionsAnsweredInLevel = 0;
  List<DocumentSnapshot> _questionsForCurrentLevel = [];
  late DocumentSnapshot _currentQuestion;

  // --- État de l'UI ---
  String questionText = "Chargement...";
  List<String> propositions = [];
  late String bonneReponse;
  String? selectedProposition;
  bool questionAnswered = false;
  bool _isLoading = true;
  double _currentProgress = 0.0; // Pour l'animation de la barre

  // --- État des Jokers ---
  bool _fiftyFiftyAvailable = true; // Disponible pour la partie
  bool _audiencePollAvailable = true; // Disponible pour la partie
  bool _fiftyFiftyUsedThisQuestion = false;
  bool _audiencePollUsed = false;
  List<String> _removedAnswers = [];
  Map<String, String> _answerPercentages = {};
  bool _secondChanceAvailable = true;
  bool _dialogShowExplanation = false;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  void _startLevel() {
    _questionsForCurrentLevel = DataManager.instance.allQuestions
        .where((q) => (q.data() as Map<String, dynamic>)['difficulty'] == _currentLevel)
        .toList();
    _questionsForCurrentLevel.shuffle();
    if (_questionsForCurrentLevel.isEmpty) {
      if (_currentLevel > 10) {
        _endGame(won: true); 
        return;
      }
      _currentLevel++;
      _startLevel();
      return;
    }
    _displayNextQuestionInLevel();
  }

  void _displayNextQuestionInLevel() {
    _currentQuestion = _questionsForCurrentLevel.removeAt(0);
    final data = _currentQuestion.data() as Map<String, dynamic>;
    setState(() {
      questionText = data['question'] ?? '';
      propositions = List<String>.from(data['propositions'] ?? [])..shuffle();
      bonneReponse = data['reponse'] as String? ?? "";
      questionAnswered = false;
      selectedProposition = null;
      _isLoading = false;
      _fiftyFiftyUsedThisQuestion = false;
      _audiencePollUsed = false;
      _removedAnswers = [];
      _answerPercentages = {};
    });
  }

  void _handleAnswer(String selectedAnswer) {
    if (questionAnswered) return;
    final isCorrect = selectedAnswer == bonneReponse;
    
    setState(() {
      selectedProposition = selectedAnswer;
      questionAnswered = true;
    });

    if (isCorrect) {
      // --- 2. SI LA RÉPONSE EST CORRECTE ---
      // On incrémente les scores en arrière-plan
      _score++;
      _questionsAnsweredInLevel++;

      // On attend une seconde AVANT de charger la question suivante
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        
        // La logique de passage à la question/niveau suivant est inchangée
        if (_questionsAnsweredInLevel >= 10 || _questionsForCurrentLevel.isEmpty) {
          setState(() {
            _currentLevel++;
            _questionsAnsweredInLevel = 0;
            _currentProgress = 0.0;
          });
          _startLevel();
        } else {
          _displayNextQuestionInLevel();
        }
      });
    } else {
      // --- 3. SI LA RÉPONSE EST FAUSSE ---
      // On attend aussi un peu pour que l'utilisateur voie le bouton rouge
      Future.delayed(const Duration(milliseconds: 1500), () {
        _endGame(won: false);
      });
    }
  }

  void _restartGame() {
    setState(() {
      // On réinitialise toutes les variables d'état du jeu
      _score = 0;
      _currentLevel = 1;
      _questionsAnsweredInLevel = 0;
      _currentProgress = 0.0;
      _fiftyFiftyAvailable = true;
      _audiencePollAvailable = true;
      _secondChanceAvailable = true;
      _isLoading = true; // On affiche le spinner pendant la préparation
    });
    // On relance la logique de démarrage du premier niveau
    _startLevel();
  }

  void _endGame({bool won = false}) {
    final rh = ResponsiveHelper(context);

    // 1. On réinitialise l'état de l'explication à chaque fois qu'on ouvre la dialogue
    _dialogShowExplanation = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // On ne déclare plus 'showExplanation' ici.

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(5))),
                title: Center(
                  child: Column(
                    children: [
                      Text(won ? "Félicitations !" : "Partie Terminée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(6))),
                      SizedBox(height: rh.h(1)),
                      Text("Votre score : $_score", style: TextStyle(fontSize: rh.w(5), color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                contentPadding: EdgeInsets.fromLTRB(rh.w(6), rh.h(2.5), rh.w(6), rh.h(1)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_secondChanceAvailable && !won)
                        Padding(
                          padding: EdgeInsets.only(bottom: rh.h(1.5)),
                          child: ElevatedButton.icon(
                            onPressed: _getSecondChance,
                            icon: Icon(Icons.slow_motion_video_rounded, color: Colors.brown.shade800),
                            label: Text("Deuxième Chance", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade800)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade400, padding: EdgeInsets.symmetric(vertical: rh.h(1.5)), shape: const StadiumBorder()),
                          ),
                        ),
                      
                      ElevatedButton(
                        // 2. Le bouton modifie maintenant la variable d'état de la classe
                        onPressed: () => setStateDialog(() => _dialogShowExplanation = !_dialogShowExplanation),
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: rh.h(1.5)), shape: const StadiumBorder()),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Voir l'explication"),
                            const SizedBox(width: 8),
                            // 3. L'icône lit la variable d'état de la classe
                            Icon(_dialogShowExplanation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                          ],
                        ),
                      ),
                      
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        // 4. L'AnimatedSize lit aussi la variable d'état de la classe
                        child: _dialogShowExplanation
                            ? Padding(
                                padding: EdgeInsets.only(top: rh.h(1.5)),
                                child: Container(
                                  padding: EdgeInsets.all(rh.w(4)),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(rh.w(3))),
                                  child: Text(
                                    (_currentQuestion.data() as Map<String, dynamic>)['explication'] ?? "Pas d'explication.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: rh.w(3.8)),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: EdgeInsets.fromLTRB(rh.w(2), 0, rh.w(2), rh.h(1.5)),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text("Retour"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _restartGame();
                        },
                        child: const Text("Rejouer"),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _getSecondChance() {
      if (mounted) {
        // 1. On ferme la dialogue de fin de partie
        Navigator.of(context).pop();
        
        // 2. On désactive la possibilité d'avoir une autre seconde chance
        setState(() {
          _secondChanceAvailable = false;
        });
        
        // 3. On recharge la prochaine question
        _displayNextQuestionInLevel();
      }
  }

  void _useFiftyFifty() {
    if (!_fiftyFiftyAvailable) return;
      setState(() {
        _fiftyFiftyAvailable = false; // Le joker est utilisé pour toute la partie
        _fiftyFiftyUsedThisQuestion = true;
        final wrongAnswers = List<String>.from(propositions)..remove(bonneReponse);
        wrongAnswers.shuffle();
        _removedAnswers = wrongAnswers.take(2).toList();
      });
  }

  Future<void> _useAudiencePoll() async {
    if (!_audiencePollAvailable) return;

      setState(() {
        _audiencePollAvailable = false; // Le joker est utilisé pour toute la partie
        _audiencePollUsed = true; // Pour griser le bouton sur cette question
      });

      try {
        final questionId = _currentQuestion.id;
        final questionDoc = await FirebaseFirestore.instance.collection('Questions').doc(questionId).get();
        if (questionDoc.exists && mounted) {
          final stats = Map<String, int>.from(questionDoc.data()?['answerStats'] ?? {});
          final totalVotes = stats.values.fold(0, (sum, count) => sum + count);
          final Map<String, String> percentages = {};

          for (var entry in stats.entries) {
            final percentage = totalVotes > 0 ? (entry.value / totalVotes * 100) : 0;
            percentages[entry.key] = '${percentage.toStringAsFixed(0)}%';
          }
          
          // 3. On met à jour l'interface avec les pourcentages
          setState(() {
            _answerPercentages = percentages;
          });
        }
      } catch (e) {
        print("Erreur : $e");
        if (mounted) setState(() => _audiencePollAvailable = true); // Redonne le joker en cas d'erreur
      }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le Mode Infini ?'),
        content: const Text('Votre score actuel sera perdu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Rester')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  ButtonStyle _getButtonStyle(String prop) {
    Color? buttonColor;
    if (questionAnswered) {
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
    
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(buttonColor),
      foregroundColor: WidgetStateProperty.all(Colors.black),
      elevation: WidgetStateProperty.all(2),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildLevelProgressBar() {
    final rh = ResponsiveHelper(context);
    // La valeur cible de la barre
    final double targetProgress = min(_questionsAnsweredInLevel, 10) / 10.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Niveau : $_currentLevel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
              ),
              SizedBox(height: rh.h(0.5)),
              // On utilise TweenAnimationBuilder pour l'animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                tween: Tween<double>(begin: _currentProgress, end: targetProgress),
                builder: (context, value, child) {
                  // On met à jour la progression actuelle pour la prochaine animation
                  _currentProgress = value;
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: rh.h(1),
                    borderRadius: BorderRadius.circular(rh.w(1)),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar() {
    final rh = ResponsiveHelper(context);
    return Row(
      // --- ON CENTRE LE SCORE ---
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, color: Colors.amber, size: rh.w(5)),
        SizedBox(width: rh.w(1)),
        Text(
          'Score : $_score',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5), color: Colors.grey.shade700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);
    return Scaffold(
      body: Stack(
        children: [
          // 1. Le contenu principal (inchangé)
          Column(
            children: [
              SizedBox(height: rh.h(14)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: rh.w(5)),
                        child: Column(
                          children: [
                            const Spacer(flex: 4),
                            Text(
                              questionText,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: rh.w(6), fontWeight: FontWeight.bold),
                            ),
                            const Spacer(flex: 1),
                            // --- ON MET À JOUR LE STYLE DES BOUTONS ICI ---
                            Wrap(
                              spacing: rh.w(3),
                              runSpacing: rh.w(3),
                              alignment: WrapAlignment.center,
                              children: propositions.map((prop) {
                                final bool isRemoved = _removedAnswers.contains(prop);
                                return SizedBox(
                                  width: (rh.screenWidth - rh.w(10) - rh.w(3)) / 2,
                                  height: rh.h(8),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: isRemoved ? 0.0 : 1.0,
                                    child: ElevatedButton(
                                      onPressed: isRemoved ? null : () => _handleAnswer(prop),
                                      // --- ANIMATION DE COULEUR IMPLICITE ---
                                      // On change le style directement
                                      style: _getButtonStyle(prop),
                                      child: Stack(
                                        children: [
                                          // On utilise AnimatedPositioned pour la cohérence, même s'il n'y a pas d'animation ici
                                          AnimatedPositioned(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                            left: rh.w(1),
                                            right: _audiencePollUsed ? rh.w(8) : rh.w(1),
                                            top: 0, bottom: 0,
                                            child: Center(
                                              child: Text(
                                                prop,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: rh.w(3.5)),
                                              ),
                                            ),
                                          ),
                                          // On garde la structure pour le joker "Public", même si elle est désactivée
                                          Positioned(
                                            right: rh.w(1),
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
                            const Spacer(flex: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildFiftyFiftyButton(),
                                _buildAudiencePollButton(),
                              ],
                            ),
                            const Spacer(flex: 7),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            top: rh.h(3),
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: rh.w(2)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Le bouton de retour à gauche
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: _showExitDialog,
                    ),
                    // Les barres et textes au milieu
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLevelProgressBar(), // Affiche "Niveau Suivant"
                          SizedBox(height: rh.h(0.5)),
                          _buildScoreBar(), // Affiche le score
                        ],
                      ),
                    ),
                    // Espace vide à droite pour la symétrie
                    SizedBox(width: rh.a(48)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiftyFiftyButton() {
    final rh = ResponsiveHelper(context);
    final bool isEnabled = _fiftyFiftyAvailable && !_fiftyFiftyUsedThisQuestion;

    // On détermine la couleur de fond cible
    final targetColor = _fiftyFiftyAvailable ? Colors.blueAccent : Colors.grey.shade300;
    // On détermine la couleur du contenu cible
    final foregroundColor = _fiftyFiftyAvailable ? Colors.white : Colors.grey.shade500;

    return GestureDetector(
      // On n'appelle la fonction que si le bouton est activé
      onTap: isEnabled ? _useFiftyFifty : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Vitesse de l'animation de couleur
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: rh.w(4), vertical: rh.w(2)),
        decoration: BoxDecoration(
          color: targetColor, // La couleur est maintenant animée
          borderRadius: BorderRadius.circular(rh.w(10)), // Forme de pastille (StadiumBorder)
          boxShadow: isEnabled ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [], // On anime aussi l'ombre
        ),
        child: AnimatedTheme(
          duration: const Duration(milliseconds: 200),
          data: ThemeData(
            // On change le thème des icônes pour animer leur couleur
            iconTheme: IconThemeData(color: foregroundColor, size: rh.w(4.8)),
          ),
          child: _fiftyFiftyAvailable
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('50/50', style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5), color: foregroundColor)),
                    SizedBox(width: rh.w(1.5)),
                    const Icon(Icons.slow_motion_video_rounded),
                    SizedBox(width: rh.w(1.5)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: rh.w(2), vertical: rh.w(0.5)),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade100,
                        borderRadius: BorderRadius.circular(rh.w(3)),
                      ),
                      child: Text('+1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: rh.w(3.2))),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('50/50', style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5), color: foregroundColor)),
                    SizedBox(width: rh.w(1.5)),
                    const Icon(Icons.star_half),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAudiencePollButton() {
    final rh = ResponsiveHelper(context);
    final bool isEnabled = _audiencePollAvailable && !_audiencePollUsed;

    final targetColor = _audiencePollAvailable ? Colors.purpleAccent.shade100 : Colors.grey.shade300;
    final foregroundColor = _audiencePollAvailable ? Colors.white : Colors.grey.shade500;

    return GestureDetector(
      onTap: isEnabled ? _useAudiencePoll : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: rh.w(4), vertical: rh.w(2)),
        decoration: BoxDecoration(
          color: targetColor,
          borderRadius: BorderRadius.circular(rh.w(10)),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: AnimatedTheme(
          duration: const Duration(milliseconds: 200),
          data: ThemeData(iconTheme: IconThemeData(color: foregroundColor, size: rh.w(4.8))),
          child: _audiencePollAvailable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Public', style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5), color: foregroundColor)),
                  SizedBox(width: rh.w(1.5)),
                  Icon(Icons.slow_motion_video_rounded, size: rh.w(4.8)),
                  SizedBox(width: rh.w(1.5)),
                  // --- ON RÉINTÈGRE LE BADGE "+1" ---
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: rh.w(2), vertical: rh.w(0.5)),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 241, 171, 255),
                      borderRadius: BorderRadius.circular(rh.w(3)),
                    ),
                    child: Text('+1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: rh.w(3.2))),
                  ),
                ],
              )
            // CAS 2 : Le joker a été consommé
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Public', style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(3.5), color: foregroundColor)),
                  SizedBox(width: rh.w(1.5)),
                  Icon(Icons.poll_outlined, size: rh.w(4.8)),
                ],
              ),
        ),
      ),
    );
  }
}

class EndGameDialog extends StatefulWidget {
  final int score;
  final bool won;
  final bool secondChanceAvailable;
  final VoidCallback onSecondChance;
  final String explanation;
  final VoidCallback? onRestart;

  const EndGameDialog({
    super.key,
    required this.score,
    required this.won,
    required this.secondChanceAvailable,
    required this.onSecondChance,
    required this.explanation,
    this.onRestart,
  });

  @override
  State<EndGameDialog> createState() => _EndGameDialogState();
}

class _EndGameDialogState extends State<EndGameDialog> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(5))),
        
        // --- GESTION DU TITRE ---
        title: Center(
          child: Column(
            children: [
              Text(
                widget.won ? "Félicitations !" : "Perdu...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(6)),
              ),
              SizedBox(height: rh.h(1)),
              Text(
                "Score : ${widget.score}",
                style: TextStyle(fontSize: rh.w(5), color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        
        // --- GESTION DU CONTENU PRINCIPAL ---
        // On supprime le padding par défaut de la dialogue
        contentPadding: EdgeInsets.zero,
        
        content: SingleChildScrollView(
          // On applique notre propre padding contrôlé
          padding: EdgeInsets.only(
            left: rh.w(6),
            right: rh.w(6),
            top: rh.h(2.5),
            bottom: rh.h(1), // Petit padding en bas du contenu
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bouton "Deuxième Chance"
              if (widget.secondChanceAvailable && !widget.won)
                ElevatedButton.icon(
                  onPressed: widget.onSecondChance,
                  icon: Icon(Icons.slow_motion_video_rounded, color: Colors.brown.shade800),
                  label: Text("Deuxième Chance", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade400,
                    padding: EdgeInsets.symmetric(vertical: rh.h(1.5)),
                    shape: const StadiumBorder(),
                  ),
                ),
              
              if (widget.secondChanceAvailable && !widget.won) SizedBox(height: rh.h(1.5)),

              // Bouton "Explication"
              ElevatedButton(
                onPressed: () => setState(() => _showExplanation = !_showExplanation),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: rh.h(1.5)),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Voir l'explication"),
                    const SizedBox(width: 8),
                    Icon(_showExplanation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  ],
                ),
              ),
              
              // Conteneur de l'explication qui se déplie
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showExplanation
                    ? Padding(
                        padding: EdgeInsets.only(top: rh.h(1.5)),
                        child: Container(
                          padding: EdgeInsets.all(rh.w(4)),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(rh.w(3)),
                          ),
                          child: Text(
                            widget.explanation,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: rh.w(3.8)),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        
        // --- GESTION DES ACTIONS (BOUTON DU BAS) ---
        actionsAlignment: MainAxisAlignment.center,
        // On supprime aussi le padding des actions pour un look compact
        actionsPadding: EdgeInsets.only(
          bottom: rh.h(1.5), // Garde un petit espace en bas
          top: 0, // Supprime l'espace en haut
        ),
        
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Retour aux modes de jeu"),
          ),
        ],
      ),
    );
  }
}