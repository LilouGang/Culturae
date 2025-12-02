import 'dart:math';
import 'package:flutter/material.dart';
import '../data/data_manager.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // --- ÉTATS DE NAVIGATION ---
  ThemeInfo? _selectedTheme;
  SubThemeInfo? _selectedSubTheme;
  
  // Données chargées
  List<Map<String, dynamic>> _allQuestions = [];
  bool _isLoading = false;

  // --- ÉTATS DU JEU ---
  Map<String, dynamic>? _currentQuestion; // La question affichée
  bool _hasAnswered = false;               // A-t-il cliqué ?
  int? _selectedAnswerIndex;               // Index cliqué
  int? _correctAnswerIndex;                // Index de la bonne réponse
  
  // Paramètres de difficulté
  String _diffLabel = "";
  int _minLvl = 0; 
  int _maxLvl = 0;

  // --- LOGIQUE ---

  // 1. Charger les questions du sous-thème
  Future<void> _selectSubTheme(SubThemeInfo st) async {
    setState(() { _selectedSubTheme = st; _isLoading = true; });
    final qs = await DataManager.instance.getQuestions(st.parentTheme, st.name);
    if(mounted) setState(() { _allQuestions = qs; _isLoading = false; });
  }

  // 2. Choisir la difficulté et lancer le jeu
  void _selectDifficulty(String label, int min, int max) {
    _diffLabel = label; _minLvl = min; _maxLvl = max;
    _nextQuestion();
  }

  // 3. Tirer une question au hasard
  void _nextQuestion() {
    // Filtrage par difficulté (1-10)
    final filtered = _allQuestions.where((q) {
      final raw = q['difficulty']; // Ton champ Firestore
      int lvl = 0;
      if (raw is int) lvl = raw;
      if (raw is String) lvl = int.tryParse(raw) ?? 0;
      return lvl >= _minLvl && lvl <= _maxLvl;
    }).toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pas de questions pour ce niveau !")));
      return;
    }

    final q = filtered[Random().nextInt(filtered.length)];
    
    setState(() {
      _currentQuestion = q;
      _hasAnswered = false;
      _selectedAnswerIndex = null;
      _correctAnswerIndex = null;
    });
  }

  // 4. Vérifier la réponse
  void _checkAnswer(int index, String clickedText, List<String> allPropositions) {
    if (_hasAnswered) return; // Anti-triche
    
    // Récupération de la bonne réponse (String exact)
    final correctText = _currentQuestion!['reponse']?.toString() ?? "";
    
    // On cherche l'index qui contient ce texte
    int correctIdx = allPropositions.indexOf(correctText);
    
    // Sécurité si pas trouvé exactement (ex: espace en trop)
    if (correctIdx == -1) {
       correctIdx = allPropositions.indexWhere((p) => p.trim() == correctText.trim());
    }
    // Sécurité ultime
    if (correctIdx == -1) correctIdx = 0; 

    setState(() {
      _hasAnswered = true;
      _selectedAnswerIndex = index;
      _correctAnswerIndex = correctIdx;
    });
  }

  // 5. Reset global (Bouton Quitter)
  void _reset() {
    setState(() {
      if (_currentQuestion != null) _currentQuestion = null;
      else if (_selectedSubTheme != null) { _selectedSubTheme = null; _allQuestions = []; }
      else if (_selectedTheme != null) _selectedTheme = null;
    });
  }

  // --- INTERFACE PRINCIPALE ---

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DataManager.instance.isReady ? null : DataManager.instance.loadAllData(),
      builder: (ctx, snap) {
        if (!DataManager.instance.isReady && snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- ROUTEUR D'ÉCRANS ---
        if (_currentQuestion != null) return _buildGame(); // LE JEU
        if (_selectedSubTheme != null) return _isLoading ? const Center(child: CircularProgressIndicator()) : _buildDifficulty();
        if (_selectedTheme != null) return _buildSubThemes();
        return _buildThemes();
      },
    );
  }

  // --- ECRAN 4 : LE JEU (C'est ici que j'ai tout remis) ---
  Widget _buildGame() {
    final q = _currentQuestion!;
    
    // Récupération sécurisée des propositions
    List<String> props = [];
    try {
      props = List<String>.from(q['propositions']);
    } catch(e) {
      props = ["Erreur de données", "Vérifier Firestore", "...", "..."];
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- COLONNE GAUCHE : QUESTION + GRILLE ---
        Expanded(
          flex: 2, 
          child: Column(
            children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                ElevatedButton.icon(onPressed: _reset, icon: const Icon(Icons.close), label: const Text("Quitter")),
                Chip(label: Text("Niveau $_diffLabel")),
              ]),
              const SizedBox(height: 20),
              
              // La Question
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                child: Text(
                  q['question'] ?? "Question vide", 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center
                ),
              ),
              const SizedBox(height: 30),
              
              // La Grille de réponses
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 3.5, crossAxisSpacing: 15, mainAxisSpacing: 15
                  ),
                  itemCount: props.length,
                  itemBuilder: (ctx, idx) {
                    // Calcul de la couleur
                    Color? bg; 
                    Color? txt;
                    
                    if (_hasAnswered) {
                      if (idx == _correctAnswerIndex) {
                        // C'est la bonne -> VERT
                        bg = Colors.green; txt = Colors.white; 
                      } else if (idx == _selectedAnswerIndex) {
                        // J'ai cliqué là mais c'est faux -> ROUGE
                        bg = Colors.red; txt = Colors.white; 
                      }
                    }

                    return _MyCard(
                      text: props[idx], 
                      bgColor: bg, 
                      textColor: txt,
                      // On désactive le clic si déjà répondu
                      onTap: _hasAnswered ? null : () => _checkAnswer(idx, props[idx], props),
                    );
                  },
                ),
              ),
            ],
          )
        ),

        // --- COLONNE DROITE : EXPLICATION (Apparaît après le clic) ---
        if (_hasAnswered) 
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(left: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre Bravo / Raté
                  Row(children: [
                    Icon(_selectedAnswerIndex == _correctAnswerIndex ? Icons.check_circle : Icons.cancel, 
                         color: _selectedAnswerIndex == _correctAnswerIndex ? Colors.green : Colors.red, size: 32),
                    const SizedBox(width: 10),
                    Text(_selectedAnswerIndex == _correctAnswerIndex ? "Bien joué !" : "Oups...", 
                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _selectedAnswerIndex == _correctAnswerIndex ? Colors.green : Colors.red)),
                  ]),
                  const Divider(height: 30),
                  const Text("Explication :", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Texte de l'explication (Scrollable si trop long)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(q['explication'] ?? "Pas d'explication fournie.", style: const TextStyle(fontSize: 16, height: 1.4)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Bouton Suivant
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Question Suivante"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                      onPressed: _nextQuestion, // Relance une question aléatoire
                    ),
                  )
                ],
              ),
            )
          )
      ],
    );
  }

  // --- ECRANS 1, 2, 3 (Standards) ---

  Widget _buildThemes() {
    return _GridWrapper(
      title: "Thèmes",
      children: DataManager.instance.themes.map((t) => _MyCard(
        text: t.name, 
        onTap: () => setState(() => _selectedTheme = t)
      )).toList(),
    );
  }

  Widget _buildSubThemes() {
    final list = DataManager.instance.getSubThemesFor(_selectedTheme!.name);
    return _GridWrapper(
      title: "Thème : ${_selectedTheme!.name}",
      onBack: _reset,
      children: list.map((st) => _MyCard(
        text: st.name, 
        onTap: () => _selectSubTheme(st)
      )).toList(),
    );
  }

  Widget _buildDifficulty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(onPressed: _reset, icon: const Icon(Icons.arrow_back), label: const Text("Retour")),
        const SizedBox(height: 20),
        const Text("Difficulté", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Center(
          child: Wrap(
            spacing: 20, runSpacing: 20,
            children: [
              _DiffCard("FACILE", Colors.green, () => _selectDifficulty("Facile", 1, 3)),
              _DiffCard("MOYEN", Colors.orange, () => _selectDifficulty("Moyen", 4, 6)),
              _DiffCard("DIFFICILE", Colors.red, () => _selectDifficulty("Difficile", 7, 8)),
              _DiffCard("IMPOSSIBLE", Colors.purple, () => _selectDifficulty("Impossible", 9, 10)),
            ],
          ),
        )
      ],
    );
  }
}

// --- WIDGETS UI INTERNES ---

class _GridWrapper extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  const _GridWrapper({required this.title, required this.children, this.onBack});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (onBack != null) ...[ElevatedButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back), label: const Text("Retour")), const SizedBox(height: 10)],
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Expanded(child: GridView.count(crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 20, mainAxisSpacing: 20, children: children)),
    ]);
  }
}

class _MyCard extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? bgColor;
  final Color? textColor;
  const _MyCard({required this.text, this.onTap, this.bgColor, this.textColor});
  @override
  State<_MyCard> createState() => _MyCardState();
}

class _MyCardState extends State<_MyCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final bg = widget.bgColor ?? (_hover ? Colors.blue : Colors.white);
    final txt = widget.textColor ?? (_hover ? Colors.white : Colors.black);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [if(_hover && widget.onTap != null) BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0,4))],
          ),
          child: Center(child: Text(widget.text, textAlign: TextAlign.center, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  final String title; final Color color; final VoidCallback onTap;
  const _DiffCard(this.title, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 200, height: 100,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
        ),
      ),
    );
  }
}