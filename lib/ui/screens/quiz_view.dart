import 'package:flutter/material.dart';
import '../../data/services/data_manager.dart';
import '../../data/models/theme_info.dart';
import '../../data/models/sub_theme_info.dart';
import '../widgets/quiz/answer_card.dart';

class QuizView extends StatefulWidget {
  const QuizView({super.key});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  // --- VARIABLES D'ÉTAT ---
  ThemeInfo? _selectedTheme;
  SubThemeInfo? _selectedSubTheme;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoadingQuestions = false;

  // Chargement initial des thèmes
  Future<void>? _globalLoadingFuture;

  @override
  void initState() {
    super.initState();
    _globalLoadingFuture = DataManager.instance.loadAllData();
  }

  // --- LOGIQUE DE NAVIGATION ---

  // 1. Quand on clique sur un Thème
  void _onThemeSelected(ThemeInfo theme) {
    setState(() {
      _selectedTheme = theme;
      _selectedSubTheme = null; // Reset du sous-thème
      _questions = []; // Reset des questions
    });
  }

  // 2. Quand on clique sur un Sous-Thème
  Future<void> _onSubThemeSelected(SubThemeInfo subTheme) async {
    setState(() {
      _selectedSubTheme = subTheme;
      _isLoadingQuestions = true;
    });

    // Appel à Firestore via le DataManager
    final questions = await DataManager.instance.getQuestions(
      subTheme.parentTheme,
      subTheme.name,
    );

    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoadingQuestions = false;
      });
    }
  }

  // 3. Retour en arrière
  void _goBack() {
    setState(() {
      if (_selectedSubTheme != null) {
        // Retour : Questions -> Sous-Thèmes
        _selectedSubTheme = null;
        _questions = [];
      } else if (_selectedTheme != null) {
        // Retour : Sous-Thèmes -> Thèmes
        _selectedTheme = null;
      }
    });
  }

  // --- CONSTRUCTION DE L'INTERFACE ---

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _globalLoadingFuture,
      builder: (context, snapshot) {
        // Chargement global (au lancement)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Erreur globale
        if (snapshot.hasError) {
          return Center(
             child: Text("Erreur de chargement : ${snapshot.error}", 
             style: const TextStyle(color: Colors.red))
          );
        }

        // --- ROUTEUR D'AFFICHAGE ---
        
        // VUE 3 : Si un sous-thème est choisi, on affiche le JEU
        if (_selectedSubTheme != null) {
          if (_isLoadingQuestions) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_questions.isEmpty) {
            return _buildErrorView("Aucune question trouvée pour ce sous-thème.");
          }
          return _buildGameView();
        }

        // VUE 2 : Si un thème est choisi, on affiche les SOUS-THÈMES
        if (_selectedTheme != null) {
          return _buildSubThemesView();
        }

        // VUE 1 : Sinon, on affiche les THÈMES (Accueil)
        return _buildThemesView();
      },
    );
  }

  // --- WIDGETS DES DIFFÉRENTES VUES ---

  Widget _buildThemesView() {
    final themes = DataManager.instance.themes;
    
    if (themes.isEmpty) return const Center(child: Text("Aucun thème disponible."));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sélectionnez un Thème",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              childAspectRatio: 2.5,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: themes.length,
            itemBuilder: (ctx, index) {
              return AnswerCard(
                answer: themes[index].name,
                index: index,
                onTap: () => _onThemeSelected(themes[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubThemesView() {
    final subThemes = DataManager.instance.getSubThemesFor(_selectedTheme!.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text("Retour aux thèmes"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Thème : ${_selectedTheme!.name}",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 30),
        Expanded(
          child: subThemes.isEmpty 
          ? const Center(child: Text("Aucun sous-thème pour ce thème."))
          : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: subThemes.length,
            itemBuilder: (ctx, index) {
              return AnswerCard(
                answer: subThemes[index].name, 
                index: index,
                onTap: () => _onSubThemeSelected(subThemes[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameView() {
    // Pour l'instant, on affiche juste la première question pour tester l'affichage
    final question = _questions.first; 
    
    // Sécurisation des champs (au cas où ils sont vides dans Firestore)
    final titreQuestion = question['Question'] ?? 'Question sans titre';
    final reponses = [
      question['Réponse A'] ?? '...',
      question['Réponse B'] ?? '...',
      question['Réponse C'] ?? '...',
      question['Réponse D'] ?? '...'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Changer de sous-thème"),
            ),
            Chip(label: Text("Question 1 / ${_questions.length}")),
          ],
        ),
        const SizedBox(height: 40),
        
        // Affichage de la Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            titreQuestion,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),

        // Grille des Réponses
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 colonnes pour les réponses
              childAspectRatio: 4, // Format rectangulaire large
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: reponses.length,
            itemBuilder: (ctx, index) {
              return AnswerCard(
                answer: reponses[index].toString(),
                index: index,
                onTap: () {
                  // Logique de validation de réponse à venir ici
                  debugPrint("Réponse $index cliquée");
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontSize: 18, color: Colors.black54)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _goBack, child: const Text("Retour"))
        ],
      ),
    );
  }
}