import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/data_manager.dart';
import 'views/quiz_selection_views.dart';
import 'views/quiz_game_view.dart';

class QuizPage extends StatefulWidget {
  final ThemeInfo? initialTheme;
  const QuizPage({super.key, this.initialTheme});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // --- ÉTATS ---
  late Future<void> _loadDataFuture;
  
  // Navigation State
  ThemeInfo? _selectedTheme;
  SubThemeInfo? _selectedSubTheme;
  String? _diffLabel;
  int _minLvl = 0; 
  int _maxLvl = 0;
  
  // Game State
  Map<String, dynamic>? _currentQuestion;
  List<Map<String, dynamic>> _allQuestions = [];
  bool _isLoadingGame = false;
  
  // Answer State
  bool _hasAnswered = false;
  int? _selectedAnswerIndex;
  int? _correctAnswerIndex;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = DataManager.instance.loadAllData();
    if (widget.initialTheme != null) {
      _selectedTheme = widget.initialTheme;
    }
  }

  // --- LOGIQUE DE NAVIGATION ---

  void _onSelectTheme(ThemeInfo theme) {
    setState(() => _selectedTheme = theme);
  }

  Future<void> _onSelectSubTheme(SubThemeInfo subTheme) async {
    setState(() {
      _selectedSubTheme = subTheme;
      // On ne charge pas encore les questions, on attend la difficulté
    });
  }

  Future<void> _onSelectDifficulty(String label, int min, int max) async {
    setState(() {
      _diffLabel = label;
      _minLvl = min;
      _maxLvl = max;
      _isLoadingGame = true;
    });

    // Chargement des questions
    final qs = await DataManager.instance.getQuestions(_selectedTheme!.name, _selectedSubTheme!.name);
    
    // Filtrage par difficulté
    final filtered = qs.where((q) {
      int lvl = int.tryParse(q['difficulty'].toString()) ?? 0;
      return lvl >= _minLvl && lvl <= _maxLvl;
    }).toList();

    if (filtered.isEmpty) {
      if (mounted) {
        setState(() => _isLoadingGame = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune question trouvée pour ce niveau !"), backgroundColor: Colors.orange));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _allQuestions = filtered;
        _isLoadingGame = false;
        _nextQuestion(); // Lance la première question
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion = _allQuestions[Random().nextInt(_allQuestions.length)];
      _hasAnswered = false;
      _selectedAnswerIndex = null;
      _correctAnswerIndex = null;
    });
  }

  void _onAnswer(int index, String text, List<String> props) {
    if (_hasAnswered) return;

    final correctText = _currentQuestion!['reponse']?.toString() ?? "";
    int correctIdx = props.indexWhere((p) => p.trim() == correctText.trim());
    if (correctIdx == -1) correctIdx = 0; // Fallback

    // Envoi BDD
    DataManager.instance.addAnswer(
      index == correctIdx, 
      _currentQuestion!['id'] ?? "", 
      text, 
      _selectedTheme!.name
    );

    // Mise à jour locale pour affichage immédiat stats
    Map<String, dynamic> newStats = Map.from(_currentQuestion!['answerStats'] ?? {});
    newStats[text] = (int.tryParse(newStats[text].toString()) ?? 0) + 1;
    
    setState(() {
      _hasAnswered = true;
      _selectedAnswerIndex = index;
      _correctAnswerIndex = correctIdx;
      _currentQuestion!['answerStats'] = newStats;
      _currentQuestion!['timesAnswered'] = (_currentQuestion!['timesAnswered'] ?? 0) + 1;
      if (index == correctIdx) {
        _currentQuestion!['timesCorrect'] = (_currentQuestion!['timesCorrect'] ?? 0) + 1;
      }
    });
  }

  void _onBack() {
    setState(() {
      if (_currentQuestion != null) {
        _currentQuestion = null;
        _allQuestions = [];
      } else if (_selectedSubTheme != null) {
        _selectedSubTheme = null;
      } else if (_selectedTheme != null) {
        _selectedTheme = null;
      }
    });
  }

  void _onQuitGame() {
    setState(() {
      _currentQuestion = null;
      _allQuestions = [];
      _selectedSubTheme = null;
      _selectedTheme = null;
    });
  }

  // --- RENDU ---

  @override
  Widget build(BuildContext context) {
    // Utilisation d'un Stack pour superposer le fond dessiné et le contenu
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Couleur de base très claire
      body: Stack(
        children: [
          // --- COUCHE 1 : LE PATTERN DESSINÉ ---
          // Dessine des petits motifs géométriques subtils en arrière-plan
          Positioned.fill(
            child: CustomPaint(
              painter: _QuizPatternPainter(),
            ),
          ),

          // --- COUCHE 2 : LE CONTENU (FutureBuilder) ---
          FutureBuilder(
            future: _loadDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 1. ÉCRAN DE JEU (Active Game)
              if (_currentQuestion != null) {
            return QuizGameView(
                  key: ValueKey(_currentQuestion!['id']),
                  questionData: _currentQuestion!,
                  difficultyLabel: _diffLabel!,
                  hasAnswered: _hasAnswered,
                  selectedAnswerIndex: _selectedAnswerIndex,
                  correctAnswerIndex: _correctAnswerIndex,
                  onAnswer: _onAnswer,
                  onNext: _nextQuestion,
                  onQuit: _onQuitGame,
                );
              }

              // 2. ÉCRAN DE CHARGEMENT JEU
              if (_isLoadingGame) {
                return const Center(child: CircularProgressIndicator());
              }

              // 3. ÉCRANS DE SÉLECTION
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    // On garde les paddings réduits comme demandé précédemment
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _buildSelectionView(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionView() {
    // A. Choix Difficulté
    if (_selectedSubTheme != null) {
      return DifficultySelectionView(
        theme: _selectedTheme!,
        subTheme: _selectedSubTheme!,
        onSelect: _onSelectDifficulty,
        onBack: _onBack,
      );
    }
    // B. Choix Sous-Thème
    if (_selectedTheme != null) {
      return SubThemeSelectionView(
        theme: _selectedTheme!,
        subThemes: DataManager.instance.getSubThemesFor(_selectedTheme!.name),
        onSelect: _onSelectSubTheme,
        onBack: _onBack,
      );
    }
    // C. Choix Thème (Racine)
    return ThemeSelectionView(
      themes: DataManager.instance.themes,
      onSelect: _onSelectTheme,
    );
  }
}

class _QuizPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paintStroke = Paint()
      ..color = Colors.blueGrey.withOpacity(0.3) // Gris très doux
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Paint paintFill = Paint()
      ..color = Colors.blueGrey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    const double gridSize = 50.0; // Grille un peu plus serrée

    // Calcul du nombre de colonnes et lignes
    final int cols = (size.width / gridSize).ceil();
    final int rows = (size.height / gridSize).ceil();

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        // Coordonnées du centre de la cellule
        final double x = i * gridSize;
        final double y = j * gridSize;
        final Offset center = Offset(x + gridSize / 2, y + gridSize / 2);

        // FORMULE AMÉLIORÉE POUR LA VARIÉTÉ
        // On utilise XOR (^) et des nombres premiers (13, 7) pour casser la répétition
        final int hash = ((i * 13) ^ (j * 7) + (i * j)).abs();
        
        // On utilise un modulo 7 pour avoir plus de cas (dont du vide)
        final int shapeType = hash % 14; 

        switch (shapeType) {
          case 0: 
          case 1: 
            // CROIX (+) - Fréquent (2 chances sur 7)
            const double s = 4.0;
            canvas.drawLine(center.translate(-s, 0), center.translate(s, 0), paintStroke);
            canvas.drawLine(center.translate(0, -s), center.translate(0, s), paintStroke);
            break;
            
          case 2:
          case 3:
            // POINT (.) - Fréquent (2 chances sur 7)
            canvas.drawCircle(center, 1.5, paintFill);
            break;
            
          case 4:
            // CERCLE VIDE (o) - Rare
            canvas.drawCircle(center, 3.0, paintStroke);
            break;
            
          case 5:
            // TRAIT DIAGONAL (/) - Rare
            const double s = 3.0;
            canvas.drawLine(center.translate(-s, s), center.translate(s, -s), paintStroke);
            break;
            
          case 6:
            // VIDE - Pour laisser respirer le design
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}