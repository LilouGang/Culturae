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
  List<Map<String, dynamic>> _currentSubThemeQuestionsForStats = [];
  
  ThemeInfo? _selectedTheme;
  SubThemeInfo? _selectedSubTheme;
  String? _diffLabel;
  int _minLvl = 0; 
  int _maxLvl = 0;
  
  // Game State
  List<Map<String, dynamic>> _gameQuestions = []; 
  int _currentQuestionIndex = 0;
  Map<String, dynamic>? _currentQuestionData;
  bool _isGameOver = false;
  int _score = 0;
  bool _isLoadingGame = false;
  
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

  void _onSelectTheme(ThemeInfo theme) {
    setState(() => _selectedTheme = theme);
  }

  Future<void> _onSelectSubTheme(SubThemeInfo subTheme) async {
    setState(() {
      _selectedSubTheme = subTheme;
      _isLoadingGame = true; 
    });
    final qs = await DataManager.instance.getQuestions(_selectedTheme!.name, subTheme.name);
    if (mounted) {
      setState(() {
        _currentSubThemeQuestionsForStats = qs;
        _isLoadingGame = false;
      });
    }
  }

  double _calculatePackProgress(int minDiff, int maxDiff, int packIndex) {
    if (_currentSubThemeQuestionsForStats.isEmpty) return 0.0;
    final questionsOfLevel = _currentSubThemeQuestionsForStats.where((q) {
      int lvl = int.tryParse(q['difficulty'].toString()) ?? 0;
      return lvl >= minDiff && lvl <= maxDiff;
    }).toList();
    questionsOfLevel.sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
    int startIndex = (packIndex - 1) * 10;
    int endIndex = startIndex + 10;
    if (startIndex >= questionsOfLevel.length) return 0.0;
    if (endIndex > questionsOfLevel.length) endIndex = questionsOfLevel.length;
    final packQuestions = questionsOfLevel.sublist(startIndex, endIndex);
    if (packQuestions.isEmpty) return 0.0;
    final userIds = DataManager.instance.currentUser.answeredQuestions;
    int validatedCount = 0;
    for (var q in packQuestions) {
      if (userIds.contains(q['id'])) validatedCount++;
    }
    return validatedCount / packQuestions.length; 
  }

  Future<void> _onSelectDifficulty(String label, int min, int max, int packIndex) async {
    setState(() {
      _diffLabel = "$label - Pack $packIndex";
      _minLvl = min;
      _maxLvl = max;
      _isLoadingGame = true;
    });
    final questionsOfLevel = _currentSubThemeQuestionsForStats.where((q) {
      int lvl = int.tryParse(q['difficulty'].toString()) ?? 0;
      return lvl >= _minLvl && lvl <= _maxLvl;
    }).toList();
    questionsOfLevel.sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
    int startIndex = (packIndex - 1) * 10;
    int endIndex = startIndex + 10;
    if (startIndex >= questionsOfLevel.length) {
       setState(() => _isLoadingGame = false);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ce pack est vide !"), backgroundColor: Colors.orange));
       return;
    }
    if (endIndex > questionsOfLevel.length) endIndex = questionsOfLevel.length;
    List<Map<String, dynamic>> selectedPack = questionsOfLevel.sublist(startIndex, endIndex);
    selectedPack.shuffle();
    if (mounted) {
      setState(() {
        _gameQuestions = selectedPack;
        _currentQuestionIndex = 0;
        _score = 0;
        _isGameOver = false;
        if (_gameQuestions.isNotEmpty) _currentQuestionData = _gameQuestions[0];
        _hasAnswered = false;
        _selectedAnswerIndex = null;
        _correctAnswerIndex = null;
        _isLoadingGame = false;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _gameQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentQuestionData = _gameQuestions[_currentQuestionIndex];
        _hasAnswered = false;
        _selectedAnswerIndex = null;
        _correctAnswerIndex = null;
      });
    } else {
      setState(() => _isGameOver = true);
    }
  }

  void _onAnswer(int index, String text, List<String> props) {
    if (_hasAnswered) return;
    final correctText = _currentQuestionData!['reponse']?.toString() ?? "";
    int correctIdx = props.indexWhere((p) => p.trim() == correctText.trim());
    if (correctIdx == -1) correctIdx = 0; 
    bool isCorrect = (index == correctIdx);

    // MODIFICATION ICI : On passe le sous-thème pour mettre à jour le cache
    DataManager.instance.addAnswer(
      isCorrect, 
      _currentQuestionData!['id'] ?? "", 
      text, 
      _selectedTheme!.name,
      _selectedSubTheme?.name // <--- Sous-thème passé ici
    );

    Map<String, dynamic> newStats = Map.from(_currentQuestionData!['answerStats'] ?? {});
    newStats[text] = (int.tryParse(newStats[text].toString()) ?? 0) + 1;
    setState(() {
      _hasAnswered = true;
      _selectedAnswerIndex = index;
      _correctAnswerIndex = correctIdx;
      if (isCorrect) _score++;
      _currentQuestionData!['answerStats'] = newStats;
      _currentQuestionData!['timesAnswered'] = (_currentQuestionData!['timesAnswered'] ?? 0) + 1;
      if (isCorrect) {
        _currentQuestionData!['timesCorrect'] = (_currentQuestionData!['timesCorrect'] ?? 0) + 1;
      }
    });
  }

  void _onBack() {
    setState(() {
      if (_currentQuestionData != null || _isGameOver) {
        _currentQuestionData = null;
        _gameQuestions = [];
        _isGameOver = false;
      } else if (_selectedSubTheme != null) {
        _selectedSubTheme = null;
      } else if (_selectedTheme != null) {
        _selectedTheme = null;
      }
    });
  }

  void _onQuitGame() {
    setState(() {
      _currentQuestionData = null;
      _gameQuestions = [];
      _isGameOver = false;
    });
  }

  // --- CALCULS DE PROGRESSION GLOBALE (Utilisent maintenant le cache scores) ---
  
  Map<String, double> _calculateThemeProgressMap() {
    final user = DataManager.instance.currentUser;
    Map<String, double> progressMap = {};
    
    // On utilise la map scores qui est maintenant tenue à jour localement
    DataManager.instance.themes.forEach((theme) {
      int score = user.scores[theme.name] ?? 0;
      int total = DataManager.instance.countTotalQuestionsForTheme(theme.name);
      if (total == 0) total = 1;
      progressMap[theme.name] = (score / total).clamp(0.0, 1.0);
    });
    
    return progressMap;
  }

  Map<String, double> _calculateSubThemeProgressMap() {
    final user = DataManager.instance.currentUser;
    Map<String, double> progressMap = {};
    
    if (_selectedTheme != null) {
      DataManager.instance.getSubThemesFor(_selectedTheme!.name).forEach((st) {
        int score = user.scores[st.name] ?? 0;
        int total = DataManager.instance.countTotalQuestionsForSubTheme(_selectedTheme!.name, st.name);
        if (total == 0) total = 1;
        progressMap[st.name] = (score / total).clamp(0.0, 1.0);
      });
    }
    
    return progressMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _QuizPatternPainter())),
          FutureBuilder(
            future: _loadDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_currentQuestionData != null || _isGameOver) {
                return QuizGameView(
                  key: _isGameOver ? const ValueKey('GameOver') : ValueKey(_currentQuestionData!['id']),
                  questionData: _isGameOver ? null : _currentQuestionData,
                  difficultyLabel: _diffLabel ?? "",
                  hasAnswered: _hasAnswered,
                  selectedAnswerIndex: _selectedAnswerIndex,
                  correctAnswerIndex: _correctAnswerIndex,
                  onAnswer: _onAnswer,
                  onNext: _nextQuestion,
                  onQuit: _onQuitGame,
                  isGameOver: _isGameOver,
                  score: _score,
                  totalQuestions: _gameQuestions.length,
                  questionsHistory: _gameQuestions,
                );
              }
              if (_isLoadingGame) {
                return const Center(child: CircularProgressIndicator());
              }

              final progressMap = _calculateThemeProgressMap();
              final subThemeProgressMap = _calculateSubThemeProgressMap();

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000), 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          child: _buildSelectionView(progressMap, subThemeProgressMap),
                        ),
                      ),
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

  Widget _buildSelectionView(Map<String, double> progressMap, Map<String, double> subThemeProgressMap) {
    if (_selectedSubTheme != null) {
      return DifficultySelectionView(
        theme: _selectedTheme!,
        subTheme: _selectedSubTheme!,
        progressCalculator: _calculatePackProgress, 
        onSelect: (label, min, max, packNum) => _onSelectDifficulty(label, min, max, packNum),
        onBack: _onBack,
      );
    }
    if (_selectedTheme != null) {
      return SubThemeSelectionView(
        theme: _selectedTheme!,
        subThemes: DataManager.instance.getSubThemesFor(_selectedTheme!.name),
        progressMap: subThemeProgressMap,
        onSelect: _onSelectSubTheme,
        onBack: _onBack,
      );
    }
    return ThemeSelectionView(
      themes: DataManager.instance.themes,
      progressMap: progressMap,
      onSelect: _onSelectTheme,
    );
  }
}

class _QuizPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paintStroke = Paint()..color = Colors.blueGrey.withOpacity(0.2)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final Paint paintFill = Paint()..color = Colors.blueGrey.withOpacity(0.2)..style = PaintingStyle.fill;
    const double gridSize = 50.0;
    final int cols = (size.width / gridSize).ceil();
    final int rows = (size.height / gridSize).ceil();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double x = i * gridSize;
        final double y = j * gridSize;
        final Offset center = Offset(x + gridSize / 2, y + gridSize / 2);
        final int hash = ((i * 13) ^ (j * 7) + (i * j)).abs();
        final int shapeType = hash % 7; 
        switch (shapeType) {
          case 0: case 1: 
            const double s = 4.0;
            canvas.drawLine(center.translate(-s, 0), center.translate(s, 0), paintStroke);
            canvas.drawLine(center.translate(0, -s), center.translate(0, s), paintStroke);
            break;
          case 2: case 3: canvas.drawCircle(center, 1.5, paintFill); break;
          case 4: canvas.drawCircle(center, 3.0, paintStroke); break;
          case 5: const double s = 3.0; canvas.drawLine(center.translate(-s, s), center.translate(s, -s), paintStroke); break;
          default: break;
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}